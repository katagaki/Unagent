//
//  GlobalSettingsView.swift
//  Unagent
//
//  Created by シンジャスティン on 2023/05/28.
//

import Komponents
import SwiftUI

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
                PresetsSection {
                    return currentUserAgent
                } onSelect: { selectedUserAgent in
                    currentUserAgent = selectedUserAgent
                }
            }
            .navigationTitle("Global Settings")
            .onAppear {
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
