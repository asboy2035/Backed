//
//  DisplaysView.swift
//  Backed
//
//  Created by ash on 12/28/25.
//

import SwiftUI
import Combine

final class DisplaysController {
  static let shared = DisplaysController()
  private init() {}

  private var window: NSWindow?

  func showDisplays() {
    if window == nil {
      let hosting = NSHostingController(rootView: DisplaysView())
      let win = NSWindow(
        contentViewController: hosting
      )
      win.title = "Displays"
      win.styleMask = [.titled, .closable, .miniaturizable, .resizable]
      win.toolbarStyle = .unifiedCompact
      win.setFrameAutosaveName("DisplaysWindow")
      window = win
    }
    window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
  }
}

struct DisplaysView: View {
  @ObservedObject private var displayManager = DisplayManager.shared
  @ObservedObject private var wallpaperLibrary = WallpaperLibrary.shared
  
  @State private var workingDisplays: [DisplayInfo] = []
  @State private var selectedWallpaperMode: WallpaperMode = .sameOnAll
  @State private var selectedConfiguration: DisplayConfiguration?
  @State private var showingNewConfigSheet = false
  @State private var showingRenameSheet = false
  @State private var newConfigName = ""
  @State private var configToRename: DisplayConfiguration?
  @State private var scale: CGFloat = 0.1
  @State private var dragStartPositions: [CGDirectDisplayID: CGPoint] = [:]
  
  // Computed property for bounding box of all displays
  private var boundingBox: CGRect {
    guard !workingDisplays.isEmpty else { return .zero }
    let minX = workingDisplays.map { $0.frame.minX }.min() ?? 0
    let maxX = workingDisplays.map { $0.frame.maxX }.max() ?? 0
    let minY = workingDisplays.map { $0.frame.minY }.min() ?? 0
    let maxY = workingDisplays.map { $0.frame.maxY }.max() ?? 0
    return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
  }
  
