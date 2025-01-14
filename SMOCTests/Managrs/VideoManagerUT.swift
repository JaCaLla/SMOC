//
//  VideoManagerUT.swift
//  SMOCTests
//
//  Created by Javier Calatrava on 14/1/25.
//
import AVFoundation
@testable import SMOC
import Testing

@MainActor
@Suite("VideoManagerUT", .serialized)
struct VideoManagerUT {

    @Test func testCheckPermission_Authorized() async throws {
        MockAVCaptureDevice.mockAuthorizationStatus = .authorized
        let videoManager = VideoManager(device: MockAVCaptureDevice.self)
        await videoManager.checkPermission()
        
        // Look Out! permistionGranted is updated in Main Thread from another background thread, so we have to
        // wait in MainThread until is updated.
        await MainActor.run {
        #expect(videoManager.permissionGranted)
        }
    }
    
    @Test func testCheckPermission_Denied() async throws {
        MockAVCaptureDevice.mockAuthorizationStatus = .denied
        let videoManager = VideoManager(device: MockAVCaptureDevice.self)
        await videoManager.checkPermission()
        
        // Look Out! permistionGranted is updated in Main Thread from another background thread, so we have to
        // wait in MainThread until is updated.
        await MainActor.run {
            #expect(!videoManager.permissionGranted)
        }
    }
    
    @Test func testCheckPermission_NotDetermined_Denied() async throws {
        MockAVCaptureDevice.mockAuthorizationStatus = .notDetermined
        MockAVCaptureDevice.mockRequestAccessResult = false
        let videoManager = VideoManager(device: MockAVCaptureDevice.self)
        await videoManager.checkPermission()
        
        // Look Out! permistionGranted is updated in Main Thread from another background thread, so we have to
        // wait in MainThread until is updated.
        await MainActor.run {
            #expect(!videoManager.permissionGranted)
        }
    }
    
    @Test func testCheckPermission_NotDetermined_Authorized() async throws {
        MockAVCaptureDevice.mockAuthorizationStatus = .notDetermined
        MockAVCaptureDevice.mockRequestAccessResult = true
        let videoManager = VideoManager(device: MockAVCaptureDevice.self)
        await videoManager.checkPermission()
        
        // Look Out! permistionGranted is updated in Main Thread from another background thread, so we have to
        // wait in MainThread until is updated.
        await MainActor.run {
            #expect(videoManager.permissionGranted)
        }
    }
}

final class MockAVCaptureDevice: AVCaptureDeviceProtocol {
    static var mockAuthorizationStatus: AVAuthorizationStatus = .notDetermined
    static var mockRequestAccessResult: Bool = false

    static func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus {
        return mockAuthorizationStatus
    }

    static func requestAccess(for mediaType: AVMediaType, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(mockRequestAccessResult)
    }
}
