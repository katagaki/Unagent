//
//  ListSectionHeader.swift
//  Unagent
//
//  Created by シンジャスティン on 2023/08/23.
//

import SwiftUI

struct ListSectionHeader: View {
    var text: String

    var body: some View {
        Text(text)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .textCase(nil)
            .lineLimit(1)
            .truncationMode(.middle)
            .allowsTightening(true)
    }
}
