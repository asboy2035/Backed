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
  @Published var folders: [WallpaperFolder] = []
  @Published var isClearingCache: Bool = false
  
  private let libraryURL: URL
  private let cacheURL: URL = FileManager.default
    .urls(for: .cachesDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("BackedCache")
  
  private init() {
    libraryURL = FileManager.default
      .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      .appendingPathComponent("Backed/Wallpapers")
    
    try? FileManager.default.createDirectory(
      at: libraryURL,
      withIntermediateDirectories: true
    )
    try? FileManager.default.createDirectory(
      at: cacheURL,
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
    if let data = try? JSONEncoder().encode(wallpapers) {
      UserDefaults.standard.set(data, forKey: "wallpapers")
    }
    UserDefaults.standard.set(
      activeWallpaper?.url.path,
      forKey: "activeWallpaper"
    )
    do {
      let data = try JSONEncoder().encode(folders)
      UserDefaults.standard.set(data, forKey: "folders")
    } catch {
      print("Failed to save folders:", error)
    }
  }
  
  private func load() {
    if let data = UserDefaults.standard.data(forKey: "wallpapers") {
      if let decoded = try? JSONDecoder().decode([Wallpaper].self, from: data) {
        wallpapers = decoded
      }
    }
    
    if let activePath = UserDefaults.standard.string(forKey: "activeWallpaper") {
      activeWallpaper = wallpapers.first { $0.url.path == activePath }
    }
    if let data = UserDefaults.standard.data(forKey: "folders") {
      do {
        folders = try JSONDecoder().decode([WallpaperFolder].self, from: data)
      } catch {
        print("Failed to load folders:", error)
      }
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
        id: wallpaper.id,
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
    for idx in folders.indices {
      folders[idx].wallpaperIDs.removeAll { $0 == wallpaper.id }
    }
    save()
  }
  
  func createFolder(name: String, systemImage: String = "folder") {
    let folder = WallpaperFolder(name: name, systemImage: systemImage)
    folders.append(folder)
    save()
  }
  
  func renameFolder(_ folder: WallpaperFolder, to newName: String) {
    guard let i = folders.firstIndex(of: folder) else { return }
    folders[i].name = newName
    save()
  }
  
  func changeFolderIcon(_ folder: WallpaperFolder, to systemImage: String) {
    guard let i = folders.firstIndex(of: folder) else { return }
    folders[i].systemImage = systemImage
    save()
  }
  
  func deleteFolder(_ folder: WallpaperFolder) {
    folders.removeAll { $0.id == folder.id }
    save()
  }
  
  func addWallpaper(_ wallpaper: Wallpaper, to folder: WallpaperFolder) {
    guard let i = folders.firstIndex(of: folder) else { return }
    let id = wallpaper.id
    if !folders[i].wallpaperIDs.contains(id) {
      folders[i].wallpaperIDs.append(id)
      save()
    }
  }
  
  func removeWallpaper(_ wallpaper: Wallpaper, from folder: WallpaperFolder) {
    guard let i = folders.firstIndex(of: folder) else { return }
    folders[i].wallpaperIDs.removeAll { $0 == wallpaper.id }
    save()
  }
  
  func cleanCacheAndQuit() {
    isClearingCache = true
    cleanCache()

    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
      self.isClearingCache = false
      NSApplication.shared.terminate(nil)
    }
  }

  func cleanCache() {
    let fm = FileManager.default

    // remove entire BackedCache directory
    try? fm.removeItem(at: cacheURL)
    try? fm.createDirectory(at: cacheURL, withIntermediateDirectories: true)

    // remove orphaned wallpapers
    let usedURLs = Set(wallpapers.map { $0.url })
    if let contents = try? fm.contentsOfDirectory(at: libraryURL, includingPropertiesForKeys: nil) {
      for file in contents {
        if !usedURLs.contains(file) {
          try? fm.removeItem(at: file)
        }
      }
    }
  }
}
