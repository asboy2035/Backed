//
//  Wallpaper.swift
//  Backed
//
//  Created by ash on 12/24/25.
//


import Foundation

struct Wallpaper: Identifiable, Codable, Equatable {
  let id: UUID
  var url: URL
  var name: String
  var thumbnailURL: URL

  init(id: UUID = UUID(), url: URL, name: String, thumbnailURL: URL) {
    self.id = id
    self.url = url
    self.name = name
    self.thumbnailURL = thumbnailURL
  }
}
