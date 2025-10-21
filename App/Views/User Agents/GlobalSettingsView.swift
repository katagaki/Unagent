//
//  GlobalSettingsView.swift
//  Unagent
//
//  Created by Copilot on 2025/10/21.
//

import SwiftUI

struct GlobalSettingsView: View {
    
    @Binding var globalUserAgent: String
    @Binding var globalViewportString: String
    var synchronizeDefaults: () -> Void
    
    var globalViewport: Viewport? {
        get {
            if globalViewportString.isEmpty {
                return nil
            }
            return Viewport(rawValue: globalViewportString)
        }
        set {
            globalViewportString = newValue?.rawValue ?? ""
        }
    }
    
    var body: some View {
        List {
            Section {
                Text("GlobalSettings.Description")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            UserAgentEditorSection(
                userAgent: $globalUserAgent,
                viewport: Binding(
                    get: { globalViewport },
                    set: { newValue in
                        globalViewportString = newValue?.rawValue ?? ""
                        synchronizeDefaults()
                    }
                ),
                headerText: "Shared.UserAgent",
                footerText: "GlobalSettings.GlobalUserAgent.Footer"
            )
            
            ViewportPickerSection(
                viewport: Binding(
                    get: { globalViewport },
                    set: { newValue in
                        globalViewportString = newValue?.rawValue ?? ""
                        synchronizeDefaults()
                    }
                ),
                headerText: "Viewport",
                footerText: "GlobalSettings.GlobalViewport.Footer"
            )
        }
        .navigationTitle("ViewTitle.GlobalSettings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
