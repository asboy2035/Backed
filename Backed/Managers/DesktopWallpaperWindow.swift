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
  private var playerLayer: AVPlayerLayer?
  
  func show(player: AVPlayer) {
    guard let screen = NSScreen.main else { return }
    let display = DisplayInfo(
      id: CGMainDisplayID(),
      name: "Main",
      index: 1,
      frame: screen.frame,
      isPrimary: true
    )
    show(player: player, on: display)
  }
  
  func show(player: AVPlayer, on display: DisplayInfo) {
    // Find the NSScreen that matches this display
    guard let screen = NSScreen.screens.first(where: { screen in
      let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
      return screenNumber == display.id
    }) else {
      print("Could not find screen for display \(display.id)")
      return
    }
    
    let win: NSWindow
    
    if let existing = window {
      win = existing
    } else {
      let newWindow = NSWindow(
        contentRect: screen.frame,
        styleMask: [.borderless],
        backing: .buffered,
        defer: false,
        screen: screen
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
  
  func showStretched(player: AVPlayer, on display: DisplayInfo, videoFrame: CGRect) {
    // Find the NSScreen that matches this display
    guard let screen = NSScreen.screens.first(where: { screen in
      let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
      return screenNumber == display.id
    }) else {
      print("Could not find screen for display \(display.id)")
      return
    }
    
    let win: NSWindow
    
    if let existing = window {
      win = existing
    } else {
      let newWindow = NSWindow(
        contentRect: screen.frame,
        styleMask: [.borderless],
        backing: .buffered,
        defer: false,
        screen: screen
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
    
    // For stretched mode, we need to use a CALayer approach
    // to show only a portion of the video
    let containerView = NSView(frame: screen.frame)
    containerView.wantsLayer = true
    containerView.layer?.backgroundColor = NSColor.black.cgColor
    
    let layer = AVPlayerLayer(player: player)
    layer.videoGravity = .resizeAspectFill
    
    // Calculate the layer frame to show the correct portion
    let screenWidth = screen.frame.width
    let screenHeight = screen.frame.height
    
    // The video needs to be scaled up so that when we show only a portion,
    // it fills the screen correctly
    let scaledWidth = screenWidth / videoFrame.width
    let scaledHeight = screenHeight / videoFrame.height
    
    let layerFrame = CGRect(
      x: -videoFrame.minX * scaledWidth,
      y: -videoFrame.minY * scaledHeight,
      width: scaledWidth,
      height: scaledHeight
    )
    
    layer.frame = layerFrame
    containerView.layer?.addSublayer(layer)
    
    playerLayer = layer
    
    win.contentView = containerView
    win.setFrame(screen.frame, display: true)
    win.orderBack(nil)
  }
  
  func hide() {
    playerView?.player?.pause()
    playerView?.player = nil
    playerLayer?.player?.pause()
    playerLayer?.player = nil
    playerLayer?.removeFromSuperlayer()
    playerLayer = nil
    window?.orderOut(nil)
    window = nil
  }
}
