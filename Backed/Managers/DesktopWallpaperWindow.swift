//
//  DesktopWallpaperWindow.swift
//  Backed
//
//  Created by ash on 12/24/25.
//

import AppKit
import AVKit

final class DesktopWallpaperWindow {
  private var window: NSWindow?
  private var playerView: AVPlayerView?
  
  func show(player: AVPlayer) {
    guard let screen = NSScreen.main else { return }
    
    let win: NSWindow
    
    if let existing = window {
      win = existing
    } else {
      let newWindow = NSWindow(
        contentRect: screen.frame,
        styleMask: [.borderless],
        backing: .buffered,
        defer: false
      )
      
      newWindow.level = NSWindow.Level(
        rawValue: Int(CGWindowLevelForKey(.desktopWindow))
      )
      
      newWindow.orderBack(nil)
      newWindow.ignoresMouseEvents = true
      newWindow.isExcludedFromWindowsMenu = true
      newWindow.collectionBehavior = [.canJoinAllSpaces, .stationary]
      newWindow.backgroundColor = .black
      
      window = newWindow
      win = newWindow
    }
    
    if let existingView = playerView {
      existingView.player?.pause()
      existingView.player = player
      existingView.videoGravity = .resizeAspectFill
      existingView.controlsStyle = .none
    } else {
      let newView = AVPlayerView()
      newView.player = player
      newView.videoGravity = .resizeAspectFill
      newView.controlsStyle = .none
      playerView = newView
    }
    
    win.setFrame(screen.frame, display: true)
    if let playerView {
      win.contentView = playerView
    }
    win.orderBack(nil)
  }
  
  func hide() {
    playerView?.player?.pause()
    playerView?.player = nil
    window?.orderOut(nil)
    window = nil
  }
}
