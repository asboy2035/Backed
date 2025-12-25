//
//  SettingsView.swift
//  Backed
//
//  Created by ash on 12/25/25.
//

import SwiftUI
import LaunchAtLogin

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
  }
}
