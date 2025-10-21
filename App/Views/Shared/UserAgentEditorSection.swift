//
//  UserAgentEditorSection.swift
//  Unagent
//
//  Created by Copilot on 2025/10/21.
//

import SwiftUI

struct UserAgentEditorSection: View {
    
    @Binding var userAgent: String
    @Binding var viewport: Viewport?
    var showPasteButton: Bool = true
    var headerText: String

    var body: some View {
        Section {
            TextEditor(text: $userAgent)
                .autocorrectionDisabled()
                .autocapitalization(.none)
                .font(.monospaced(.custom("", size: 14.0, relativeTo: .body))())
                .frame(height: 120)
                .scrollIndicators(.never)
            Menu {
                PresetsSection {
                    return userAgent
                } onSelect: { selectedUserAgent in
                    userAgent = selectedUserAgent
                } onSelectWithViewport: { selectedUserAgent, selectedViewport in
                    userAgent = selectedUserAgent
                    viewport = selectedViewport
                }
            } label: {
                Text("Shared.SelectPreset")
            }
        } header: {
            HStack(alignment: .center) {
                Text(NSLocalizedString(headerText, comment: ""))
                Spacer()
                if showPasteButton && UIPasteboard.general.hasStrings {
                    Button("Shared.Paste") {
                        if let pasteboardString = UIPasteboard.general.string {
                            userAgent = pasteboardString
                        }
                    }
                    .textCase(.none)
                }
            }
        } footer: {
            Text("About.UserAgent")
        }
    }
}
