//
//  BackedApp.swift
//  Backed
//
//  Created by ash on 12/24/25.
//

import SwiftUI
import AppKit

@main
struct BackedApp: App {
  @StateObject private var library = WallpaperLibrary.shared
  @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
  
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
    
    MenuBarExtra {
      WallpaperGridView(menuMode: true)
        .frame(width: 540, height: 360)
        .environmentObject(library)
    } label: {
      Label("Backed Menu", systemImage: "film.stack.fill")
    }
    .menuBarExtraStyle(.window)
  }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDockMenu(_ sender: NSApplication) -> NSMenu {
    let menu = NSMenu()

    let stopItem = NSMenuItem(
      title: "Stop Playing",
      action: #selector(stopWallpaper),
      keyEquivalent: ""
    )
    stopItem.target = self
    menu.addItem(stopItem)

    let muteItem = NSMenuItem(
      title: WallpaperLibrary.shared.isAudioEnabled ? "Mute Audio" : "Unmute Audio",
      action: #selector(toggleAudio),
      keyEquivalent: ""
    )
    muteItem.target = self
    menu.addItem(muteItem)

    return menu
  }

  @objc private func stopWallpaper() {
    WallpaperLibrary.shared.stopPlaying()
  }

  @objc private func toggleAudio() {
    WallpaperLibrary.shared.isAudioEnabled.toggle()
    VideoWallpaperEngine.shared.setMuted(!WallpaperLibrary.shared.isAudioEnabled)
  }
}
