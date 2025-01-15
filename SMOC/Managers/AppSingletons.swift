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
    var fileStoreManager: FileStoreManager
    
    init(videoManager: VideoManager = VideoManager(),
         reelManager: ReelManager = ReelManager(),
         fileStoreManager: FileStoreManager? = nil) {
        self.videoManager = videoManager
        self.reelManager = reelManager
        self.fileStoreManager = fileStoreManager ?? FileStoreManager()

    }
}

@MainActor var appSingletons = AppSingletons()
