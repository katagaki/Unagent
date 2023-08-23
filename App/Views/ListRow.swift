//
//  ListRow.swift
//  Unagent
//
//  Created by シンジャスティン on 2023/08/23.
//

import SwiftUI

struct ListRow: View {
    var image: String
    var title: String
    var subtitle: String?
    var includeSpacer: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 16.0) {
            Image(image)
                .resizable()
                .frame(width: 30.0, height: 30.0)
            VStack(alignment: .leading, spacing: 2.0) {
                Text(title)
                    .font(.body)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            if includeSpacer {
                Spacer()
            }
        }
    }
}
