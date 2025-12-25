//
//  WallpaperFolder.swift
//  Backed
//
//  Created by ash on 12/25/25.
//

import Foundation

struct WallpaperFolder: Identifiable, Codable, Equatable {
  let id: UUID
  var name: String
  var systemImage: String
  var wallpaperIDs: [UUID]

  init(id: UUID = UUID(), name: String, systemImage: String = "folder", wallpaperIDs: [UUID] = []) {
    self.id = id
    self.name = name
    self.systemImage = systemImage
    self.wallpaperIDs = wallpaperIDs
  }
}
