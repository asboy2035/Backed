//
//  VideoWallpaperEngine.swift
//  Backed
//
//  Created by ash on 12/24/25.
//

import AVFoundation
import AppKit

@MainActor
final class VideoWallpaperEngine {
  static let shared = VideoWallpaperEngine()
  
  private var desktopWindows: [CGDirectDisplayID: DesktopWallpaperWindow] = [:]
  private var sleepObserver: NSObjectProtocol?
  private var wakeObserver: NSObjectProtocol?
  private var players: [CGDirectDisplayID: AVPlayer] = [:]
  private var currentMode: WallpaperMode = .sameOnAll
  
  func set(_ wallpaper: Wallpaper) {
    // Use active configuration if available, otherwise default
    if let activeConfig = DisplayManager.shared.activeConfiguration {
      set(wallpaper, mode: activeConfig.wallpaperMode, displays: activeConfig.displays)
    } else {
      let displays = DisplayManager.shared.currentDisplays
      set(wallpaper, mode: .sameOnAll, displays: displays)
    }
  }
  
  func set(_ wallpaper: Wallpaper, mode: WallpaperMode, displays: [DisplayInfo]) {
    stop()
    
    currentMode = mode
    
    switch mode {
    case .sameOnAll:
      setSameOnAllDisplays(wallpaper: wallpaper, displays: displays)
    case .stretched:
      setStretchedAcrossDisplays(wallpaper: wallpaper, displays: displays)
    }
    
    setupSleepWakeObservers()
  }
  
  private func setSameOnAllDisplays(wallpaper: Wallpaper, displays: [DisplayInfo]) {
    for display in displays {
      let player = AVPlayer(url: wallpaper.url)
      player.actionAtItemEnd = .none
      player.isMuted = !WallpaperLibrary.shared.isAudioEnabled
      
      NotificationCenter.default.addObserver(
        forName: .AVPlayerItemDidPlayToEndTime,
        object: player.currentItem,
        queue: .main
      ) { _ in
        player.seek(to: .zero)
        player.play()
      }
      
      let window = DesktopWallpaperWindow()
      window.show(player: player, on: display)
      
      desktopWindows[display.id] = window
      players[display.id] = player
      
      player.play()
    }
  }
  
  private func setStretchedAcrossDisplays(wallpaper: Wallpaper, displays: [DisplayInfo]) {
    // Calculate the total bounding box of all displays
    guard !displays.isEmpty else { return }
    
    let minX = displays.map { $0.frame.minX }.min() ?? 0
    let maxX = displays.map { $0.frame.maxX }.max() ?? 0
    let minY = displays.map { $0.frame.minY }.min() ?? 0
    let maxY = displays.map { $0.frame.maxY }.max() ?? 0
    
    let totalFrame = CGRect(
      x: minX,
      y: minY,
      width: maxX - minX,
      height: maxY - minY
    )
    
    // Create a single player for the stretched video
    let player = AVPlayer(url: wallpaper.url)
    player.actionAtItemEnd = .none
    player.isMuted = !WallpaperLibrary.shared.isAudioEnabled
    
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: player.currentItem,
      queue: .main
    ) { _ in
      player.seek(to: .zero)
      player.play()
    }
    
    // For each display, show a portion of the video
    for display in displays {
      let window = DesktopWallpaperWindow()
      
      // Calculate what portion of the total video this display should show
      let relativeFrame = CGRect(
        x: (display.frame.minX - minX) / totalFrame.width,
        y: (display.frame.minY - minY) / totalFrame.height,
        width: display.frame.width / totalFrame.width,
        height: display.frame.height / totalFrame.height
      )
      
      window.showStretched(player: player, on: display, videoFrame: relativeFrame)
      
      desktopWindows[display.id] = window
    }
    
    // Store the main player
    if let firstDisplay = displays.first {
      players[firstDisplay.id] = player
    }
    
    player.play()
  }
  
  private func setupSleepWakeObservers() {
    let workspace = NSWorkspace.shared.notificationCenter
    
    sleepObserver = workspace.addObserver(
      forName: NSWorkspace.willSleepNotification,
      object: nil,
      queue: .main
    ) { @Sendable [weak self] _ in
      Task { @MainActor [weak self] in
        self?.pauseAll()
      }
    }
    
    wakeObserver = workspace.addObserver(
      forName: NSWorkspace.didWakeNotification,
      object: nil,
      queue: .main
    ) { @Sendable [weak self] _ in
      Task { @MainActor [weak self] in
        self?.playAll()
      }
    }
  }
  
  private func pauseAll() {
    for player in players.values {
      player.pause()
    }
  }
  
  private func playAll() {
    for player in players.values {
      player.play()
    }
  }
  
  func setMuted(_ muted: Bool) {
    for player in players.values {
      player.isMuted = muted
    }
  }
  
  func stop() {
    if let sleepObserver {
      NSWorkspace.shared.notificationCenter.removeObserver(sleepObserver)
      self.sleepObserver = nil
    }
    
    if let wakeObserver {
      NSWorkspace.shared.notificationCenter.removeObserver(wakeObserver)
      self.wakeObserver = nil
    }
    
    for player in players.values {
      player.pause()
      NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player.currentItem)
    }
    
    players.removeAll()
    
    for window in desktopWindows.values {
      window.hide()
    }
    
    desktopWindows.removeAll()
  }
}
