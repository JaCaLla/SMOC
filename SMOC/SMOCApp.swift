//
//  SMOCApp.swift
//  SMOC
//
//  Created by Javier Calatrava on 13/1/25.
//

import SwiftUI

@main
struct SMOCApp: App {
   // @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
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
/*
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Configura tu aplicación, APIs, servicios, etc.
        print("AppDelegate: La aplicación ha terminado de lanzarse.")
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        print("AppDelegate: La aplicación está a punto de pasar a estado inactivo.")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        print("AppDelegate: La aplicación ha vuelto a estar activa.")
    }

    func applicationWillTerminate(_ application: UIApplication) {
        print("AppDelegate: La aplicación está a punto de terminar.")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        print("La aplicación se envió a segundo plano.")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        print("La aplicación regresó al primer plano.")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        
    }
}
*/
