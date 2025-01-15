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
    
    func startRecording() {
        guard !videoOutput.isRecording else { return }
        
        let outputDir = FileManager.default.temporaryDirectory
        let outputFile = outputDir.appendingPathComponent(UUID().uuidString).appendingPathExtension("mov")
        outputURL = outputFile
        
        if let connection = videoOutput.connection(with: .video) {
            if connection.isVideoOrientationSupported {
                connection.videoOrientation = currentVideoOrientation()
            }
        }
        
        videoOutput.startRecording(to: outputFile, recordingDelegate: self)
        print("Iniciando grabación en \(outputFile.absoluteString)")
    }
    
    func stopRecording() {
        guard videoOutput.isRecording else { return }
        videoOutput.stopRecording()
        print("Grabación detenida.")
    }
    
    func stopSession() {
        session.stopRunning()
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
            print("Error durante la grabación: \(error.localizedDescription)")
        } else {
            print("Video guardado en \(outputFileURL.absoluteString)")
        }
        guard let outputURL = outputURL else { return }
        Task {
           await appSingletons.reelManager.saveVideoToPhotoLibrary(fileURL: outputURL)
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
