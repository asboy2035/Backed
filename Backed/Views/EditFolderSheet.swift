//
//  EditFolderSheet.swift
//  Backed
//
//  Created by ash on 12/25/25.
//

import SwiftUI

struct EditFolderSheet: View {
  @State var name: String
  @State var icon: String
  let folder: WallpaperFolder
  
  @EnvironmentObject var library: WallpaperLibrary
  @Environment(\.dismiss) var dismiss
  
  let icons = ["folder", "house", "star", "sparkles", "sun.max", "moon", "photo", "film", "waveform"]
  
  var body: some View {
    VStack {
      TextField("Folder Name", text: $name)
        .textFieldStyle(.plain)
        .font(.title)
      
      ScrollView {
        let columns = [
          GridItem(.adaptive(minimum: 60), spacing: 16)
        ]
        
        LazyVGrid(columns: columns, spacing: 16) {
          ForEach(icons, id: \.self) { iconName in
            Image(systemName: iconName)
              .font(.system(size: 32))
              .frame(width: 60, height: 60)
              .background(icon == iconName ? Color.accent.opacity(0.2) : .clear)
              .cornerRadius(18)
              .onTapGesture { icon = iconName }
          }
        }
      }
    }
    .frame(width: 450)
    .padding()
    .toolbar {
      ToolbarItem(placement: .cancellationAction) {
        Button {
          dismiss()
        } label: {
          Label("Cancel", systemImage: "xmark")
            .padding(.vertical, 4)
        }
        .clipShape(.capsule)
      }

      ToolbarItem(placement: .confirmationAction) {
        Button {
          library.renameFolder(folder, to: name)
          library.changeFolderIcon(folder, to: icon)
          dismiss()
        } label: {
          Label("Done", systemImage: "checkmark")
            .padding(.vertical, 4)
        }
        .buttonStyle(.borderedProminent)
        .clipShape(.capsule)
      }
      
      ToolbarItem(placement: .destructiveAction) {
        Button {
          library.deleteFolder(folder)
          dismiss()
        } label: {
          Label("Delete", systemImage: "trash")
            .padding(.vertical, 4)
        }
        .tint(.red)
        .clipShape(.capsule)
      }
    }
  }
}
