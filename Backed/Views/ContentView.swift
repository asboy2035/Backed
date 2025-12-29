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
    NavigationSplitView {
      SidebarView()
    } detail: {
      WallpaperGridView()
    }
    .frame(minWidth: 750, minHeight: 450)
    .modifier(SafeNavigationSubtitle(title: "Backed"))
    .overlay {
      if library.isClearingCache {
        VStack {
          Text("Clearing Cache...")
            .font(.title2)
          Text("Please wait.")
            .foregroundStyle(.secondary)
        }
        .padding(8)
        .safeGlass(cornerRadius: 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
      }
    }
    .toolbar {
      ToolbarItem(placement: .navigation) {
        Toggle(isOn: $library.isAudioEnabled) {
          Label("Audio", systemImage: library.isAudioEnabled ? "speaker.wave.1" : "speaker.slash")
        }
        .tint(.accent)
        .onChange(of: library.isAudioEnabled) { enabled in
          library.setAudioEnabled(enabled)
        }
      }
      
      ToolbarItem {
        Menu {
          Button {
            library.importVideo()
          } label: {
            Label("Video", systemImage: "square.and.arrow.down")
          }
          
          Button {
            library.createFolder(name: "New Folder")
          } label: {
            Label("Folder", systemImage: "folder.badge.plus")
          }
        } label: {
          Label("New...", systemImage: "plus")
        }
      }
    }
  }
}

#Preview {
  @Previewable @StateObject var library = WallpaperLibrary.shared

  ContentView()
    .environmentObject(library)
}
