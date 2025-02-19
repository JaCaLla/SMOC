//
//  ContentView.swift
//  SMOC
//
//  Created by Javier Calatrava on 13/1/25.
//

import SwiftUI


struct ContentView: View {
    @State private var showAlertPermissions = false
    @StateObject var videoManager = appSingletons.videoManager
    @StateObject var reelManager = appSingletons.reelManager
    @StateObject var locationManager = appSingletons.locationManager
    
    var body: some View {
        VStack {
            if videoManager.permissionGranted,
               reelManager.permissionGranted,
               locationManager.permissionGranted {
                VideoRecorderView()
            } else {
                RequestPermissionView()
            }
        }
        .onChange(of: videoManager.permissionGranted) { oldValue, newValue in
            guard !newValue, oldValue != newValue else { return }
            showAlertPermissions = true
        }
        .onAppear {
            Task {
                await reelManager.checkPermission()
                await videoManager.checkPermission()
                locationManager.checkPermission()
            }
        }
    }
}

#Preview {
    ContentView()
}
