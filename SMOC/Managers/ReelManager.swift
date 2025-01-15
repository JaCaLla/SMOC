//
//  ReelManager.swift
//  SMOC
//
//  Created by Javier Calatrava on 15/1/25.
//

import Foundation
import Photos

protocol ReelManagerProtocol {
    var permissionGranted: Bool { get }
    func checkPermission() async
    func requestPermission() async -> Bool
    func saveVideoToPhotoLibrary(fileURL: URL) async
}

final class ReelManager: ObservableObject {
    
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


extension ReelManager: ReelManagerProtocol {
    func checkPermission() async {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
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
            PHPhotoLibrary.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
    }
    
    func saveVideoToPhotoLibrary(fileURL: URL) async {
        guard internalPermissionGranted else { return }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
        }) { success, error in
            if success {
                print("Video saved to photo library")
            } else {
                print("Error saving video to photo library: \(String(describing: error))")
            }
        }
//            PHPhotoLibrary.requestAuthorization { status in
//                guard status == .authorized else {
//                    print("Photo Library access denied")
//                    return
//                }
//                PHPhotoLibrary.shared().performChanges({
//                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
//                }) { success, error in
//                    if success {
//                        print("Video saved to photo library")
//                    } else {
//                        print("Error saving video to photo library: \(String(describing: error))")
//                    }
//                }
//            }
        }
}
