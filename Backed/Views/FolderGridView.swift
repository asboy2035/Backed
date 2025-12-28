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
  @State var showingEditor: Bool = false
  
  private let columns = [GridItem(.adaptive(minimum: 200), spacing: 20)]
  
  var body: some View {
    ScrollView {
      HStack(alignment: .bottom) {
        HStack {
          Image(systemName: folder.systemImage)
          VStack(alignment: .leading) {
            Text("\(folder.wallpaperIDs.count) Items")
              .font(.caption)
              .foregroundStyle(.secondary)
            Text(folder.name)
          }
        }
        .font(.largeTitle)
        
        Spacer()
        
        ZStack(alignment: .bottomTrailing) {
          Image(systemName: "folder")
            .font(.system(size: 72))
            .foregroundStyle(
              LinearGradient(
                gradient: Gradient(colors: [
                  Color.accent.opacity(0.6),
                  Color.accent.opacity(0.2)
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
              )
            )
          
          Button {
            showingEditor = true
          } label: {
            Label("Edit", systemImage: "pencil")
              .padding(.vertical, 4)
          }
          .buttonStyle(.borderedProminent)
          .clipShape(.capsule)
          .safeGlass()
        }
      }
      .padding()
      .background(
        Rectangle()
          .fill(
            LinearGradient(
              gradient: Gradient(colors: [
                Color.accent.opacity(0.0),
                Color.accent.opacity(0.3)
              ]),
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .ignoresSafeArea()
      )
      
      LazyVGrid(columns: columns, spacing: 20) {
        ForEach(items) { wallpaper in
          WallpaperTileView(wallpaper: wallpaper, folder: folder)
        }
      }
      .padding()
    }
    .navigationTitle(folder.name)
    .sheet(isPresented: $showingEditor) {
      EditFolderSheet(name: folder.name, icon: folder.systemImage, folder: folder)
        .environmentObject(library)
    }
  }
}

#Preview {
  @Previewable @StateObject var library = WallpaperLibrary.shared
  let testFolder = WallpaperFolder(name: "Test", systemImage: "gear")
  
  FolderGridView(folder: testFolder)
    .frame(minWidth: 450, maxWidth: 500)
    .environmentObject(library)
}
