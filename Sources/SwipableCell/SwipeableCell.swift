//
//  SwipeableCell.swift
//  SwipableCell
//
//  Created by Sergey Tristan on 13.05.2026.
//  Copyright © 2026 Sergey Tristan. All rights reserved.
//

import SwiftUI

public struct SwipeableCell<Content: View>: View {
    
    @Environment(\.swipeCoordinator) private var coordinator
    
    let content: Content
    let configuration: SwipeCellConfiguration
    
    private var trailingActions: AnyView?               { configuration.trailingActions }
    private var leadingActions:  AnyView?               { configuration.leadingActions  }
    private var fullSwipes:      [HorizontalEdge: Bool] { configuration.fullSwipes      }
    private var actionsLayout:   SwipeActionsLayout     { configuration.actionsLayout   }
 
    private let id = UUID()
    
    public init(content: Content, configuration: SwipeCellConfiguration = .init()) {
        self.content = content
        self.configuration = configuration
    }
    
    @State        private var isHorizontalDrag: Bool   = false
    @State        private var offset:           CGFloat = 0
    @State        private var oldOffset:        CGFloat = 0
    @State        private var lockedEdge:       HorizontalEdge? = nil
    
    @State private var cellWidth: CGFloat = .zero
    @State private var frameHeight: CGFloat? = nil
    @State private var heightLocked: Bool = false
    
    @State private var trailingMeta: [SwipeActionMeta] = []
    @State private var leadingMeta:  [SwipeActionMeta] = []
    
    private var trailingWidth: CGFloat { actionsLayout.width(for: trailingMeta.count)}
    private var leadingWidth:  CGFloat { actionsLayout.width(for: leadingMeta.count) }
    
