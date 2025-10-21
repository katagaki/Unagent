//
//  ViewportPickerSection.swift
//  Unagent
//
//  Created by Copilot on 2025/10/21.
//

import SwiftUI

struct ViewportPickerSection: View {
    
    @Binding var viewport: Viewport?
    var headerText: String
    var footerText: String
    var isOptional: Bool = false
    
    var body: some View {
        Section {
            if isOptional {
                Picker("Viewport", selection: $viewport) {
                    Text("Default").tag(Viewport?.none)
                    ForEach(Viewport.allCases.filter { $0 != .none }, id: \.self) { viewportOption in
                        Text(viewportOption.displayName).tag(Viewport?.some(viewportOption))
                    }
                }
            } else {
                Picker("Viewport", selection: Binding(
                    get: { viewport ?? .none },
                    set: { newValue in
                        viewport = newValue == .none ? nil : newValue
                    }
                )) {
                    Text("Default").tag(Viewport.none)
                    ForEach(Viewport.allCases.filter { $0 != .none }, id: \.self) { viewportOption in
                        Text(viewportOption.displayName).tag(viewportOption)
                    }
                }
            }
        } header: {
            Text(headerText)
        } footer: {
            Text(footerText)
        }
    }
}
