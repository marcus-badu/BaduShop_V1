//
//  BaduShopApp.swift
//  BaduShop
//  Version: 3
//  Created by Marcus Silva on 01/06/25.
//

import SwiftUI
import Speech
import AVFoundation

@main
struct BaduShopApp: App {
    @StateObject private var dataController = DataController()

    init() {
        requestSpeechPermissionOnFirstLaunch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(context: dataController.container.viewContext)
                         .environment(\.managedObjectContext, dataController.container.viewContext)
        }
    }

    private func requestSpeechPermissionOnFirstLaunch() {
        let hasRequested = UserDefaults.standard.bool(forKey: "SpeechPermissionRequested")

        if !hasRequested {
            SFSpeechRecognizer.requestAuthorization { _ in }
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                // Aqui você pode logar ou mostrar algo, se quiser
            }
            UserDefaults.standard.set(true, forKey: "SpeechPermissionRequested")
        }
    }
}
