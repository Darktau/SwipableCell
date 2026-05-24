//
//  SwipeCellConfiguration.swift
//  SwipableCell
//
//  Created by Sergey Tristan on 21.05.2026.
//  Copyright © 2026 Sergey Tristan. All rights reserved.
//

import SwiftUI

public struct SwipeCellConfiguration {
    public var trailingActions: AnyView?  = nil
    public var leadingActions:  AnyView?  = nil
    public var fullSwipes: [HorizontalEdge: Bool] = [:]
    public var actionsLayout:SwipeActionsLayout = .base
    public var cellAction: (() -> Void)? = nil
    
    public init(actionsLayout:SwipeActionsLayout = .base) {
        self.actionsLayout = actionsLayout
    }
    public mutating func set(edge: HorizontalEdge, actions: AnyView, allowsFullSwipe: Bool) {
        switch edge {
        case .trailing: trailingActions = actions
        case .leading: leadingActions = actions
        }
        fullSwipes[edge] = allowsFullSwipe
    }
}
