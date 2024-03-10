//
//  SetUpView.swift
//  Unagent
//
//  Created by シン・ジャスティン on 2024/03/08.
//

import Komponents
import SwiftUI

struct SetUpView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
#if os(iOS) && !targetEnvironment(macCatalyst)
                    Text(verbatim: "1. Open the Settings app.")
                    Text(verbatim: "2. Scroll down and tap 'Safari.'")
                    Text(verbatim: "3. Tap 'Extensions'.")
                    Text(verbatim: "4. Tap 'Unagent'.")
                    Text(verbatim: "5. Toggle Unagent on for the profiles you wish to use Unagent in.")
#else
                    Text(verbatim: "1. Open the Safari app.")
                    Text(verbatim: "2. From the menu bar, select 'Safari' > 'Preferences...'.")
                    Text(verbatim: "3. Select the Extensions tab.")
                    Text(verbatim: "4. Select 'Unagent'.")
                    Text(verbatim: "5. Turn Unagent on by checking it.")
#endif
                } header: {
                    ListSectionHeader(text: "1. Turn On Unagent")
                        .font(.body)
                }
                Section {
#if os(iOS) && !targetEnvironment(macCatalyst)
                    Text(verbatim: "1. Open the Safari app.")
                    Text(verbatim: "2. Tap the 'Aa' icon to the left of the address bar.")
                    Text(verbatim: "3. Tap 'Unagent'.")
                    Text(verbatim: "4. Tap 'Always Allow...'.")
                    Text(verbatim: "5. Tap 'Always Allow on Every Website'.")
#else
                    Text(verbatim: "1. Open the Safari app.")
                    Text(verbatim: "2. Select the Unagent icon on the toolbar.")
                    Text(verbatim: "3. Select 'Always Allow on Every Website...'.")
                    Text(verbatim: "4. Select 'Always Allow on Every Website'.")
#endif
                } header: {
                    ListSectionHeader(text: "2. Give Unagent Access")
                        .font(.body)
                }
            }
            .navigationTitle("ViewTitle.SetUp")
        }
    }
}
