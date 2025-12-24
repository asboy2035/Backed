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
        .onAppear {
          if let wallpaper = WallpaperLibrary.shared.activeWallpaper {
            VideoWallpaperEngine.shared.set(wallpaper)
            VideoWallpaperEngine.shared.setMuted(
              !WallpaperLibrary.shared.isAudioEnabled
            )
          }
        }
    }
  }
}