    public  var body: some View {
        ZStack(alignment: .center) {
            
            if let trailingActions {
                HStack(spacing: 0) {
                    Spacer()
                    actionsContainer(for: .trailing, with: trailingActions)
                }
                .opacity(lockedEdge == .trailing ? 1 : 0)
            }
            
            if let leadingActions {
                HStack(spacing: 0) {
                    actionsContainer(for: .leading, with: leadingActions)
                    Spacer()
                }
                .opacity(lockedEdge == .leading ? 1 : 0)
            }
            
            content
                .offset(x: offset)
                .tag(id)
            
            PanGestureView(
                onChanged: { handlePanChanged($0) },
                onEnded: { handlePanEnded($0) }
            )
            .offset(x: offset)
            .simultaneousGesture(TapGesture().onEnded({ g in
                if let cellAction = configuration.cellAction {
                    cellAction()
                }
            }))
        }
        .frame(height: frameHeight)
        .measureSize {
            cellWidth = $0.width
            if !heightLocked {
                frameHeight = $0.height
            }
        }
        .clipped()
        .onChange(of: coordinator?.openedID) { _, newID in
            guard newID != id, offset != 0 else { return }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) {
                snapClosed()
            }
        }
    }
    
    private func handlePanChanged(_ gesture: UIPanGestureRecognizer) {
        let t = gesture.translation(in: nil)
        guard isHorizontalDrag || abs(t.x) > abs(t.y) * 5.0 else { //, abs(t.x) > 15
            if coordinator?.openedID != id { coordinator?.close() }
            return
        }
        
        if !isHorizontalDrag {
            isHorizontalDrag = true
            if coordinator?.openedID != id { coordinator?.close() }
            if lockedEdge == nil {
                lockedEdge = t.x < 0 ? .trailing : .leading
                coordinator?.open(id)
            }
            offset = rubberBand(t.x + oldOffset)
            return
        }
        offset = rubberBand(t.x + oldOffset)
    }
    
    private func handlePanEnded(_ gesture: UIPanGestureRecognizer) {
        isHorizontalDrag = false
        let velocity = gesture.velocity(in: nil).x
        snapToPosition(velocity: velocity)
    }
    
    private func snapToPosition(velocity: CGFloat) {
        if fullSwipes[.trailing] == true, offset < -(trailingWidth * SwipeActionsPhase.fullSwipeTriggerThreshold) {
            triggerFullSwipe(edge: .trailing); return
        }
        
        if fullSwipes[.leading] == true, offset > leadingWidth * SwipeActionsPhase.fullSwipeTriggerThreshold {
            triggerFullSwipe(edge: .leading); return
        }
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            if offset < 0, trailingWidth > 0, lockedEdge == .trailing,
               offset < -(trailingWidth * 0.6) || velocity < -300 {
                offset    = -trailingWidth - actionsLayout.containerPadding
                oldOffset = -trailingWidth - actionsLayout.containerPadding
                coordinator?.open(id)
                return
            }
            
            if offset > 0, leadingWidth > 0, lockedEdge == .leading,
               offset > (leadingWidth * 0.6) || velocity > 300 {
                offset    = leadingWidth + actionsLayout.containerPadding
                oldOffset = leadingWidth + actionsLayout.containerPadding
                coordinator?.open(id)
                return
            }
            
            snapClosed()
        }
    }
    
    private func snapClosed() {
        offset    = 0
        oldOffset = 0
        lockedEdge  = nil
        coordinator?.close()
    }
    
    private func triggerFullSwipe(edge: HorizontalEdge) {
        let action: (() -> Void)?
        let role:ButtonRole?
        switch edge {
        case .trailing:
            action = trailingMeta.last?.action
            role =  trailingMeta.last?.role
        case .leading:
            action = leadingMeta.first?.action
            role = leadingMeta.first?.role
        }
        oldOffset = 0
        coordinator?.close()
        
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            switch edge {
            case .trailing: offset = -(cellWidth * 1.05)
            case .leading:  offset =  cellWidth * 1.05
            }
        } completion: {
            if role == .destructive {
                heightLocked = true
                playDestructive {
                    action?()
                }
            } else {
                action?()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                    offset = 0
                    lockedEdge  = nil
                }
            }
        }
    }
    
    private func playDestructive(action: (() -> Void)?) {
        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
            frameHeight = 0
            offset = 0
            lockedEdge  = nil
        } completion: {
            action?()
        }
    }
    
    private func rubberBand(_ value: CGFloat) -> CGFloat {
        let maxNeg = trailingActions != nil ? trailingWidth : 0
        let maxPos = leadingActions  != nil ? leadingWidth  : 0
        if value < -maxNeg {
            return -maxNeg + (value + maxNeg) * 0.25
        } else if value > maxPos {
            return maxPos + (value - maxPos) * 0.25
        }
        return value
    }
    
    private func makeRenderInfo(for edge: HorizontalEdge, meta: [SwipeActionMeta]) -> (state: SwipeActionsState, size: CGSize) {
        
        let ids = meta.map(\.id)
        let width = actionsLayout.width(for: meta.count)
        let edgeOffset      = edge == .trailing ? min(0, offset) : max(0, offset)
        let adjustedOffset  = max(0, abs(edgeOffset) - actionsLayout.appearanceThreshold)
        let adjustedWidth   = width - actionsLayout.appearanceThreshold
        let overallProgress = adjustedWidth > 0 ? min(1, adjustedOffset / adjustedWidth) : 0
        let containerWidth  = fullSwipes[edge] ?? false
        ? max(abs(edgeOffset) - actionsLayout.containerPadding, width)
        : width
        let containerHeight  = actionsLayout.height(for: meta.count)
        
        let phase = SwipeActionsPhase.phase(
            for: edge,
            actionsWidth: width,
            offset: edgeOffset,
            fullSwipeAvailable: fullSwipes[edge]
        )
        let layout = SwipeActionsState(
            edge: edge,
            phase: phase,
            actionsLayout: actionsLayout,
            ids: ids,
            overallProgress: overallProgress,
            fullSwipeAvailable: fullSwipes[edge] ?? false
        )
        
        return (layout, CGSize(width: containerWidth, height: containerHeight))
    }
    
    @ViewBuilder
    private func actionsContainer(for edge: HorizontalEdge, with actions: AnyView) -> some View {
        HStack(spacing: 0) {
            Group(subviews: actions) { subviews in
                let currentMeta = subviews.map { $0.containerValues.swipeActionMeta }
                Color.clear.frame(width: 0, height: 0)
                    .onChange(of: currentMeta, initial: true) { _, new in
                        switch edge {
                        case .trailing: trailingMeta = new
                        case .leading:  leadingMeta  = new
                        }
                    }
                
                let stateInfo = makeRenderInfo(for: edge, meta: currentMeta)
                let state = stateInfo.state
                let containerSize = stateInfo.size
                
                AnyLayout(actionsLayout.swipeLayout) {
                    ForEach(subviews) { subview in
                        let itemID = subview.containerValues.swipeActionMeta.id
                        if !state.shouldHide(itemID: itemID) {
                            SwipeActionButton(subview: subview, state: state, actionsLayout:actionsLayout, itemID: itemID) {
                                let info = currentMeta.filter( { $0.id == itemID } ).first
                                if info?.role == .destructive {
                                    playDestructive {
                                        info?.action()
                                    }
                                } else {
                                    info?.action()
                                }
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                    snapClosed()
                                }
                            }
                        }
                    }
                }
                .frame(width: containerSize.width, height: containerSize.height)
            }
        }
    }
}

internal struct SwipeActionButton: View {
    let subview: Subview
    let state: SwipeActionsState
    let actionsLayout: SwipeActionsLayout
    let itemID: UUID
    let onTap: () -> Void
    
    @GestureState private var isPressed = false
    
    var body: some View {
        subview
            .frame(width: actionsLayout.buttonMetrics.width, height: actionsLayout.buttonMetrics.height)
            .frame(maxWidth: state.isHero(itemID: itemID) ? .infinity : actionsLayout.buttonMetrics.width)
            .frame(maxHeight: state.isHero(itemID: itemID) ? .infinity : actionsLayout.buttonMetrics.height)
            .labelStyle(.iconOnly)
            .font(.system(size: 16))
            .foregroundStyle(.white)
            .background(subview.containerValues.swipeActionMeta.color.opacity(isPressed ? 0.7 : 1.0), in: Capsule())
            .scaleEffect(isPressed ? 1.1 : state.scale(itemID: itemID), anchor: .center)
            .opacity(state.opacity(itemID: itemID))
            .transition(.move(edge: .leading).combined(with: .opacity))
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .updating($isPressed) { _, state, _ in state = true }
                    .onEnded { _ in onTap() }
            )
    }
}
