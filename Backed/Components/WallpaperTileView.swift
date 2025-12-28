//
//  WallpaperTileView.swift
//  Backed
//
//  Created by ash on 12/24/25.
//


import SwiftUI
import AVKit

struct WallpaperTileView: View {
  @EnvironmentObject var library: WallpaperLibrary
  let wallpaper: Wallpaper
  @State var showingRename: Bool = false
  var folder: WallpaperFolder? = nil
  
  var body: some View {
    Button {
      library.setActive(wallpaper)
    } label: {
      ZStack(alignment: .bottomLeading) {
        VideoPlayerView(player: AVPlayer(url: wallpaper.thumbnailURL))
          .aspectRatio(16.0 / 9.0, contentMode: .fit)
          .clipped()
          .disabled(true)
        
        Text(wallpaper.name)
          .font(.headline)
          .padding(4)
          .background(
            RoundedRectangle(cornerRadius: 10)
              .fill(.ultraThinMaterial)
          )
          .padding(8)
        
        // Full rect to capture pointer events
        Rectangle()
          .fill(.background.opacity(0.001))
          .ignoresSafeArea()
      }
      .clipShape(RoundedRectangle(cornerRadius: 18))
      .overlay(
        RoundedRectangle(cornerRadius: 18)
          .stroke(
            library.activeWallpaper == wallpaper ? Color.accentColor : .clear,
            lineWidth: 3
          )
      )
    }
    .buttonStyle(.plain)
    .contextMenu {
      Button {
        library.setActive(wallpaper)
      } label: {
        Label("Set", systemImage: "photo.badge.checkmark")
      }
      
      Divider()
      
      Button {
        showingRename = true
      } label: {
        Label("Rename", systemImage: "pencil")
      }
            
      Button {
        library.delete(wallpaper)
      } label: {
        Label("Delete", systemImage: "trash")
      }
      
      Divider()
      
      Menu {
        ForEach(library.folders) { folder in
          Button {
            library.addWallpaper(wallpaper, to: folder)
          } label: {
            Label(folder.name, systemImage: folder.systemImage)
          }
        }
      } label: {
        Label("Add to Folder...", systemImage: "folder.badge.plus")
      }

      if (folder != nil) {
        Button {
          library.removeWallpaper(wallpaper, from: folder!)
        } label: {
          Label("Remove from \(folder?.name ?? "Folder")", systemImage: "folder.badge.minus")
        }
      }
      
      Divider()
      
      Button {
        library.stopPlaying()
      } label: {
        Label("Stop", systemImage: "stop")
      }
    }
    .sheet(isPresented: $showingRename) {
      WallpaperRenameView(shown: $showingRename, wallpaper: wallpaper)
        .environmentObject(library)
        .frame(maxWidth: 400)
    }
  }
}

struct VideoPlayerView: NSViewRepresentable {
    let player: AVPlayer
    
    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.showsFullScreenToggleButton = false
        view.controlsStyle = .none
        return view
    }
    
    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        nsView.player = player
    }
}

struct WallpaperRenameView: View {
  @Binding var shown: Bool
  let wallpaper: Wallpaper
  @EnvironmentObject var library: WallpaperLibrary
  @State var newName: String = ""
  
  var body: some View {
    NavigationStack {
      VStack {
        Text("Rename Wallpaper")
          .font(.headline)
        
        TextField("Name", text: $newName)
          .textFieldStyle(.plain)
          .font(.title)
      }
      .padding(.bottom, 32)
    }
    .padding()
    .toolbar {
      ToolbarItem(placement: .destructiveAction) {
        Button {
          library.delete(wallpaper)
        } label: {
          Label("Delete", systemImage: "trash")
            .padding(.vertical, 4)
        }
        .tint(.red)
        .clipShape(.capsule)
      }
      
      ToolbarItem(placement: .cancellationAction) {
        Button {
          shown = false
        } label: {
          Label("Cancel", systemImage: "xmark")
            .padding(.vertical, 4)
        }
        .clipShape(.capsule)
      }
      
      ToolbarItem(placement: .confirmationAction) {
        Button {
          library.rename(wallpaper, to: newName)
          shown = false
        } label: {
          Label("Rename", systemImage: "checkmark")
            .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .clipShape(.capsule)
      }
    }
  }
}
