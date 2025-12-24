//
//  Wallpaper.swift
//  Backed
//
//  Created by ash on 12/24/25.
//


import Foundation

struct Wallpaper: Identifiable, Hashable {
  let id = UUID()
  let url: URL
  let name: String
  let thumbnailURL: URL
}
