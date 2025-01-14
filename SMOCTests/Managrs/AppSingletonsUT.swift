//
//  AppSingletonsUT.swift
//  SMOCTests
//
//  Created by Javier Calatrava on 14/1/25.
//

import Foundation
@testable import SMOC
import Testing

@MainActor
@Suite("AppSingletonsUT", .serialized)
struct AppSingletonsUT {
    
    @Test
   func testAppSingletonsDefaultInitialization() {

       let appSingletons = AppSingletons()
       #expect(appSingletons.videoManager is VideoManager)
   }
    
     @Test
    func testAppSingletonsInitialization() {
        // Arrange: Create a mock VideoManager
                let mockVideoManager = MockVideoManager()
                
                // Act: Initialize AppSingletons with the mock
                let appSingletons = AppSingletons(videoManager: mockVideoManager)
                
                // Assert: Verify the injected videoManager is the mock
        #expect(appSingletons.videoManager is MockVideoManager)
        #expect((appSingletons.videoManager as! MockVideoManager).isInitialized)
    }
}


class MockVideoManager: VideoManager, @unchecked Sendable {
    var isInitialized = false
    
    init() {
        super.init()
        isInitialized = true
    }
}
