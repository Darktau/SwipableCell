# SwipableCell

![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)
![iOS](https://img.shields.io/badge/iOS-18.0+-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen)

A SwiftUI swipe-actions component for `ScrollView`, with physics-based gestures, multi-button reveal animations, full-swipe triggers, and a one-open-at-a-time coordinator — all via a familiar `.makeSwipeActions()` modifier API.

> Requires **iOS 18+ / macOS 15+** (uses `@Observable`, `Group(subviews:)`, `ContainerValues`).

---

## Features

- **Leading & trailing actions** — attach actions to either side independently
- **Horizontal or vertical button layout** — stack buttons side-by-side or stacked
- **Animated reveal** — buttons pop in sequentially with scale + opacity transitions
- **Full-swipe trigger** — optional swipe-to-confirm with a hero button animation
- **Destructive full-swipe** — collapses row height to zero before firing the action
- **Coordinator** — `SwipeCoordinator` ensures only one row is open at a time; closes on tap/drag outside
- **Rubber-band overscroll** — natural resistance when dragging past the action tray
- **Composable** — chain `.makeSwipeActions()` twice for both edges

---

## Installation

### Swift Package Manager

In Xcode: **File → Add Package Dependencies**, paste the repository URL.

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Darktau/SwipeActions.git", from: "1.0.0")
]
```

Then add `"SwipableCell"` to your target's dependencies.

---

## Quick Start

### 1. Wrap your list in `.makeSwipable()`

Place `.makeSwipable()` on the `ScrollView` (or any ancestor). This injects the `SwipeCoordinator` that keeps only one cell open at a time and closes open cells on outside taps or vertical drags.

```swift
ScrollView {
    LazyVStack(spacing: 0) {
        ForEach(items) { item in
            rowView(item)
        }
    }
}
.makeSwipable()
```

### 2. Attach actions to a row

```swift
Text("Hello, world!")
    .makeSwipeActions(edge: .trailing) {
        SwipeButton(color: .red, role: .destructive) {
            delete(item)
        } label: {
            Label("Delete", systemImage: "trash")
        }

        SwipeButton(color: .blue) {
            archive(item)
        } label: {
            Label("Archive", systemImage: "archivebox")
        }
    }
```

### 3. Add actions on both edges

Chain the modifier a second time for the opposite edge:

```swift
Text("Hello, world!")
    .makeSwipeActions(edge: .trailing, allowsFullSwipe: true) {
        SwipeButton(color: .red, role: .destructive) { delete(item) } label: {
            Label("Delete", systemImage: "trash")
        }
    }
    .makeSwipeActions(edge: .leading) {
        SwipeButton(color: .green) { flag(item) } label: {
            Label("Flag", systemImage: "flag")
        }
    }
```

---

## API Reference

### `View.makeSwipeActions(edge:allowsFullSwipe:actions:)`

```swift
func makeSwipeActions<T: View>(
    edge: HorizontalEdge = .trailing,
    allowsFullSwipe: Bool = false,
    @ViewBuilder actions: () -> T
) -> SwipeableCell<Self>
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `edge` | `.trailing` | Which edge reveals the actions |
| `allowsFullSwipe` | `false` | Enables full-swipe trigger on the outermost button |

### `SwipeButton`

```swift
SwipeButton(
    color: Color = .gray,
    role: ButtonRole? = nil,   // pass .destructive for collapse animation
    action: @escaping () -> Void,
    @ViewBuilder label: () -> Label
)
```

Buttons are ordered left-to-right (trailing) / top-to-bottom (vertical) as written. The **last** button in a trailing tray (or **first** in a leading tray) becomes the full-swipe hero when `allowsFullSwipe: true`.

### `View.makeSwipable()`

Attach to the scroll container. Creates a `SwipeCoordinator` via `@State`, so it survives re-renders. Adds simultaneous drag gesture that close any open cell.

### `SwipeCoordinator`