  var body: some View {
    VStack(spacing: 0) {
      // Canvas area for dragging displays
      GeometryReader { geometry in
        ZStack {
          Color(nsColor: .controlBackgroundColor)
          
          ForEach(workingDisplays) { display in
            DisplayPreview(
              display: display,
              scale: scale,
              wallpaper: wallpaperLibrary.activeWallpaper
            )
            .position(
              x: geometry.size.width / 2 + (display.frame.midX - boundingBox.midX) * scale,
              y: geometry.size.height / 2 + (display.frame.midY - boundingBox.midY) * scale
            )
            .gesture(
              DragGesture()
                .onChanged { value in
                  if dragStartPositions[display.id] == nil {
                    dragStartPositions[display.id] = display.frame.origin
                  }
                  updateDisplayPosition(display, translation: value.translation)
                }
                .onEnded { _ in
                  dragStartPositions[display.id] = nil
                }
            )
            .contextMenu {
              Button("Set as Primary") {
                setPrimaryDisplay(display)
              }
              .disabled(display.isPrimary)
            }
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      
      Divider()
      
      // Settings panel
      VStack(alignment: .leading, spacing: 16) {
        HStack {
          Text("Wallpaper Mode:")
            .fontWeight(.medium)
          
          Picker("", selection: $selectedWallpaperMode) {
            ForEach(WallpaperMode.allCases, id: \.self) { mode in
              Text(mode.description).tag(mode)
            }
          }
          .pickerStyle(.segmented)
          .frame(maxWidth: 400)
        }
        
        if let wallpaper = wallpaperLibrary.activeWallpaper {
          HStack {
            Text("Active Wallpaper:")
              .fontWeight(.medium)
            Text(wallpaper.name)
              .foregroundColor(.secondary)
          }
        }
      }
      .padding()
      .background(Color(nsColor: .controlBackgroundColor))
    }
    .navigationTitle("Displays")
    .toolbar {
      ToolbarItem(placement: .navigation) {
        Menu {
          if configurations.isEmpty {
            Text("No saved configurations")
              .foregroundColor(.secondary)
          } else {
            ForEach(configurations) { config in
              Button {
                loadConfiguration(config)
              } label: {
                HStack {
                  if config.id == selectedConfiguration?.id {
                    Image(systemName: "checkmark")
                  }
                  VStack(alignment: .leading, spacing: 2) {
                    Text(config.name)
                    Text("\(config.displays.count) display\(config.displays.count == 1 ? "" : "s") • \(config.wallpaperMode.description)")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                }
              }
              .contextMenu {
                Button("Rename") {
                  configToRename = config
                  newConfigName = config.name
                  showingRenameSheet = true
                }
                Button("Delete", role: .destructive) {
                  displayManager.deleteConfiguration(config)
                }
              }
            }
            
            Divider()
          }
          
          Button("New Configuration...") {
            showingNewConfigSheet = true
          }
        } label: {
          Label(
            selectedConfiguration?.name ?? "Select Configuration",
            systemImage: "rectangle.on.rectangle.slash"
          )
        }
        .frame(minWidth: 200)
      }
      
      ToolbarItem {
        Button {
          applyConfiguration()
        } label: {
          Label("Apply", systemImage: "checkmark")
        }
        .keyboardShortcut(.return, modifiers: .command)
      }
    }
    .onAppear {
      initializeDisplays()
    }
    .onReceive(displayManager.$activeConfiguration) { activeConfig in
      // Update local selection if the active config changes externally
      // and we are not in a 'dirty' state (checking if selectedConfiguration matches active might be enough)
      // For now, always sync to active if it's set
      if let active = activeConfig {
        selectedConfiguration = active
        selectedWallpaperMode = active.wallpaperMode
        // Only update displays if we want to force sync, but user might be editing.
        // Let's only update if the current selected config was the one that changed.
        if selectedConfiguration?.id == active.id {
             workingDisplays = active.displays
             calculateScale()
        }
      }
    }
    .onChange(of: wallpaperLibrary.activeWallpaper) { _ in
      // If wallpaper changes, we might want to refresh views or re-check active config state
      // (Handled by DisplayPreview automatically)
    }
    .sheet(isPresented: $showingNewConfigSheet) {
      NewConfigurationSheet(
        configName: $newConfigName,
        onSave: {
          saveNewConfiguration()
        }
      )
    }
    .sheet(isPresented: $showingRenameSheet) {
      if let config = configToRename {
        RenameConfigurationSheet(
          configName: $newConfigName,
          onSave: {
            displayManager.renameConfiguration(config, to: newConfigName)
            showingRenameSheet = false
          }
        )
      }
    }
  }
  
  private var configurations: [DisplayConfiguration] {
    displayManager.configurations
  }
  
  private func initializeDisplays() {
    displayManager.detectDisplays()
    
    // Default to current displays
    workingDisplays = displayManager.currentDisplays
    
    if let active = displayManager.activeConfiguration {
      selectedConfiguration = active
      selectedWallpaperMode = active.wallpaperMode
      workingDisplays = active.displays
    }
    
    calculateScale()
  }
  
  private func calculateScale() {
    guard !workingDisplays.isEmpty else { return }
    
    let bounds = boundingBox
    let padding: CGFloat = 40
    let canvasWidth: CGFloat = 800 - padding * 2
    let canvasHeight: CGFloat = 400 - padding * 2
    
    // Avoid division by zero
    let scaleX = bounds.width > 0 ? canvasWidth / bounds.width : 1
    let scaleY = bounds.height > 0 ? canvasHeight / bounds.height : 1
    
    scale = min(scaleX, scaleY)
  }
  
  private func updateDisplayPosition(_ display: DisplayInfo, translation: CGSize) {
    guard let index = workingDisplays.firstIndex(where: { $0.id == display.id }) else { return }
    guard let startPosition = dragStartPositions[display.id] else { return }
    
    let scaledTranslation = CGSize(
      width: translation.width / scale,
      height: translation.height / scale
    )
    
    var newOrigin = CGPoint(
      x: startPosition.x + scaledTranslation.width,
      y: startPosition.y + scaledTranslation.height // Assuming Y+ is down/down, consistent with screen coords
    )
    
    // Apply snapping
    let snapThreshold: CGFloat = 20
    
    for other in workingDisplays where other.id != display.id {
        // Snap X
        if abs(newOrigin.x - other.frame.maxX) < snapThreshold {
            newOrigin.x = other.frame.maxX
        } else if abs(newOrigin.x - other.frame.minX) < snapThreshold {
            newOrigin.x = other.frame.minX
        } else if abs((newOrigin.x + display.frame.width) - other.frame.minX) < snapThreshold {
            newOrigin.x = other.frame.minX - display.frame.width
        } else if abs((newOrigin.x + display.frame.width) - other.frame.maxX) < snapThreshold {
            newOrigin.x = other.frame.maxX - display.frame.width
        }
        
        // Snap Y
        if abs(newOrigin.y - other.frame.maxY) < snapThreshold {
            newOrigin.y = other.frame.maxY
        } else if abs(newOrigin.y - other.frame.minY) < snapThreshold {
            newOrigin.y = other.frame.minY
        } else if abs((newOrigin.y + display.frame.height) - other.frame.minY) < snapThreshold {
            newOrigin.y = other.frame.minY - display.frame.height
        } else if abs((newOrigin.y + display.frame.height) - other.frame.maxY) < snapThreshold {
            newOrigin.y = other.frame.maxY - display.frame.height
        }
    }
    
    var updatedDisplay = display
    updatedDisplay.frame.origin = newOrigin
    workingDisplays[index] = updatedDisplay
  }
  
  private func setPrimaryDisplay(_ display: DisplayInfo) {
    for index in workingDisplays.indices {
      workingDisplays[index].isPrimary = workingDisplays[index].id == display.id
    }
  }
  
  private func loadConfiguration(_ config: DisplayConfiguration) {
    selectedConfiguration = config
    selectedWallpaperMode = config.wallpaperMode
    workingDisplays = config.displays
    calculateScale()
  }
  
  private func saveNewConfiguration() {
    guard !newConfigName.isEmpty else { return }
    
    displayManager.createConfiguration(
      name: newConfigName,
      displays: workingDisplays,
      wallpaperMode: selectedWallpaperMode
    )
    
    if let newConfig = displayManager.configurations.last {
      selectedConfiguration = newConfig
    }
    
    newConfigName = ""
    showingNewConfigSheet = false
  }
  
  private func applyConfiguration() {
    if let config = selectedConfiguration {
      // Create updated config to ensure we apply the new state
      var updatedConfig = config
      updatedConfig.displays = workingDisplays
      updatedConfig.wallpaperMode = selectedWallpaperMode
      
      displayManager.updateConfiguration(
        config,
        displays: workingDisplays,
        wallpaperMode: selectedWallpaperMode
      )
      displayManager.applyConfiguration(updatedConfig)
      
      // Update local state
      selectedConfiguration = updatedConfig
    } else {
      newConfigName = "Configuration \(configurations.count + 1)"
      showingNewConfigSheet = true
    }
  }
}

struct DisplayPreview: View {
  let display: DisplayInfo
  let scale: CGFloat
  let wallpaper: Wallpaper?
  
  var body: some View {
    ZStack {
      // Wallpaper preview background
      if let wallpaper = wallpaper {
        AsyncImage(url: wallpaper.thumbnailURL) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
        } placeholder: {
          Color.black
        }
      } else {
        Color.black
      }
      
      // Overlay with display info
      VStack {
        Spacer()
        VStack(spacing: 4) {
          Text(display.name)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
          Text("Display \(display.index)")
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.8))
          if display.isPrimary {
            Text("Primary")
              .font(.system(size: 10, weight: .medium))
              .foregroundColor(.white)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Color.blue.opacity(0.8))
              .cornerRadius(4)
          }
        }
        .padding(8)
        .background(Color.black.opacity(0.5))
        .cornerRadius(8)
        .padding(8)
      }
    }
    .frame(
      width: display.frame.width * scale,
      height: display.frame.height * scale
    )
    .cornerRadius(8)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(display.isPrimary ? Color.blue : Color.white.opacity(0.3), lineWidth: 2)
    )
    .shadow(radius: 4)
  }
}

