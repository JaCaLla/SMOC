//
//  SMOCApp.swift
//  SMOC
//
//  Created by Javier Calatrava on 13/1/25.
//

import SwiftUI

@main
struct SMOCApp: App {
    @Environment(\.scenePhase) var scenePhase
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    UIApplication.shared.isIdleTimerDisabled = true
                    await appSingletons.fileStoreManager.clearTemporaryDirectory()
                }
        }
    }
}
