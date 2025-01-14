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
    var body: some View {
        VStack {
            if videoManager.permissionGranted {
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
                await videoManager.checkPermission()
            }
        }
    }
}

#Preview {
    ContentView()
}
