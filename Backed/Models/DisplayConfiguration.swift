//
//  DisplayConfiguration.swift
//  Backed
//
//  Created by ash on 12/28/25.
//

import Foundation
import AppKit

enum WallpaperMode: String, Codable, CaseIterable {
  case sameOnAll = "Same on All Displays"
  case stretched = "Stretched Across Displays"
  
  var description: String { rawValue }
}

struct DisplayInfo: Codable, Identifiable, Hashable {
  let id: CGDirectDisplayID
  let name: String
  let index: Int
  var frame: CGRect
  var isPrimary: Bool
  
  init(id: CGDirectDisplayID, name: String, index: Int, frame: CGRect, isPrimary: Bool = false) {
    self.id = id
    self.name = name
    self.index = index
    self.frame = frame
    self.isPrimary = isPrimary
  }
}

struct DisplayConfiguration: Codable, Identifiable, Hashable {
  let id: UUID
  var name: String
  var displays: [DisplayInfo]
  var wallpaperMode: WallpaperMode
  
  init(id: UUID = UUID(), name: String, displays: [DisplayInfo], wallpaperMode: WallpaperMode = .sameOnAll) {
    self.id = id
    self.name = name
    self.displays = displays
    self.wallpaperMode = wallpaperMode
  }
}
