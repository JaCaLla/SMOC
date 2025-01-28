//
//  VideoManager.swift
//  SMOC
//
//  Created by Javier Calatrava on 13/1/25.
//
import AVFoundation
import Foundation
import UIKit
import SwiftUI

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

extension AVCaptureSession: @unchecked Sendable {}

enum VideoManagerState {
    case notStarted
    case preRecording
    case ready
    case postRecording
    case transferingToReel
    
    func description() -> String {
        switch self {
        case .notStarted:
            return "not started"
        case .preRecording:
            return "pre recording"
        case .ready:
            return "ready"
        case .postRecording:
            return "post recording"
        case .transferingToReel:
            return "transferingToReel"
        }
    }
    
    func sfSymbolName() -> String {
        switch self {
        case .notStarted:
            return "questionmark.video"
        case .preRecording:
            return "video.badge.ellipsis"
        case .ready:
            return "video.circle"
        case .postRecording:
            return "video.fill.badge.ellipsis"
        case .transferingToReel:
            return "video.fill.badge.checkmark"
        }
    }
}

@GlobalManager
class VideoManager:NSObject, ObservableObject, @unchecked Sendable {
    
    @AppStorage(AppStorageVar.preRecordingSecs.rawValue) private var preRecordingSecs = AppStorageDefaultValues.preRecordingSecs
    @AppStorage(AppStorageVar.postRecordingSecs.rawValue) private var postRecordingSecs = AppStorageDefaultValues.postRecordingSecs
    
    var orientationOnStartRecording = AVCaptureVideoOrientation.portrait
    
    @MainActor
    @Published var state: VideoManagerState = .notStarted
    
    private var internalState: VideoManagerState = .notStarted {
         didSet {
            Task { [internalState] in
                await MainActor.run {
                    self.state = internalState
                }
            }
        }
    }
    
    @MainActor
    @Published var buttonSymbolName: String = "questionmark.video"
    
    @MainActor
    @Published var progress: Double = 0.0
    private var internalProgress: Double = 0.0 {
         didSet {
            Task { [internalProgress] in
                await MainActor.run {
                    self.progress = internalProgress
                }
            }
        }
    }
    
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
    let avCaptureSession: AVCaptureSession = AVCaptureSession()
    
    private var avCaptureDevice: AVCaptureDevice?
    private var videoOutput = AVCaptureMovieFileOutput()
    private var outputURL: URL?
    
    let avCaptureDeviceRequestPermission: AVCaptureDeviceProtocol.Type
    
    @MainActor
    init(device: AVCaptureDeviceProtocol.Type = AVCaptureDevice.self) {
        self.avCaptureDeviceRequestPermission = device
    }
    
