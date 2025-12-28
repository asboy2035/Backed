//
//  DisplayManager.swift
//  Backed
//
//  Created by ash on 12/28/25.
//

import AppKit
import Combine
import Foundation

@MainActor
final class DisplayManager: ObservableObject {
  static let shared = DisplayManager()
  
  @Published var configurations: [DisplayConfiguration] = []
  @Published var activeConfiguration: DisplayConfiguration?
  @Published var currentDisplays: [DisplayInfo] = []
  
  private init() {
    loadConfigurations()
    detectDisplays()
    
    // Listen for display configuration changes
    NotificationCenter.default.addObserver(
      forName: NSApplication.didChangeScreenParametersNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.detectDisplays()
      }
    }
  }
  
  func detectDisplays() {
    var displays: [DisplayInfo] = []
    
    let maxDisplays: UInt32 = 32
    var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(maxDisplays))
    var displayCount: UInt32 = 0
    
    let result = CGGetActiveDisplayList(maxDisplays, &displayIDs, &displayCount)
    
    guard result == .success else {
      print("Failed to get display list")
      return
    }
    
    let mainDisplayID = CGMainDisplayID()
    
    for i in 0..<Int(displayCount) {
      let displayID = displayIDs[i]
      let bounds = CGDisplayBounds(displayID)
      
      let name = getDisplayName(for: displayID)
      let isPrimary = displayID == mainDisplayID
      
      let display = DisplayInfo(
        id: displayID,
        name: name,
        index: i + 1,
        frame: bounds,
        isPrimary: isPrimary
      )
      
      displays.append(display)
    }
    
    currentDisplays = displays
  }
  
  private func getDisplayName(for displayID: CGDirectDisplayID) -> String {
    // Try to get the display name from NSScreen
    if let screen = NSScreen.screens.first(where: { screen in
      let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
      return screenNumber == displayID
    }) {
      let name = screen.localizedName
      if !name.isEmpty {
        return name
      }
    }
    
    // Fallback to generic name
    if displayID == CGMainDisplayID() {
      return "Built-in Display"
    }
    
    return "External Display"
  }
  
  // MARK: - Configuration Management
  
  func createConfiguration(name: String, displays: [DisplayInfo], wallpaperMode: WallpaperMode) {
    let config = DisplayConfiguration(
      name: name,
      displays: displays,
      wallpaperMode: wallpaperMode
    )
    configurations.append(config)
    saveConfigurations()
  }
  
  func updateConfiguration(_ config: DisplayConfiguration, displays: [DisplayInfo], wallpaperMode: WallpaperMode) {
    guard let index = configurations.firstIndex(where: { $0.id == config.id }) else { return }
    
    configurations[index].displays = displays
    configurations[index].wallpaperMode = wallpaperMode
    
    if activeConfiguration?.id == config.id {
      activeConfiguration = configurations[index]
    }
    
    saveConfigurations()
  }
  
  func renameConfiguration(_ config: DisplayConfiguration, to newName: String) {
    guard let index = configurations.firstIndex(where: { $0.id == config.id }) else { return }
    configurations[index].name = newName
    
    if activeConfiguration?.id == config.id {
      activeConfiguration = configurations[index]
    }
    
    saveConfigurations()
  }
  
  func deleteConfiguration(_ config: DisplayConfiguration) {
    configurations.removeAll { $0.id == config.id }
    
    if activeConfiguration?.id == config.id {
      activeConfiguration = nil
    }
    
    saveConfigurations()
  }
  
  func applyConfiguration(_ config: DisplayConfiguration) {
    activeConfiguration = config
    
    // Apply the display arrangement
    for displayInfo in config.displays {
      // Note: Actually moving displays programmatically requires private APIs
      // This stores the configuration for wallpaper application
    }
    
    // Apply wallpaper based on mode
    if let wallpaper = WallpaperLibrary.shared.activeWallpaper {
      VideoWallpaperEngine.shared.set(wallpaper, mode: config.wallpaperMode, displays: config.displays)
    }
    
    saveConfigurations()
  }
  
  // MARK: - Persistence
  
  private func saveConfigurations() {
    do {
      let data = try JSONEncoder().encode(configurations)
      UserDefaults.standard.set(data, forKey: "displayConfigurations")
      
      if let activeConfig = activeConfiguration {
        UserDefaults.standard.set(activeConfig.id.uuidString, forKey: "activeDisplayConfiguration")
      }
    } catch {
      print("Failed to save display configurations:", error)
    }
  }
  
  private func loadConfigurations() {
    if let data = UserDefaults.standard.data(forKey: "displayConfigurations") {
      do {
        configurations = try JSONDecoder().decode([DisplayConfiguration].self, from: data)
      } catch {
        print("Failed to load display configurations:", error)
      }
    }
    
    if let activeID = UserDefaults.standard.string(forKey: "activeDisplayConfiguration"),
       let uuid = UUID(uuidString: activeID) {
      activeConfiguration = configurations.first { $0.id == uuid }
    }
  }
}

// Helper to get display name
@_silgen_name("CoreDisplay_DisplayCreateInfoDictionary")
private func CoreDisplay_DisplayCreateInfoDictionary(_ display: CGDirectDisplayID) -> Unmanaged<CFDictionary>?
