
//  SwipeButton.swift
//  SwipableCell
//
//  Created by Sergey Tristan on 13.05.2026.
//  Copyright © 2026 Sergey Tristan. All rights reserved.
//

import SwiftUI

public struct SwipeButton<Label: View>: View {
    @State private var swipeID: UUID = UUID()
    let label:  Label
    let action: () -> Void
    let color:  Color
    let role:   ButtonRole?

    public init(
        color: Color = .gray,
        role:  ButtonRole? = nil,
        action: @escaping () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        self.color  = color
        self.role   = role
        self.action = action
        self.label  = label()
    }

    public var body: some View {
        label
        .contentShape(Capsule())
        .containerValue(\.swipeActionMeta, SwipeActionMeta(id: swipeID, color: color, role: role, action: action))
    }
}

