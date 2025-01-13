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
    
    init(videoManager: VideoManager = VideoManager()) {
        self.videoManager = videoManager
    }
}

@MainActor var appSingletons = AppSingletons()