struct NewConfigurationSheet: View {
  @Binding var configName: String
  let onSave: () -> Void
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    VStack(spacing: 20) {
      Text("New Display Configuration")
        .font(.headline)
      
      TextField("Configuration Name", text: $configName)
        .textFieldStyle(.roundedBorder)
        .frame(width: 300)
      
      HStack {
        Button("Cancel") {
          dismiss()
        }
        .keyboardShortcut(.cancelAction)
        
        Button("Save") {
          onSave()
        }
        .keyboardShortcut(.defaultAction)
        .disabled(configName.isEmpty)
      }
    }
    .padding()
    .frame(width: 400, height: 150)
  }
}

struct RenameConfigurationSheet: View {
  @Binding var configName: String
  let onSave: () -> Void
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    VStack(spacing: 20) {
      Text("Rename Configuration")
        .font(.headline)
      
      TextField("Configuration Name", text: $configName)
        .textFieldStyle(.roundedBorder)
        .frame(width: 300)
      
      HStack {
        Button("Cancel") {
          dismiss()
        }
        .keyboardShortcut(.cancelAction)
        
        Button("Save") {
          onSave()
        }
        .keyboardShortcut(.defaultAction)
        .disabled(configName.isEmpty)
      }
    }
    .padding()
    .frame(width: 400, height: 150)
  }
}