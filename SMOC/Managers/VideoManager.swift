//
//  VideoManager.swift
//  SMOC
//
//  Created by Javier Calatrava on 13/1/25.
//
import AVFoundation
import Foundation
import UIKit

protocol AVCaptureDeviceProtocol {
    static func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus
    static func requestAccess(for mediaType: AVMediaType, completionHandler: @escaping (Bool) -> Void)
}

extension AVCaptureDevice: AVCaptureDeviceProtocol {}

protocol VideoManagerProtocol {
    var permissionGranted: Bool { get }
    func checkPermission() async
    func requestPermission() async -> Bool
}

/*final*/ class VideoManager:NSObject, ObservableObject, @unchecked Sendable {
    
    let postRecordingSecs: TimeInterval = 8.0
    let preRecordingSecs: TimeInterval = 5.0
    
    var stoppedSessionDueAppBackground = false
    
    @MainActor
    @Published var permissionGranted: Bool = false
    
    private var internalPermissionGranted: Bool = false {
         didSet {
            Task { [internalPermissionGranted] in
                await MainActor.run {
                    self.permissionGranted = internalPermissionGranted
                }
            }
        }
    }
    
    @MainActor
    @Published var recorderReady: Bool = false
    
    private var internalRecorderReady: Bool = false {
         didSet {
            Task { [internalRecorderReady] in
                await MainActor.run {
                    self.recorderReady = internalRecorderReady
                }
            }
        }
    }
    
    @Published var session = AVCaptureSession()
    private var videoOutput = AVCaptureMovieFileOutput()
    private var outputURL: URL?
    
    private let avCaptureDevice: AVCaptureDeviceProtocol.Type

    init(device: AVCaptureDeviceProtocol.Type = AVCaptureDevice.self) {
        self.avCaptureDevice = device
    }
    
    func setupSession() async {

        session.beginConfiguration()
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("No se pudo acceder a la cámara.")
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        session.commitConfiguration()
        session.startRunning()
    }
    
    private func getAnyFileURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
    }
    
    func startRecording() {
        guard !videoOutput.isRecording else { return }
        
        stoppedSessionDueAppBackground = false
        
        let outputFile = getAnyFileURL()
        outputURL = outputFile
        
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = currentVideoOrientation()
            }
        }
        
        videoOutput.startRecording(to: outputFile, recordingDelegate: self)
        print("Iniciando grabación en \(outputFile.absoluteString)")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + preRecordingSecs) { [weak self] in
            self?.internalRecorderReady = true
        }
    }
    
    func stopRecording() {
        guard videoOutput.isRecording else { return }
        
        internalRecorderReady = false
        print("Recording will stop in \(postRecordingSecs) seconds")
        DispatchQueue.main.asyncAfter(deadline: .now() + postRecordingSecs) { [weak self] in
            self?.videoOutput.stopRecording()
            print("Recording Stopped.")
        }
    }
    
    func stopSession(_ stoppedSessionDueAppBackground: Bool = false) {
        session.stopRunning()
        internalRecorderReady = false
        self.stoppedSessionDueAppBackground = stoppedSessionDueAppBackground
    }
    
    private func currentVideoOrientation() -> AVCaptureVideoOrientation {
        switch UIDevice.current.orientation {
        case .portrait:
            return .portrait
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
}

extension VideoManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error during recording: \(error.localizedDescription)")
            //stopSession(true)
            return
        }
        guard !stoppedSessionDueAppBackground else {
            return
        }
        Task {
            await moveToReelLastSecs(outputURL: outputURL)
        }
    }
    
    private func moveToReelLastSecs(outputURL: URL?) async {
        guard let outputURL  else { return }
        let lastSecsOutputURL = getAnyFileURL()
        do {
            let lastRecordingSecs = postRecordingSecs + preRecordingSecs
            try await trimLastThirteenSeconds(last: lastRecordingSecs, from: outputURL, to: lastSecsOutputURL)
        } catch {
            print("Error on extracting last secs: \(error.localizedDescription)")
        }
        await appSingletons.reelManager.saveVideoToPhotoLibrary(fileURL: lastSecsOutputURL)
        print("Video stored at \(lastSecsOutputURL.absoluteString)")
        startRecording()
    }
    
    func trimLastThirteenSeconds(last lastRecordingSecs: TimeInterval, from inputURL: URL, to outputURL: URL) async throws {
        
        let asset = AVAsset(url: inputURL)
        let duration = asset.duration
        let startTime = CMTimeSubtract(duration, CMTime(seconds: lastRecordingSecs, preferredTimescale: 600))
        let timeRange = CMTimeRange(start: startTime, duration: CMTime(seconds: lastRecordingSecs, preferredTimescale: 600))
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "ExportSession", code: 0, userInfo: nil)
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.timeRange = timeRange
        
        // Await the export process
        try await withCheckedThrowingContinuation { continuation in
            exportSession.exportAsynchronously {
                switch exportSession.status {
                case .completed:
                    continuation.resume()
                case .failed:
                    if let error = exportSession.error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(throwing: NSError(domain: "ExportSession", code: 2, userInfo: nil))
                    }
                case .cancelled:
                    continuation.resume(throwing: NSError(domain: "ExportSession", code: 1, userInfo: nil))
                default:
                    continuation.resume(throwing: NSError(domain: "ExportSession", code: 3, userInfo: nil))
                }
            }
        }
    }
    
}

extension VideoManager: VideoManagerProtocol {
    func checkPermission() async {
        switch avCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            internalPermissionGranted = true
        case .notDetermined:
            internalPermissionGranted = await requestPermission()
        default:
            internalPermissionGranted = false
        }
    }
    
    func requestPermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            avCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
