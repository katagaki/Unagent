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
    
    @State var willSaveUserAgentToMemory: Bool = false
    @State var userAgent: String = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextEditor(text: $userAgent)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .font(.monospaced(.custom("", size: 14.0, relativeTo: .body))())
                        .frame(height: 120)
                        .scrollIndicators(.never)
                } header: {
                    HStack(alignment: .center) {
                        ListSectionHeader(text: "Shared.UserAgent")
                            .font(.body)
                        Spacer()
                        if UIPasteboard.general.hasStrings {
                            Button {
                                if let pasteboardString = UIPasteboard.general.string {
                                    userAgent = pasteboardString
                                }
                            } label: {
                                Text("Shared.Paste")
                            }
                            .textCase(.none)
                        }
                    }
                } footer: {
                    Text("GlobalSettings.GlobalUserAgent.Footer")
                }
                PresetsSection {
                    return userAgent
                } onSelect: { selectedUserAgent in
                    userAgent = selectedUserAgent
                }
            }
            .navigationTitle("ViewTitle.GlobalSettings")
            .onAppear {
                userAgent = defaults.string(forKey: "UserAgent") ?? ""
                willSaveUserAgentToMemory = true
            }
            .onChange(of: userAgent) { newValue in
                if willSaveUserAgentToMemory {
                    defaults.set(newValue, forKey: "UserAgent")
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }
}
