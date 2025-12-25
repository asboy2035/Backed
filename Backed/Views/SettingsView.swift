//
//  SettingsView.swift
//  Backed
//
//  Created by ash on 12/25/25.
//

import SwiftUI
import LaunchAtLogin

final class SettingsController {
  static let shared = SettingsController()
  private init() {}

  private var window: NSWindow?

  func showSettings() {
    if window == nil {
      let hosting = NSHostingController(rootView: SettingsView())
      let win = NSWindow(
        contentViewController: hosting
      )
      win.title = "Settings"
      win.styleMask = [.titled, .closable, .miniaturizable, .resizable]
      win.toolbarStyle = .unifiedCompact
      win.setFrameAutosaveName("SettingsWindow")
      window = win
    }
    window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
}

struct SettingsView: View {
  var body: some View {
    ScrollView {
      Form {
        Section("General") {
          LaunchAtLogin.Toggle()
        }
      }
      .navigationTitle("Settings")
      .formStyle(.grouped)
    }
    .frame(minWidth: 400, minHeight: 300)
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Button {
          NSApplication.shared.terminate(nil)
        } label: {
          Label("Quit", systemImage: "power")
        }
      }
    }
  }
}
