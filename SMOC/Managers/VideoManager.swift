//
//  VideoManager.swift
//  SMOC
//
//  Created by Javier Calatrava on 13/1/25.
//

import Foundation
import AVFoundation

protocol VideoManagerProtocol {
    func checkPermission()
    func requestPermission()
}

final class VideoManager: ObservableObject, @unchecked Sendable {
    
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
}

extension VideoManager: VideoManagerProtocol {
    func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            internalPermissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            internalPermissionGranted = false
        }
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            self.internalPermissionGranted = granted
        }
    }
}
