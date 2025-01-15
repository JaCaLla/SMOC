//
//  AppSingletons.swift
//  LocationSampleApp
//
//  Created by Javier Calatrava on 1/12/24.
//

import Foundation

@MainActor
struct AppSingletons {
    var videoManager: VideoManager
    var reelManager: ReelManager
    
    init(videoManager: VideoManager = VideoManager(),
         reelManager: ReelManager = ReelManager()) {
        self.videoManager = videoManager
        self.reelManager = reelManager
    }
}

@MainActor var appSingletons = AppSingletons()
