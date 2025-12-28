//
//  SheetAction.swift
//  Backed
//
//  Created by ash on 12/28/25.
//

import SwiftUI

struct SheetAction<Label: View>: ToolbarContent {
  let placement: ToolbarItemPlacement
  @Binding var disabled: Bool?
  let action: () -> Void
  @ViewBuilder var label: () -> Label

  init(
    placement: ToolbarItemPlacement,
    disabled: Binding<Bool?>? = nil,
    action: @escaping () -> Void,
    @ViewBuilder label: @escaping () -> Label
  ) {
    self.placement = placement
    self._disabled = disabled ?? .constant(nil)
    self.action = action
    self.label = label
  }
  
  var body: some ToolbarContent {
    ToolbarItem(placement: placement) {
      Button(action: action) {
        label()
          .padding(.vertical, 4)
      }
      .disabled(disabled ?? false)
      .clipShape(.capsule)
    }
  }
}

#Preview {
  HStack {
    Text("Content")
      .font(.largeTitle)
  }
  .toolbar {
    SheetAction(placement: .confirmationAction) {
      
    } label: {
      Label("Confirm", systemImage: "checkmark")
    }
  }
}
