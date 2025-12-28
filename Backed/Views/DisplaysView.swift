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
      win.styleMask = [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView]
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
    NavigationSplitView {
      if configurations.isEmpty {
        Text("No saved configurations")
      } else {
        List {
          Section("Configurations") {
            ForEach(configurations) { config in
              Label {
                VStack(alignment: .leading, spacing: 2) {
                  Text(config.name)
                  Text("\(config.displays.count) display\(config.displays.count == 1 ? "" : "s") • \(config.wallpaperMode.description)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
              } icon: {
                Image(systemName: config.id == selectedConfiguration?.id ?
                      "checkmark" : "display.2"
                )
              }
              .contextMenu {
                Button {
                  configToRename = config
                  newConfigName = config.name
                  showingRenameSheet = true
                } label: {
                  Label("Rename", systemImage: "pencil")
                }
                
                Button(role: .destructive) {
                  displayManager.deleteConfiguration(config)
                } label: {
                  Label("Delete", systemImage: "trash")
                }
              }
              .frame(minWidth: 0, maxWidth: .infinity)
              .padding(8)
              .contentShape(Rectangle())
              .background(config.id == selectedConfiguration?.id ? Color.accentColor : Color.clear)
              .clipShape(RoundedRectangle(cornerRadius: 10))
              .onTapGesture {
                loadConfiguration(config)
              }
            }
          }
        }
        .frame(minWidth: 250)
      }
    } detail: {
      VStack(spacing: 0) {
        // Canvas area for dragging displays
        GeometryReader { geometry in
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
              Button {
                setPrimaryDisplay(display)
              } label: {
                Label("Set as Primary", systemImage: "display.and.arrow.down")
              }
              .disabled(display.isPrimary)
            }
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
        Divider()
        
        // Settings panel
        Form {
          Section("Options") {
            Picker("Wallpaper Mode", selection: $selectedWallpaperMode) {
              ForEach(WallpaperMode.allCases, id: \.self) { mode in
                Text(mode.description).tag(mode)
              }
            }
            
            if let wallpaper = wallpaperLibrary.activeWallpaper {
              HStack {
                Text("Active Wallpaper")
                  .fontWeight(.medium)
                Spacer()
                Text(wallpaper.name)
                  .foregroundStyle(.secondary)
              }
            }
          }
        }
        .formStyle(.grouped)
        .frame(maxHeight: 150)
      }
    }
    .navigationTitle("Displays")
    .toolbar {
      ToolbarItem {
        Button {
          showingNewConfigSheet = true
        } label: {
          Label("New Configuration", systemImage: "plus")
        }
      }
      
      ToolbarItem {
        Button {
          applyConfiguration()
        } label: {
          Label("Apply", systemImage: "checkmark")
        }
        .buttonStyle(.borderedProminent)
        .tint(Color.accent)
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
  let cornerRadius: CGFloat = 16
  
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
            .foregroundStyle(.white)
          
          Text("Display \(display.index)")
            .font(.system(size: 11))
            .foregroundStyle(.white.opacity(0.8))
          
          if display.isPrimary {
            Text("Primary")
              .font(.headline)
              .foregroundStyle(.white)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Color.accentColor.opacity(0.8))
              .cornerRadius(cornerRadius/2)
          }
        }
        .padding(8)
        .background(Color.black.opacity(0.5))
        .cornerRadius(cornerRadius)
        .padding(8)
      }
    }
    .frame(
      width: display.frame.width * scale,
      height: display.frame.height * scale
    )
    .cornerRadius(cornerRadius)
    .overlay(
      RoundedRectangle(cornerRadius: cornerRadius)
        .stroke(display.isPrimary ? Color.accentColor : Color.primary.opacity(0.3), lineWidth: 2)
    )
    .shadow(radius: 4)
  }
}

struct NewConfigurationSheet: View {
  @Binding var configName: String
  let onSave: () -> Void
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    VStack {
      TextField("New Configuration...", text: $configName)
        .textFieldStyle(.plain)
        .font(.largeTitle)
    }
    .padding()
    .frame(width: 400, height: 150)
    .toolbar {
      SheetAction(placement: .cancellationAction) {
        dismiss()
      } label: {
        Label("Cancel", systemImage: "xmark")
      }
      
      SheetAction(
        placement: .confirmationAction,
        disabled: .constant(configName.isEmpty)
      ) {
        onSave()
      } label: {
        Label("Save", systemImage: "checkmark")
      }
    }
  }
}

struct RenameConfigurationSheet: View {
  @Binding var configName: String
  let onSave: () -> Void
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    VStack {
      TextField("Configuration Name", text: $configName)
        .textFieldStyle(.plain)
        .font(.largeTitle)
    }
    .padding()
    .frame(width: 400, height: 150)
    .toolbar {
      SheetAction(placement: .cancellationAction) {
        dismiss()
      } label: {
        Label("Cancel", systemImage: "xmark")
      }
      
      SheetAction(
        placement: .confirmationAction,
        disabled: .constant(configName.isEmpty)
      ) {
        onSave()
      } label: {
        Label("Save", systemImage: "checkmark")
      }
    }
  }
}
