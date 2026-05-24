//
//  SwipeActionLayout.swift
//  SwipableCell
//
//  Created by Sergey Tristan on 21.05.2026.
//  Copyright © 2026 Sergey Tristan. All rights reserved.
//

import SwiftUI

public struct SwipeButtonMetrics : Sendable{
    public let width: CGFloat
    public let height: CGFloat

    public static let base = SwipeButtonMetrics(width: 58, height: 44)
}

public struct SwipeActionsLayout : Sendable{
    public let orientation:Axis
    public let buttonMetrics: SwipeButtonMetrics
    public let spacing: CGFloat
    public let containerPadding: CGFloat
    
    public var appearanceThreshold: CGFloat { buttonMetrics.width / 2 + containerPadding }
    public static let base = SwipeActionsLayout(orientation: .horizontal, buttonMetrics: .base, spacing: 8, containerPadding: 8)
    
    public func width(for count: Int) -> CGFloat {
        guard count > 0 else { return 0 }
        switch orientation {
        case .vertical:   return buttonMetrics.width
        case .horizontal: return CGFloat(count) * buttonMetrics.width
                               + CGFloat(count - 1) * spacing
        }
    }

    public func height(for count: Int) -> CGFloat {
        guard count > 0 else { return 0 }
        switch orientation {
        case .horizontal: return buttonMetrics.height
        case .vertical:   return CGFloat(count) * buttonMetrics.height
                               + CGFloat(count - 1) * spacing
        }
    }
}

public extension SwipeActionsLayout {
     var swipeLayout: AnyLayout {
        switch orientation {
        case .horizontal: AnyLayout(HStackLayout(spacing: spacing))
        case .vertical:   AnyLayout(VStackLayout(spacing: spacing))
        }
    }
}

public extension SwipeActionsLayout {
    static func layout(for orientation: Axis) -> SwipeActionsLayout {
        switch orientation {
        case .horizontal:
            return .base
        case .vertical:
            return SwipeActionsLayout(
                orientation: .vertical,
                buttonMetrics: .base,
                spacing: 8,
                containerPadding: 8
                )
        }
    }
}

public extension SwipeActionsLayout {
    static func custom(
        orientation: Axis = .horizontal,
        buttonWidth: CGFloat = SwipeButtonMetrics.base.width,
        buttonHeight: CGFloat = SwipeButtonMetrics.base.height,
        spacing: CGFloat = 8,
        containerPadding: CGFloat = 8
    ) -> SwipeActionsLayout {
        SwipeActionsLayout(
            orientation: orientation,
            buttonMetrics: SwipeButtonMetrics(width: buttonWidth, height: buttonHeight),
            spacing: spacing,
            containerPadding: containerPadding
        )
    }
}

internal struct SwipeActionsState {
    let edge: HorizontalEdge
    let phase: SwipeActionsPhase
    let actionsLayout: SwipeActionsLayout
    let ids:[UUID]
    let overallProgress:CGFloat
    let fullSwipeAvailable:Bool
    
    func shouldHide(itemID: UUID) -> Bool {
        let isCurrentHero = isHero(itemID: itemID)
        switch phase {
        case .preparingToFull(let opPercent, _):
            return !isCurrentHero && opPercent < 0.5
        case .fullSwipe:
            return !isCurrentHero
        default: return false
        }
    }
    
    func scale(itemID: UUID) -> CGFloat {
        guard actionsLayout.orientation == .horizontal else { return 1 }
        let sp = segmentProgress(for: itemID)
        switch phase {
        case .closed:    return 0
        case .revealing: return sp
        case .preparingToFull, .fullSwipe: return 1
        }
    }
    
    func opacity(itemID: UUID) -> CGFloat {
        let isCurrentHero = isHero(itemID: itemID)
        let sp = segmentProgress(for: itemID)
        
        switch phase {
        case .closed:
            return 0
        case .revealing:
            return sp
        case .preparingToFull(let opPercent, _):
            if actionsLayout.orientation == .vertical { return sp }
            return isCurrentHero ? 1 : opPercent
        case .fullSwipe:
            if actionsLayout.orientation == .vertical { return 1 }
            return isCurrentHero ? 1 : 0
        }
    }
   
    func segmentProgress(for itemID: UUID) -> CGFloat {
        guard ids.count > 0 else { return 0 }
        let index = ids.firstIndex(of: itemID) ?? 0
        
        let effectiveIndex: Int
        switch (actionsLayout.orientation, edge) {
        case (.horizontal, .trailing): effectiveIndex = ids.count - 1 - index
        case (.horizontal, .leading):  effectiveIndex = index
        case (.vertical, _):           effectiveIndex = ids.count - 1 - index
        }
        
        let segmentSize  = 1.0 / CGFloat(ids.count)
        let segmentStart = CGFloat(effectiveIndex) * segmentSize
        return max(0, min(1, (overallProgress - segmentStart) / segmentSize))
    }
    
    func isHero(itemID:UUID) -> Bool {
        let index = ids.firstIndex(of: itemID) ?? 0
        let fullSwipeIndex: Int = actionsLayout.orientation == .vertical ? ids.count - 1 : edge == .trailing ? ids.count - 1 : 0
        return index == fullSwipeIndex && fullSwipeAvailable
    }
}
