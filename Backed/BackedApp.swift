//
//  BackedApp.swift
//  Backed
//
//  Created by ash on 12/24/25.
//

import SwiftUI

@main
struct BackedApp: App {
  @StateObject private var library = WallpaperLibrary.shared
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(library)
        .task {
          if let wallpaper = library.activeWallpaper {
            VideoWallpaperEngine.shared.set(wallpaper)
            VideoWallpaperEngine.shared.setMuted(!library.isAudioEnabled)
          }
        }
    }
    .commands {
      CommandGroup(replacing: .appSettings) {
        Button {
          SettingsController.shared.showSettings()
        } label: {
          Label("Settings…", systemImage: "gear")
        }
        .keyboardShortcut(",", modifiers: [.command])
      }
      
      CommandGroup(replacing: .appTermination) {
        Button {
          WallpaperLibrary.shared.cleanCacheAndQuit()
        } label: {
          Label("Quit Backed", systemImage: "power")
        }
        .keyboardShortcut("q", modifiers: .command)
      }
    }
  }
}
