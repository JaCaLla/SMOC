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
    var motionManager: MotionManager
    
    init(videoManager: VideoManager? = nil,
         reelManager: ReelManager? = nil,
         fileStoreManager: FileStoreManager? = nil,
         locationManager: LocationManager? = nil,
         motionManager: MotionManager? = nil) {
        self.videoManager = VideoManager()
        self.reelManager = reelManager ?? ReelManager()
        self.fileStoreManager = fileStoreManager ?? FileStoreManager()
        self.locationManager = locationManager ?? LocationManager()
        self.motionManager = motionManager ?? MotionManager()
    }
}

@MainActor var appSingletons = AppSingletons()
