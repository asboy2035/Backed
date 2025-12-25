//
//  FolderGridView.swift
//  Backed
//
//  Created by ash on 12/25/25.
//


import SwiftUI

struct FolderGridView: View {
  let folder: WallpaperFolder
  @EnvironmentObject var library: WallpaperLibrary
  var items: [Wallpaper] {
    folder.wallpaperIDs.compactMap { id in
      library.wallpapers.first { $0.id == id }
    }
  }
  
  private let columns = [GridItem(.adaptive(minimum: 200), spacing: 20)]
  
  var body: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 20) {
        ForEach(items) { wallpaper in
          WallpaperTileView(wallpaper: wallpaper, folder: folder)
        }
      }
      .padding()
    }
    .navigationTitle(folder.name)
  }
}
