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
    var onSelectWithViewport: ((String, Viewport?) -> ())?

    init(currentUserAgent: @escaping () -> String, onSelect: @escaping (String) -> Void, onSelectWithViewport: ((String, Viewport?) -> ())? = nil) {
        let store = PresetStore()
        self.presets = store.presets
        self.currentUserAgent = currentUserAgent
        self.onSelect = onSelect
        self.onSelectWithViewport = onSelectWithViewport
    }

    var body: some View {
        Section {
            ForEach(presets) { preset in
                Button {
                    var userAgent: String = preset.userAgent
                    let os = ProcessInfo().operatingSystemVersion
                    let replaceTokens: [String: String] = [
                        "%OS_MAJOR%": String(os.majorVersion),
                        "%OS_MINOR%": String(os.minorVersion),
                        "%OS_PATCH%": String(os.patchVersion)
                    ]
                    for (token, replacement) in replaceTokens {
                        if userAgent.contains(token) {
                            userAgent = userAgent.replacingOccurrences(of: token, with: replacement)
                        }
                    }
                    if let onSelectWithViewport = onSelectWithViewport {
                        onSelectWithViewport(userAgent, preset.viewport)
                    } else {
                        onSelect(userAgent)
                    }
                } label: {
                    HStack(spacing: 8.0) {
                        if UIImage(named: preset.imageName) != nil {
                            Image(preset.imageName)
                        } else {
                            Image(systemName: preset.imageName)
                                .frame(width: 24, height: 24)
                                .foregroundStyle(.secondary)
                        }
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
            ListSectionHeader(text: "Shared.Presets")
                .font(.body)
        }
    }
}
