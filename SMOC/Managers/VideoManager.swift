//
//  VideoManager.swift
//  SMOC
//
//  Created by Javier Calatrava on 13/1/25.
//
import AVFoundation
import Foundation

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

/*final*/ class VideoManager: ObservableObject, @unchecked Sendable {
    
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
    
    private let avCaptureDevice: AVCaptureDeviceProtocol.Type

    init(device: AVCaptureDeviceProtocol.Type = AVCaptureDevice.self) {
        self.avCaptureDevice = device
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
