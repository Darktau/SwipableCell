//
//  SwipeCoordinator.swift
//  SwipableCell
//
//  Created by Sergey Tristan on 13.05.2026.
//  Copyright © 2026 Sergey Tristan. All rights reserved.
//

import SwiftUI

// MARK: - Coordinator
@MainActor
@Observable
internal class SwipeCoordinator {
    var openedID: UUID? = nil

    func close()           { openedID = nil }
    func open(_ id: UUID)  { openedID = id  }
}

// MARK: - Environment key (optional so SwipeableCell never crashes without one)

internal struct SwipeCoordinatorKey: EnvironmentKey {
    static let defaultValue: SwipeCoordinator? = nil
}

internal extension EnvironmentValues {
    var swipeCoordinator: SwipeCoordinator? {
        get { self[SwipeCoordinatorKey.self] }
        set { self[SwipeCoordinatorKey.self] = newValue }
    }
}

// MARK: - Modifier  (uses @State so the coordinator survives view re-evaluations)
internal struct SwipableModifier: ViewModifier {
    @State private var coordinator = SwipeCoordinator()

    func body(content: Content) -> some View {
        content
            .environment(\.swipeCoordinator, coordinator)
            .simultaneousGesture(DragGesture(minimumDistance: 15).onChanged({ value in
                let translation = value.translation
                let isHorizontal = abs(translation.width) > abs(translation.height)
                if !isHorizontal && abs(translation.height) > 15 {
                    coordinator.close()
                }
            }), including: coordinator.openedID != nil ? .gesture : .subviews)
    }
}

public extension View {
    func makeSwipable() -> some View {
        modifier(SwipableModifier())
    }
}

// MARK: - ContainerValues  (consumed by SwipeableCell's actionsContainer)

internal extension ContainerValues {
    @Entry var swipeActionMeta: SwipeActionMeta = .default
}

internal struct SwipeActionMeta: Equatable, @unchecked Sendable {
    let id:     UUID
    let color:  Color
    let role:   ButtonRole?
    let action: () -> Void
    
    static func == (lhs: SwipeActionMeta, rhs: SwipeActionMeta) -> Bool {
            return lhs.id == rhs.id
        }
}

internal extension SwipeActionMeta {
    static let `default` = SwipeActionMeta(id: UUID(), color: .gray, role: nil,action: {})
}
