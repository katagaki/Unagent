//
//  SetUpView.swift
//  Unagent
//
//  Created by シン・ジャスティン on 2024/03/08.
//

import SwiftUI

struct SetUpView: View {
    var body: some View {
#if os(iOS) || os(watchOS) || os(tvOS)
        Text("Set up Unagent in Settings > Safari > Extensions.")
#else
        Text("Set up Unagent in Safari > Settings > Extensions.")
#endif
    }
}
