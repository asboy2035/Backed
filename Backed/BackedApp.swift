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
    }
  }
}
