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
                if videoManager.permissionGranted  {
                    Text("Permissions: OK!")
                } else {
                    Text("Se requiere permiso para acceder a la cámara y el micrófono")
                    Button("Abrir Ajustes") {
                        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsURL)
                        }
                    }
                }
        }
        .onChange(of: videoManager.permissionGranted) { oldValue, newValue in
            guard !newValue, oldValue != newValue else { return }
            showAlertPermissions = true
        }
        .onAppear {
            videoManager.checkPermission()
        }
    }
}

#Preview {
    ContentView()
}