    func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) async {
        guard let device = avCaptureDevice else {
            return
        }
        
        if await gesture.state == .changed {
            do {
                try device.lockForConfiguration()
                let videoZoomFactor = await device.videoZoomFactor * gesture.scale
                let zoomFactor = max(1.0, min(videoZoomFactor, device.activeFormat.videoMaxZoomFactor))
                print("zoomFactor: \(zoomFactor)")
                device.videoZoomFactor = zoomFactor
                device.unlockForConfiguration()
            } catch {
                print("Error al ajustar el zoom: \(error)")
            }
            Task { @MainActor in
                gesture.scale = 1.0
            }
        }
    }
    
    func setupSessionAndStartRecording() async {
        await setupSession()
        await startRecording()
    }
    
    func reStartRecording() async {
        await stopSession()
        await setupSessionAndStartRecording()
    }
    
    func setupSession() async {
        print(">>> setupSession")
        guard internalState == .notStarted else { return }
        
        await appSingletons.fileStoreManager.clearTemporaryDirectory()
        
        let internalAVCaptureSession = await getAVCaptureSession()

        internalAVCaptureSession.beginConfiguration()
        
        guard let avCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: avCaptureDevice) else {
            print("Not possible having access to camera")
            return
        }
        self.avCaptureDevice = avCaptureDevice
        
        if internalAVCaptureSession.canAddInput(input) {
            internalAVCaptureSession.addInput(input)
        }
        
        if internalAVCaptureSession.canAddOutput(videoOutput) {
            internalAVCaptureSession.addOutput(videoOutput)
        }
        
        internalAVCaptureSession.commitConfiguration()
        internalAVCaptureSession.startRunning()
    }
    
    private func getAVCaptureSession() async -> AVCaptureSession {
        await MainActor.run {
            return avCaptureSession
        }
    }
    
    private func getAnyFileURL() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
    }
    
    func startRecording() async {
        print(">>> startRecording")
        guard [.notStarted, .transferingToReel].contains(where: { $0 == internalState}) else { return }
        internalState = .preRecording
        startTimer(duration: preRecordingSecs)
        guard !videoOutput.isRecording else { return }
        
        let outputFile = getAnyFileURL()
        outputURL = outputFile
        
        
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = await currentVideoOrientation()
                    print("Iniciando grabación en \(connection.videoOrientation)")
            }
        } else {
            print("no se encontró conexión para el video")
        }
        
        
        if let connection = videoOutput.connection(with: .video) {
            let angle: CGFloat = await currentVideoRotationAngle()
            if connection.isVideoRotationAngleSupported(angle) {
                Task {
                    let angle = await currentVideoRotationAngle()
                    connection.videoRotationAngle = angle
                    print("Iniciando grabación con ángulo de rotación: \(angle)")
                }
            }
        }
        
        videoOutput.startRecording(to: outputFile, recordingDelegate: self)
        
        if deadline == nil {
            deadline = 5.0 * 60.0
            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + (deadline ?? 0.0)) { [weak self] in
                Task { @GlobalManager in
                    guard let self, self.internalState == .ready else {
                        return
                    }
                    await self.stopSession()
                    await self.setupSession()
                    self.deadline = nil
                    await self.startRecording()
                }
            }
        }
        print("Iniciando grabación en \(outputFile.absoluteString)")
    }
    var deadline: Double?
    
    @MainActor
    func currentVideoRotationAngle() -> CGFloat {
            let orientation = UIDevice.current.orientation
            switch orientation {
            case .portrait:
                return 0.0
            case .landscapeLeft:
                return 90.0
            case .portraitUpsideDown:
                return 180.0
            case .landscapeRight:
                return 270.0
            default:
                return 0
            }
    }
        
    func stopRecording() {
        print(">>> stopRecording")
        internalState = .postRecording
        startTimer(duration: postRecordingSecs)
        guard videoOutput.isRecording else { return }
        print("Recording will stop in \(postRecordingSecs) seconds")
    }
    
    func stopSession() async {
        print(">>> stopSession ")
        guard internalState != .notStarted else { return }
        let internalAVCaptureSession = await getAVCaptureSession()
        internalState = .notStarted
        internalAVCaptureSession.stopRunning()
        invalidateTimers()
    }
    
    @MainActor
    private func currentVideoOrientation() async -> AVCaptureVideoOrientation {
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
        
    var timerRunning = false
    private var timer: DispatchSourceTimer?
    
    // Look out!!! this crashes on Swift 6 migration
    private func startTimer(duration: Double) {
        if timerRunning { return }
        timerRunning = true
        internalProgress = 0.0

        let interval = 0.1 // Actualización cada 0.1 segundos
        let step = interval / duration
        
        let queue = DispatchQueue(label: "com.example.myTimerQueue")
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer?.schedule(deadline: .now(), repeating: interval)
        timer?.setEventHandler { [weak self] in
            Task { //@MyGlobalActor in
                guard let self else { return }
                                if self.internalProgress < 1.0 {
                                    self.internalProgress += step//min(self?.internalProgress ?? 0.0 + step, 1.0)
                                    self.internalProgress = min(self.internalProgress  , 1.0)
                                } else {
                                    
                                    if self.internalState == .preRecording {
                                                        self.internalState = .ready
                                                       // self?.internalRecorderReady = true
                                    } else if self.internalState == .postRecording {
                                        self.videoOutput.stopRecording()
                                            print("Recording Stopped.")
                                    
                                    }
                                    
                                    self.invalidateTimers()
                                }
            }
        }
        timer?.resume()
    }
    
    private func invalidateTimers() {
        timer?.cancel()
        timer = nil
        timerRunning = false
    }
}

extension VideoManager: @preconcurrency AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?) {
        guard internalState == .postRecording else {
            return
        }
        if let error = error {
            print("Error during recording: \(error.localizedDescription)")
            return
        }
        
        Task { @GlobalManager in
            internalState = .transferingToReel
            await moveToReelLastSecs(outputURL: outputURL)
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) async {
        guard internalState == .postRecording else {
            return
        }
        if let error = error {
            print("Error during recording: \(error.localizedDescription)")
            return
        }
        
        let curr = await currentVideoOrientation()
        guard orientationOnStartRecording == curr  else {
            return
        }
        
        Task { @GlobalManager in
            internalState = .transferingToReel
            await moveToReelLastSecs(outputURL: outputURL)
            await appSingletons.fileStoreManager.clearTemporaryDirectory()
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
        await startRecording()
    }
    
    func trimLastThirteenSeconds(last lastRecordingSecs: TimeInterval, from inputURL: URL, to outputURL: URL) async throws {
        
        let asset = AVURLAsset(url: inputURL)
        let duration = try await asset.load(.duration)
        let startTime = CMTimeSubtract(duration, CMTime(seconds: lastRecordingSecs, preferredTimescale: 600))
        let timeRange = CMTimeRange(start: startTime, duration: CMTime(seconds: lastRecordingSecs, preferredTimescale: 600))
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw NSError(domain: "ExportSession", code: 0, userInfo: nil)
        }
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.timeRange = timeRange
        
        try await  exportSession.export(to: outputURL, as: .mov)
    }
}

extension VideoManager: @preconcurrency VideoManagerProtocol {
    func checkPermission() async {
        switch avCaptureDeviceRequestPermission.authorizationStatus(for: .video) {
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
            avCaptureDeviceRequestPermission.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}
