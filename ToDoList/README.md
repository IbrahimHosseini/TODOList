# testAI — To‑Do List (SwiftUI + SwiftData)

A modern To‑Do app built with SwiftUI, Swift Concurrency, and SwiftData. It demonstrates MVVM architecture, local persistence, and a clean, accessible UI with swipe actions, popovers, and alerts.

## Features

- SwiftUI interface with NavigationStack and List
- Add new tasks with quick entry (title + default due date set to “now”)
- Mark tasks complete/incomplete (button and swipe actions)
- Priority levels (low/medium/high) with clear iconography
- Edit task details in a popover sheet:
  - Title
  - Note
  - Priority (segmented control with icons)
  - Due date & time (always visible)
  - Completion toggle
- Swipe to delete, drag to reorder (local visual feedback)
- Clear all completed tasks
- Loading overlay while syncing
- Error alerts with user‑friendly messages
- Accessibility labels for key controls and date announcements

## Tech Stack

- Swift 5.9+
- SwiftUI
- Swift Concurrency (async/await)
- SwiftData (ModelContainer / ModelContext)
- MVVM
- OSLog for logging

## Architecture

- UI Layer (SwiftUI):
  - ContentView (entry point; hosts ToDoListScreen)
  - ToDoListScreen: Main list UI, quick add, toolbar, popover presentation
  - ToDoDetailView: Edit sheet for item details

- ViewModel:
  - ToDoListViewModel (ObservableObject, @MainActor)
    - @Published items, isLoading, errorPresentation
    - Methods: load, add, update, toggleCompletion, delete, delete(at:), moveItems(from:to:), clearCompleted
    - Sorts items by completion → priority → createdAt → title → id
    - Maps errors to ErrorPresentation for alerts
    - Uses a service (SyncingToDoService) composed of local and remote repositories

- Models:
  - ToDoItem: Identifiable struct (id, title, isCompleted, createdAt, note, priority, dueDate)
  - ToDoPriority: enum (low, medium, high)
  - ErrorPresentation: Identifiable wrapper for alert presentation
  - ToDoEntity: SwiftData @Model (not shown here) that persists ToDoItem locally

- Persistence & Services:
  - testAIApp configures a SwiftData ModelContainer with a schema including ToDoEntity
  - ToDoListViewModel is initialized with a ModelContext and creates:
    - SwiftDataToDoRepository (local)
    - RemoteToDoRepository (stub/placeholder baseURL)
    - SyncingToDoService (orchestrates local/remote operations)
  - Note: Repository/service implementations are referenced but not shown in this snippet

## UI/UX Details

- List rows:
  - Leading toggle button for completion
  - Title with strikethrough when completed
  - Optional note (single line)
  - Optional due date with calendar icon; color emphasizes overdue/today
  - Small priority dot icon before title
  - Trailing info button opens popover with details
- Swipe actions:
  - Leading: Complete/Uncomplete (green/orange)
  - Trailing: Delete (destructive)
- Toolbar:
  - “Clear Completed” button (disabled when none)
- Loading:
  - Dimmed overlay with ProgressView
- Alerts:
  - Presented via ErrorPresentation

## Accessibility

- Completion button: Accessibility labels “Mark as completed” / “Mark as not completed”
- Priority icons: Decorative in rows; labeled in segmented control
- Due date: VoiceOver friendly “Due <date and time>”

## Getting Started

### Requirements
- Xcode 15 or later
- iOS 17 or later (SwiftData)
- Swift 5.9+

### Build & Run
1. Open the project in Xcode.
2. Select an iOS 17+ simulator or device.
3. Run (Cmd+R).

The app creates a SwiftData ModelContainer in testAIApp and injects it via .modelContainer into the environment. ContentView should create a ToDoListViewModel with the ModelContext and pass it into ToDoListScreen.

Example (conceptual):
```swift
struct ContentView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var vm: ToDoListViewModel
    @State private var newTitle = ""

    init(context: ModelContext) {
        _vm = StateObject(wrappedValue: ToDoListViewModel(context: context))
    }

    var body: some View {
        ToDoListScreen(vm: vm, newTitle: $newTitle)
            .task { await vm.load() }
    }
}
