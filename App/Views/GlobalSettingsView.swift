//
//  GlobalSettingsView.swift
//  Unagent
//
//  Created by シンジャスティン on 2023/05/28.
//

import SwiftUI

class GlobalSettingsViewController: UIHostingController<GlobalSettingsView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: GlobalSettingsView())
    }
}

struct GlobalSettingsView: View {
    
    let defaults: UserDefaults = UserDefaults(suiteName: "group.\(Bundle.main.bundleIdentifier!)")!
    
    @State var presets: [Preset] = []
    @State var willSaveUserAgentToMemory: Bool = false
    @State var currentUserAgent: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextEditor(text: $currentUserAgent)
                        .font(.monospaced(.body)())
                        .frame(height: 150)
                        .scrollIndicators(.never)
                } header: {
                    HStack(alignment: .center) {
                        ListSectionHeader(text: "Global User Agent")
                            .font(.body)
                        Spacer()
                        Button {
                            UIPasteboard.general.string = currentUserAgent
                        } label: {
                            Text("Copy")
                        }
                        .textCase(.none)
                    }
                } footer: {
                    Text("Setting a site-specific user agent will override the global user agent.")
                }
                Section {
                    ForEach(presets, id: \.name) { preset in
                        HStack(spacing: 8.0) {
                            Image(preset.imageName)
                            Text(preset.name)
                            Spacer()
                            if preset.userAgent == currentUserAgent {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16.0))
                                    .symbolRenderingMode(.multicolor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            currentUserAgent = preset.userAgent
                        }
                    }
                } header: {
                    ListSectionHeader(text: "Presets")
                        .font(.body)
                }
            }
            .navigationTitle("Global Settings")
            .onAppear {
                if let url = Bundle.main.url(forResource: "Presets", withExtension: "json"),
                   let data = try? Data(contentsOf: url) {
                    let decoder = JSONDecoder()
                    if let presets = try? decoder.decode([Preset].self, from: data) {
                        self.presets = presets
                    }
                }
                if defaults.string(forKey: "UserAgent") == nil {
                    defaults.set(presets[0].userAgent, forKey: "UserAgent")
                }
                currentUserAgent = defaults.string(forKey: "UserAgent") ?? ""
                willSaveUserAgentToMemory = true
            }
            .onChange(of: currentUserAgent) { newValue in
                if willSaveUserAgentToMemory {
                    defaults.set(newValue, forKey: "UserAgent")
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }
}
