//
//  SafeGlassEffect.swift
//  Backed
//
//  Created by ash on 12/28/25.
//

import SwiftUI

struct SafeGlassEffect: ViewModifier {
  var cornerRadius: CGFloat?
  var isClear: Bool

  func body(content: Content) -> some View {
    let shape: AnyShape = {
      if let r = cornerRadius {
        return AnyShape(RoundedRectangle(cornerRadius: r))
      } else {
        return AnyShape(Capsule())
      }
    }()

    if #available(macOS 26.0, *) {
      if isClear {
        content.glassEffect(.clear, in: shape)
      } else {
        content.glassEffect(in: shape)
      }
    } else {
      content
    }
  }
}

extension View {
  func safeGlass(cornerRadius: CGFloat? = nil, clear: Bool = false) -> some View {
    modifier(SafeGlassEffect(cornerRadius: cornerRadius, isClear: clear))
  }
}
