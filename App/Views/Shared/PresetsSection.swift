//
//  PresetsSection.swift
//  Unagent
//
//  Created by シン on 2024/03/08.
//

import Komponents
import SwiftUI

struct PresetsSection: View {
    
    var presets: [Preset]
    var currentUserAgent: () -> String
    var onSelect: (String) -> ()

    init(currentUserAgent: @escaping () -> String, onSelect: @escaping (String) -> Void) {
        if let url = Bundle.main.url(forResource: "Presets", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let presets = try? JSONDecoder().decode([Preset].self, from: data) {
            self.presets = presets
        } else {
            self.presets = []
        }
        self.currentUserAgent = currentUserAgent
        self.onSelect = onSelect
    }
    
    var body: some View {
        Section {
            ForEach(presets, id: \.name) { preset in
                Button {
                    onSelect(preset.userAgent)
                } label: {
                    HStack(spacing: 8.0) {
                        Image(preset.imageName)
                        Text(preset.name)
                        Spacer()
                        if currentUserAgent() == preset.userAgent {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16.0))
                                .symbolRenderingMode(.multicolor)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        } header: {
            ListSectionHeader(text: "Presets")
                .font(.body)
        }
    }
}
