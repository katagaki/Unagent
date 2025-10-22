//
//  SiteSettingEditor.swift
//  Unagent
//
//  Created by シンジャスティン on 2023/05/28.
//

import SwiftUI

struct SiteSettingEditor: View {
    
    @Environment(\.dismiss) var dismiss

    @State var mode: EditorMode

    @Binding var domain: String
    @Binding var userAgent: String
    @Binding var viewport: Viewport?
    @Binding var shouldSave: Bool
    var onValidate: ((String) -> Bool)?
    
    @State private var showDuplicateError: Bool = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField(text: $domain) {
                        Text("Shared.DomainName")
                    }
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .disabled(mode == .edit)
                    .foregroundStyle(mode == .edit ? Color.secondary : Color.primary)
                } footer: {
                    Text(verbatim: NSLocalizedString("SiteSettings.DomainName.Example", comment: ""))
                }
                
                UserAgentEditorSection(
                    userAgent: $userAgent,
                    viewport: $viewport
                )
                
                ViewportPickerSection(
                    viewport: $viewport,
                    isOptional: true
                )
            }
            .navigationTitle(mode == .new ? "ViewTitle.SiteSettings.New" : "ViewTitle.SiteSettings.Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Shared.Cancel", role: .cancel) {
                        shouldSave = false
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // Validate before saving (for new mode only)
                        if mode == .new, let validator = onValidate {
                            if validator(domain) {
                                showDuplicateError = true
                                return
                            }
                        }
                        shouldSave = true
                        dismiss()
                    } label: {
                        switch mode {
                        case .new:
                            Text("Shared.Add")
                        case .edit:
                            Text("Shared.Save")
                        }
                    }
                    .disabled(domain == "" || userAgent == "")
                }
            }
            .alert("Error.DuplicateDomain.Title", isPresented: $showDuplicateError) {
                Button("Shared.OK", role: .cancel) { }
            } message: {
                Text("Error.DuplicateDomain.Message")
            }
        }
    }
}
