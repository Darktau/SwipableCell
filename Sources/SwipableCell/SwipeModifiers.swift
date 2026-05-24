//
//  SwipeModifiers.swift
//  SwipableCell
//
//  Created by Sergey Tristan on 21.05.2026.
//  Copyright © 2026 Sergey Tristan. All rights reserved.
//

import SwiftUI

public extension View {
    func makeSwipeActions<T: View>(
        edge: HorizontalEdge = .trailing,
        allowsFullSwipe: Bool = false,
        @ViewBuilder actions: () -> T
    ) -> SwipeableCell<Self> {
        var config = SwipeCellConfiguration()
        config.set(edge: edge, actions: AnyView(actions()), allowsFullSwipe: allowsFullSwipe)
        return SwipeableCell(content: self, configuration: config)
    }
}

public extension SwipeableCell {
    func makeSwipeActions<T: View>(
        edge: HorizontalEdge = .trailing,
        allowsFullSwipe: Bool = false,
        @ViewBuilder actions: () -> T
    ) -> SwipeableCell {
        var config = configuration
        config.set(edge: edge, actions: AnyView(actions()), allowsFullSwipe: allowsFullSwipe)
        return SwipeableCell(content: content, configuration: config)
    }
}

public extension View {
    func swipeActionsLayout(_ layout: SwipeActionsLayout) -> SwipeableCell<Self> {
        var config = SwipeCellConfiguration()
        config.actionsLayout = layout
        return SwipeableCell(content: self, configuration: config)
    }
}

public extension SwipeableCell {
    func swipeActionsLayout(_ layout: SwipeActionsLayout) -> SwipeableCell {
        var config = configuration
        config.actionsLayout = layout
        return SwipeableCell(content: content, configuration: config)
    }
}

public extension View {
    func cellAction(action: @escaping () -> Void) -> SwipeableCell<Self> {
        var config = SwipeCellConfiguration()
        config.cellAction = action
        return SwipeableCell(content: self, configuration: config)
    }
}

public extension SwipeableCell {
    func cellAction(action: @escaping () -> Void) -> SwipeableCell {
        var config = configuration
        config.cellAction = action
        return SwipeableCell(content: content, configuration: config)
    }
}
