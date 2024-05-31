//
//  UserAgentEditorSection.swift
//  Unagent
//
//  Created by シン・ジャスティン on 2024/05/31.
//

import Komponents
import SwiftUI

struct UserAgentEditorSection: View {

    var footerText: LocalizedStringKey
    @Binding var userAgent: String

    var body: some View {
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
                    Button("Shared.Paste") {
                        if let pasteboardString = UIPasteboard.general.string {
                            userAgent = pasteboardString
                        }
                    }
                    .textCase(.none)
                }
            }
        } footer: {
            Text(footerText)
        }
    }
}
