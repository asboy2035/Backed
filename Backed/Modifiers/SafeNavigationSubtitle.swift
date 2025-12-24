//
//  SafeNavigationSubtitle.swift
//  Backed
//
//  Created by ash on 12/24/25.
//

import SwiftUI

struct SafeNavigationSubtitle: ViewModifier {
  let title: String
  
  func body(content: Content) -> some View {
    if #available(macOS 26, *) {
      content.navigationSubtitle(title)
    } else {
      content
    }
  }
}