`@Observable` class that tracks `openedID: UUID?`. You can inject your own instance via `.environment(\.swipeCoordinator, myCoordinator)` if you need to control it externally (e.g. close all cells programmatically).

---

## Customising Button Metrics

`SwipeActionsLayout` controls button size, spacing, and container padding. The `.base` preset uses `58 × 44 pt` buttons with `8 pt` spacing.

```swift
// Default — no configuration needed
Text("Hello")
    .makeSwipeActions(edge: .trailing) { ... }

// Custom layout — applies to both edges at once
Text("Hello")
    .makeSwipeActions(edge: .trailing) { ... }
    .makeSwipeActions(edge: .leading) { ... }
    .swipeActionsLayout(SwipeActionsLayout(
        orientation: .vertical,
        buttonMetrics: SwipeButtonMetrics(width: 70, height: 50),
        spacing: 6,
        containerPadding: 6
    ))
```

By default, `makeSwipeActions` uses a horizontal button layout. To switch to vertical or fine-tune button size and spacing, use `.swipeActionsLayout()`.

---

## Cell Action

Use `.cellAction` to handle taps on the cell itself — for example, navigating to a detail screen.

```swift
Text("Hello")
    .makeSwipeActions(edge: .trailing) { ... }
    .cellAction {
        navigate(to: item)
    }
```

## Modifier Order

`.makeSwipeActions`, `.cellAction`, and `.swipeActionsLayout` can be applied in any order:

```swift
// all of these are equivalent
Text("Hello")
    .cellAction { navigate() }
    .makeSwipeActions(edge: .trailing) { ... }
    .swipeActionsLayout(...)

Text("Hello")
    .makeSwipeActions(edge: .trailing) { ... }
    .swipeActionsLayout(...)
    .cellAction { navigate() }

Text("Hello")
    .swipeActionsLayout(...)
    .cellAction { navigate() }
    .makeSwipeActions(edge: .trailing) { ... }
```

## Full Example

```swift
import SwiftUI
import SwipableCell

struct ContentView: View {
    @State private var items = Array(1...20).map { "Item \($0)" }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(items, id: \.self) { item in
                    HStack {
                        Text(item)
                            .padding()
                        Spacer()
                    }
                    .makeSwipeActions(edge: .trailing, allowsFullSwipe: true) {
                        SwipeButton(color: .red, role: .destructive) {
                            items.removeAll { $0 == item }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }

                        SwipeButton(color: .orange) {
                            print("Flagged \(item)")
                        } label: {
                            Label("Flag", systemImage: "flag")
                        }
                    }
                    .makeSwipeActions(edge: .leading) {
                        SwipeButton(color: .blue) {
                            print("Pinned \(item)")
                        } label: {
                            Label("Pin", systemImage: "pin")
                        }
                    }

                    Divider()
                }
            }
        }
        .makeSwipable()
    }
}
```

---

## How It Works

```
ScrollView (.makeSwipable)
 └─ SwipeCoordinator (environment)
     └─ SwipeableCell
         ├─ ZStack
         │   ├─ Trailing action tray   ← actionsContainer(.trailing)
         │   ├─ Leading action tray    ← actionsContainer(.leading)
         │   └─ Content row           ← .offset(x: offset)
         └─ UIPanGestureRecognizer
             ├─ rubberBand()          ← resistance past tray width
             ├─ snapToPosition()      ← spring to open / closed
             └─ triggerFullSwipe()    ← slide out + optional collapse
```

`SwipeActionsPhase` drives the reveal state machine:

```
.closed → .revealing → .preparingToFull → .fullSwipe
```

`SwipeActionsState` derives per-button `scale`, `opacity`, and `shouldHide` from the current phase and button index, producing the staggered pop-in and hero-button effects.

---

## Requirements

| | Minimum |
|---|---|
| iOS | 18.0 |
| macOS | 15.0 |
| Swift | 6.0 |
| Xcode | 16.0 |

---

## License

MIT — see [LICENSE](LICENSE) for details.
