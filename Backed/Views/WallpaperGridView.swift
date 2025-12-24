//
//  WallpaperGridView.swift
//  Backed
//
//  Created by ash on 12/24/25.
//


import SwiftUI

struct WallpaperGridView: View {
  @EnvironmentObject var library: WallpaperLibrary
  
  let columns = [
    GridItem(.adaptive(minimum: 220), spacing: 20)
  ]
  
  var body: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 20) {
        ForEach(library.wallpapers) { wallpaper in
          WallpaperTileView(wallpaper: wallpaper)
        }
      }
      .safeAreaPadding()
    }
  }
}
