//
//  SwipePhase.swift
//  SwipableCell
//
//  Created by Sergey Tristan on 21.05.2026.
//  Copyright © 2026 Sergey Tristan. All rights reserved.
//

import SwiftUI

internal enum SwipeActionsPhase {
    case closed
    case revealing
    case preparingToFull(fadingProgress: CGFloat, widthDiff: CGFloat)
    case fullSwipe
    
    static let prepareEdgeStart: CGFloat = 1.05
    static let fullSwipeTriggerThreshold:   CGFloat = 1.3
    
    static func phase(for edge: HorizontalEdge, actionsWidth: CGFloat, offset: CGFloat, fullSwipeAvailable:Bool?) -> SwipeActionsPhase {
        let edgeOffset = edge == .trailing ? min(0, offset) : max(0, offset)
        let absOffset  = abs(edgeOffset)
        
        if absOffset <= 0                              { return .closed }
        if !(fullSwipeAvailable ?? false)              { return .revealing}
        if absOffset < actionsWidth * prepareEdgeStart { return .revealing }
        if absOffset < actionsWidth * fullSwipeTriggerThreshold   {
            let fadingProgress  = 1 - (absOffset - actionsWidth * prepareEdgeStart)
            / (actionsWidth * fullSwipeTriggerThreshold - actionsWidth * prepareEdgeStart)
            let widthDiff = absOffset - actionsWidth * prepareEdgeStart
            return .preparingToFull(fadingProgress: fadingProgress, widthDiff: widthDiff)
        }
        return .fullSwipe
    }
    
}
