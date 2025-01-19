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
    var locationManager: LocationManager
    
    init(videoManager: VideoManager? = nil,
         reelManager: ReelManager = ReelManager(),
         fileStoreManager: FileStoreManager? = nil,
         locationManager: LocationManager? = nil) {
        self.videoManager = VideoManager()
        self.reelManager = reelManager
        self.fileStoreManager = fileStoreManager ?? FileStoreManager()
        self.locationManager = locationManager ?? LocationManager()

    }
}

@MainActor var appSingletons = AppSingletons()
