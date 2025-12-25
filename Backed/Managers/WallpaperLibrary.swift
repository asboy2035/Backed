//
//  WallpaperLibrary.swift
//  Backed
//
//  Created by ash on 12/24/25.
//


import Foundation
import AppKit
import Combine
import UniformTypeIdentifiers

@MainActor
final class WallpaperLibrary: ObservableObject {
  static let shared = WallpaperLibrary()
  
  @Published private(set) var wallpapers: [Wallpaper] = []
  @Published var activeWallpaper: Wallpaper?
  @Published var isAudioEnabled: Bool = true
  
  private let libraryURL: URL
  
  private init() {
    libraryURL = FileManager.default
      .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Backed/Wallpapers")
    
    try? FileManager.default.createDirectory(
      at: libraryURL,
      withIntermediateDirectories: true
    )
    
    load()
    if UserDefaults.standard.object(forKey: "audioEnabled") != nil {
      isAudioEnabled = UserDefaults.standard.bool(forKey: "audioEnabled")
    }
  }
  
  func importVideo() {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.movie]
    panel.allowsMultipleSelection = true
    
    guard panel.runModal() == .OK else { return }
    
    for url in panel.urls {
      let dest = libraryURL.appendingPathComponent(url.lastPathComponent)
      try? FileManager.default.copyItem(at: url, to: dest)
      
      let wallpaper = Wallpaper(
        url: dest,
        name: dest.deletingPathExtension().lastPathComponent,
        thumbnailURL: dest
      )
      
      wallpapers.append(wallpaper)
    }
    
    save()
  }
  
  func setActive(_ wallpaper: Wallpaper) {
    activeWallpaper = wallpaper
    VideoWallpaperEngine.shared.set(wallpaper)
    save()
  }
  
  private func save() {
    UserDefaults.standard.set(
      wallpapers.map { $0.url.path },
      forKey: "wallpapers"
    )
    UserDefaults.standard.set(
      activeWallpaper?.url.path,
      forKey: "activeWallpaper"
    )
  }
  
  private func load() {
    let paths = UserDefaults.standard.stringArray(forKey: "wallpapers") ?? []
    wallpapers = paths.map {
      let url = URL(fileURLWithPath: $0)
      return Wallpaper(
        url: url,
        name: url.deletingPathExtension().lastPathComponent,
        thumbnailURL: url
      )
    }
    
    if let activePath = UserDefaults.standard.string(forKey: "activeWallpaper") {
      activeWallpaper = wallpapers.first { $0.url.path == activePath }
    }
  }
  
  // -MARK: Management
  func setAudioEnabled(_ enabled: Bool) {
      // SwiftUI already updated isAudioEnabled via the binding.
      // This method only applies side effects.
      VideoWallpaperEngine.shared.setMuted(!enabled)
      UserDefaults.standard.set(enabled, forKey: "audioEnabled")
  }
  
  func rename(_ wallpaper: Wallpaper, to newName: String) {
    guard let index = wallpapers.firstIndex(of: wallpaper) else { return }
    
    let newURL = wallpaper.url
      .deletingLastPathComponent()
      .appendingPathComponent(newName)
      .appendingPathExtension(wallpaper.url.pathExtension)
    
    do {
      try FileManager.default.moveItem(at: wallpaper.url, to: newURL)
      
      let updated = Wallpaper(
        url: newURL,
        name: newName,
        thumbnailURL: newURL
      )
      
      wallpapers[index] = updated
      
      if activeWallpaper == wallpaper {
        activeWallpaper = updated
        VideoWallpaperEngine.shared.set(updated)
      }
      
      save()
    } catch {
      print("Failed to rename wallpaper:", error)
    }
  }
  
  func stopPlaying() {
    activeWallpaper = nil
    VideoWallpaperEngine.shared.stop()
  }
  
  func delete(_ wallpaper: Wallpaper) {
    guard let index = wallpapers.firstIndex(of: wallpaper) else { return }
    
    do {
      try FileManager.default.removeItem(at: wallpaper.url)
    } catch {
      print("Failed to delete wallpaper:", error)
    }
    
    if activeWallpaper == wallpaper {
      stopPlaying()
    }
    
    wallpapers.remove(at: index)
    save()
  }
}
