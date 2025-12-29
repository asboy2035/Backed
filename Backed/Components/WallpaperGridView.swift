//
//  WallpaperGridView.swift
//  Backed
//
//  Created by ash on 12/24/25.
//


import SwiftUI

struct WallpaperGridView: View {
  @EnvironmentObject var library: WallpaperLibrary
  var menuMode: Bool = false
  var spacing: CGFloat {
    menuMode ? 10 : 18
  }
  
  var columns: [GridItem] {
    [
      GridItem(.adaptive(minimum: menuMode ? 160 : 220), spacing: spacing)
    ]
  }
  
  var body: some View {
    VStack(spacing: 4) {
      if menuMode {
        HStack {
          Button {
            library.isAudioEnabled.toggle()
            library.setAudioEnabled(library.isAudioEnabled)
          } label: {
            Image(systemName: library.isAudioEnabled ? "speaker.wave.1" : "speaker.slash")
          }
          .clipShape(.capsule)
          
          HStack(alignment: .bottom) {
            Text("Wallpapers")
              .font(.headline)
            Text("Backed")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          
          Spacer()
          
          Button {
            NSApplication.shared.terminate(nil)
          } label: {
            Label("Quit", systemImage: "power")
          }
          .clipShape(.capsule)
        }
      }
      
      ScrollView {
        LazyVGrid(columns: columns, spacing: spacing) {
          ForEach(library.wallpapers) { wallpaper in
            WallpaperTileView(wallpaper: wallpaper, menuMode: menuMode)
          }
        }
        .safeAreaPadding(menuMode ? 0 : spacing - 4)
      }
    }
    .safeAreaPadding(menuMode ? 6 : 0)
    .navigationTitle("All")
  }
}
