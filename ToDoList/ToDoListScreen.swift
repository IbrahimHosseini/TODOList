//
//  ToDoListScreen.swift
//  testAI
//
//  Created by Mahsa on 6/12/1404 AP.
//

import SwiftUI
import SwiftData

struct ToDoListScreen: View {
    @ObservedObject var vm: ToDoListViewModel
    @Binding var newTitle: String

    // State for presenting detail when the info icon is tapped
    @State private var selectedItem: ToDoItem?

    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 0) {
                    List {
                        ForEach(vm.items) { item in
                            HStack {
                                // Completion toggle
                                Button {
                                    vm.toggleCompletion(for: item)
                                } label: {
                                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(item.isCompleted ? .green : .secondary)
                                        .imageScale(.large)
                                        .accessibilityLabel(item.isCompleted ? "Mark as not completed" : "Mark as completed")
                                }
                                .buttonStyle(.plain)

                                // Title + note + due date
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        // Small priority icon before the title
                                        smallPriorityIcon(for: item.priority)
                                            .accessibilityLabel(badge(for: item.priority))
                                        
                                        Text(item.title)
                                            .font(.system(size: 14, weight: .medium))
                                            .strikethrough(item.isCompleted, pattern: .solid, color: .secondary)
                                            .foregroundStyle(item.isCompleted ? .secondary : .primary)
                                            .lineLimit(2)

                                    }

                                    if !item.note.isEmpty {
                                        Text(item.note)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                    }

                                    if let due = item.dueDate {
                                        HStack(spacing: 6) {
                                            Image(systemName: "calendar")
                                                .imageScale(.small)
                                            Text(due, style: .date)
                                            Text(due, style: .time)
                                        }
                                        .font(.caption)
                                        .foregroundStyle(dueColor(for: due, completed: item.isCompleted))
                                        .accessibilityLabel(dueAccessibility(for: due))
                                    }
                                }

                                Spacer()

                                // Info button shows details
                                Button {
                                    selectedItem = item
                                } label: {
                                    Image(systemName: "info.circle")
                                        .imageScale(.medium)
                                        .foregroundStyle(.secondary)
                                        .accessibilityLabel("Show details")
                                }
                                .buttonStyle(.plain)
                                // Attach popover to this button so it feels anchored to the tapped control
                                .popover(isPresented: Binding(
                                    get: { selectedItem?.id == item.id },
                                    set: { newValue in
                                        if !newValue { selectedItem = nil }
                                    }
                                ),
                                attachmentAnchor: .rect(.bounds),
                                arrowEdge: .top) {
                                    if let selected = selectedItem {
                                        ToDoDetailView(vm: vm, item: selected)
                                            .presentationDetents([.medium, .large])
                                            .presentationDragIndicator(.visible)
                                    }
                                }
                            }
                            // Put delete on trailing side for standard swipe-to-delete UX
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    vm.delete(item)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            // Keep completion on leading side
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button {
                                    vm.toggleCompletion(for: item)
                                } label: {
                                    Label(item.isCompleted ? "Uncomplete" : "Complete",
                                          systemImage: item.isCompleted ? "arrow.uturn.left.circle" : "checkmark.circle")
                                }
                                .tint(item.isCompleted ? .orange : .green)
                            }
                        }
                        .onDelete(perform: vm.delete(at:))
                        .onMove(perform: vm.moveItems(from:to:))
                    }
                    .listStyle(.inset)

                    Divider()

                    HStack {
                        TextField("New task", text: $newTitle)
                            .textFieldStyle(.roundedBorder)
                            .submitLabel(.done)
                            .onSubmit { addNewItem() }

                        Button {
                            addNewItem()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .imageScale(.large)
                        }
                        .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding()
                    .background(.thinMaterial)
                }

                if vm.isLoading {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView("Loading…")
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.primary)
                                    .shadow(radius: 8)
                            )
                    }
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: vm.isLoading)
                }
            }
            .navigationTitle("To‑Do")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button {
                        withAnimation {
                            vm.clearCompleted()
                        }
                    } label: {
                        Label("Clear Completed", systemImage: "line.3.horizontal.decrease.circle")
                    }
                    .disabled(!vm.hasCompletedItems)
                }
            }
        }
        .alert(
            item: Binding<ErrorPresentation?>(
                get: { vm.errorPresentation },
                set: { vm.errorPresentation = $0 }
            )
        ) { presentation in
            Alert(
                title: Text(presentation.title),
                message: presentation.message.map(Text.init),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func addNewItem() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        withAnimation {
            // Set due date to current time
            vm.add(title: trimmed, dueDate: Date())
        }
        newTitle = ""
    }

    private func badge(for p: ToDoPriority) -> String {
        switch p {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    private func capsuleColor(for p: ToDoPriority) -> Color {
        switch p {
        case .low: return .blue
        case .medium: return .orange
        case .high: return .red
        }
    }

    private func dueColor(for date: Date, completed: Bool) -> Color {
        if completed { return .secondary }
        let now = Date()
        if date < Calendar.current.startOfDay(for: now) {
            return .red // overdue
        }
        if Calendar.current.isDateInToday(date) {
            return .orange // due today
        }
        return .secondary
    }

    private func dueAccessibility(for date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return "Due \(df.string(from: date))"
    }

    // Match the detail view’s icon style
    @ViewBuilder
    private func priorityIcon(for p: ToDoPriority) -> some View {
        let (bg, symbol): (Color, String) = {
            switch p {
            case .low:
                return (.green, "exclamationmark")
            case .medium:
                return (.orange, "exclamationmark.2")
            case .high:
                return (.red, "exclamationmark.3")
            }
        }()

        ZStack {
            Circle()
                .fill(bg)
                .frame(width: 22, height: 22)
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }

    // Smaller variant for list rows
    @ViewBuilder
    private func smallPriorityIcon(for p: ToDoPriority) -> some View {
        let (bg, symbol): (Color, String) = {
            switch p {
            case .low:
                return (.green, "exclamationmark")
            case .medium:
                return (.orange, "exclamationmark.2")
            case .high:
                return (.red, "exclamationmark.3")
            }
        }()

        ZStack {
            Circle()
                .fill(bg)
                .frame(width: 12, height: 12)
            Image(systemName: symbol)
                .font(.system(size: 6, weight: .medium))
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }
}

#Preview("To‑Do List") {
    @Previewable @State var newTitle: String = ""
    // Mock data for preview
    // Build a temporary in-memory SwiftData container for previews
    let schema = Schema([ToDoEntity.self])
    let inMemory = ModelConfiguration(
        "Preview",
        schema: schema,
        isStoredInMemoryOnly: true,
        allowsSave: true
    )
    let container = try! ModelContainer(for: schema, configurations: [inMemory])
    let context = ModelContext(container)
    
    let vm = ToDoListViewModel(context: context)
    let sample = ToDoItem(id: UUID(), title: "Buy groceries", isCompleted: false, note: "Milk, eggs, bread", priority: .medium, dueDate: Calendar.current.date(byAdding: .hour, value: 2, to: Date()))
    
    ToDoListScreen(vm: vm, newTitle: $newTitle)
}
