//
//  ContentView.swift
//  Backed
//
//  Created by ash on 12/24/25.
//

import SwiftUI

struct ContentView: View {
  @EnvironmentObject var library: WallpaperLibrary
  
  var body: some View {
    ScrollView {
      WallpaperGridView()
    }
    .frame(minWidth: 450, minHeight: 300)
    .navigationTitle("Library")
    .modifier(SafeNavigationSubtitle(title: "Backed"))
    .toolbar {
      ToolbarItem {
        Button {
          library.importVideo()
        } label: {
          Label("Import", systemImage: "square.and.arrow.down")
        }
        .buttonStyle(.borderedProminent)
        .tint(.accent)
      }
    }
  }
}

#Preview {
  ContentView()
}
