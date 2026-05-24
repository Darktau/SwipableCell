//
//  PanGestureView.swift
//  SwipableCell
//
//  Created by Sergey Tristan on 23.05.2026.
//

import SwiftUI


internal struct PanGestureView: UIViewRepresentable {
    let onChanged: (UIPanGestureRecognizer) -> Void
    let onEnded: (UIPanGestureRecognizer) -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        pan.delegate = context.coordinator
        view.addGestureRecognizer(pan)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onChanged: onChanged, onEnded: onEnded)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        let onChanged: (UIPanGestureRecognizer) -> Void
        let onEnded: (UIPanGestureRecognizer) -> Void

        init(onChanged: @escaping (UIPanGestureRecognizer) -> Void,
             onEnded: @escaping (UIPanGestureRecognizer) -> Void) {
            self.onChanged = onChanged
            self.onEnded = onEnded
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            switch gesture.state {
            case .began, .changed:
                onChanged(gesture)
            case .ended, .cancelled:
                onEnded(gesture)
            default: break
            }
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}
