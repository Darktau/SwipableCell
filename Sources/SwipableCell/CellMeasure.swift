//
//  MeasureSizeModifier.swift
//  SwipableCell
//
//  Created by Sergey Tristan on 22.08.2025.
//  Copyright © 2026 Sergey Tristan. All rights reserved.
//


import SwiftUI

internal struct SizePreferenceKey: PreferenceKey {
    static let defaultValue: CGSize = .zero
    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        value = nextValue()
    }
}

internal struct MeasureSizeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.overlay(GeometryReader { geometry in
            Color.clear.preference(key: SizePreferenceKey.self,
                                   value: geometry.size)
        })
    }
}

internal extension View {
    func measureSize(perform action: @escaping (CGSize) -> Void) -> some View {
        self.modifier(MeasureSizeModifier.init())
            .onPreferenceChange(SizePreferenceKey.self, perform: action)
    }
}
