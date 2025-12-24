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
  
  func show(player: AVPlayer) {
    guard let screen = NSScreen.main else { return }
    
    let view = AVPlayerView()
    view.player = player
    view.videoGravity = .resizeAspectFill
    view.controlsStyle = .none
    
    let win = NSWindow(
      contentRect: screen.frame,
      styleMask: [.borderless],
      backing: .buffered,
      defer: false
    )
    
    win.level = NSWindow.Level(
      rawValue: Int(CGWindowLevelForKey(.desktopWindow))
    )
    
    win.orderBack(nil)
    
    win.ignoresMouseEvents = true
    win.isExcludedFromWindowsMenu = true
    win.collectionBehavior = [.canJoinAllSpaces, .stationary]
    win.backgroundColor = .black
    win.contentView = view
    
    window = win
  }
  
  func hide() {
    window?.orderOut(nil)
    window = nil
  }
}
