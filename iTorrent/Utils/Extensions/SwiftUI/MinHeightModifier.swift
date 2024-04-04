//
//  MinHeightModifier.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 05.04.2024.
//

import SwiftUI

struct MinSystemHeight: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(minHeight: minimumSystemHeightConstraintValue)
    }

    private var minimumSystemHeightConstraintValue: Double {
#if os(visionOS)
        32
#else
        28
#endif
    }
}

extension View {
    func systemMinimumHeight() -> some View {
        modifier(MinSystemHeight())
    }
}
