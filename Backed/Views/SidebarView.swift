//
//  SidebarView.swift
//  Backed
//
//  Created by ash on 12/25/25.
//

import SwiftUI

struct SidebarView: View {
  @EnvironmentObject var library: WallpaperLibrary
  @State private var folderForRename: WallpaperFolder?
  @State private var folderForIconChange: WallpaperFolder?
  
  var body: some View {
    List {
      Section("Backed") {
        NavigationLink(destination: WallpaperGridView()) {
          Label("All", systemImage: "rectangle.grid.2x2")
        }
        
        Label("Settings", systemImage: "gear")
          .onTapGesture {
            SettingsController.shared.showSettings()
          }
        
        Label("Displays", systemImage: "display.2")
          .onTapGesture {
            DisplaysController.shared.showDisplays()
          }
      }
      
      Section("Folders") {
        ForEach(library.folders) { folder in
          NavigationLink(destination: FolderGridView(folder: folder)) {
            Label(folder.name, systemImage: folder.systemImage)
          }
          .contextMenu {
            Button {
              folderForRename = folder
            } label: {
              Label("Rename", systemImage: "pencil")
            }
            
            Button {
              folderForIconChange = folder
            } label: {
              Label("Change Icon", systemImage: "heart")
            }
            
            Divider()
            
            Button {
              library.deleteFolder(folder)
            } label: {
              Label("Delete", systemImage: "trash")
            }
          }
        }
      }
    }
    .sheet(item: $folderForRename) { folder in
      EditFolderSheet(name: folder.name, icon: folder.systemImage, folder: folder)
        .environmentObject(library)
    }
    .sheet(item: $folderForIconChange) { folder in
      EditFolderSheet(name: folder.name, icon: folder.systemImage, folder: folder)
        .environmentObject(library)
    }
  }
}
