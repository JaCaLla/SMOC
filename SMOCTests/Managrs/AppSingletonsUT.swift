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
}


@GlobalManager
class MockVideoManager: VideoManager, @unchecked Sendable {
    @MainActor
    var isInitialized = false
    
    @MainActor
    init() {
        super.init()
        isInitialized = true
    }
}
