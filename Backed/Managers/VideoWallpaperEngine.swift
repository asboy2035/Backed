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
  
  private let desktopWindow = DesktopWallpaperWindow()
  private var sleepObserver: NSObjectProtocol?
  private var wakeObserver: NSObjectProtocol?
  private var player: AVPlayer?
  
  func set(_ wallpaper: Wallpaper) {
    let player = AVPlayer(url: wallpaper.url)
    player.actionAtItemEnd = .none
    self.player = player
    
    player.isMuted = !WallpaperLibrary.shared.isAudioEnabled
    
    NotificationCenter.default.addObserver(
      forName: .AVPlayerItemDidPlayToEndTime,
      object: player.currentItem,
      queue: .main
    ) { _ in
      player.seek(to: .zero)
      player.play()
    }
    
    desktopWindow.show(player: player)
    
    let workspace = NSWorkspace.shared.notificationCenter
    
    sleepObserver = workspace.addObserver(
      forName: NSWorkspace.willSleepNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.player?.pause()
    }
    
    wakeObserver = workspace.addObserver(
      forName: NSWorkspace.didWakeNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.player?.play()
    }
    
    player.play()
  }
  
  func setMuted(_ muted: Bool) {
      player?.isMuted = muted
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
    
    self.player = nil
    
    desktopWindow.hide()
  }
}
