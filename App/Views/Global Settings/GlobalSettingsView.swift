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
                UserAgentEditorSection(footerText: "GlobalSettings.GlobalUserAgent.Footer",
                                       userAgent: $userAgent)
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
                    defaults.set(true, forKey: "ShouldExtensionUpdate")
                    defaults.synchronize()
                }
            }
            .scrollDismissesKeyboard(.immediately)
        }
    }
}
