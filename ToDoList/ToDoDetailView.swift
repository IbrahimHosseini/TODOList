//
//  ToDoDetailView.swift
//  testAI
//
//  Created by Mahsa on 6/12/1404 AP.
//

import SwiftUI
import SwiftData

struct ToDoDetailView: View {
    @ObservedObject var vm: ToDoListViewModel
    let item: ToDoItem

    @State private var title: String
    @State private var note: String
    @State private var priority: ToDoPriority
    @State private var isCompleted: Bool

    // Due date editing state (always shown)
    @State private var dueDate: Date

    @Environment(\.dismiss) private var dismiss

    init(vm: ToDoListViewModel, item: ToDoItem) {
        self.vm = vm
        self.item = item
        _title = State(initialValue: item.title)
        _note = State(initialValue: item.note)
        _priority = State(initialValue: item.priority)
        _isCompleted = State(initialValue: item.isCompleted)
        // If missing, default to today at 9:00
        let defaultDue = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        _dueDate = State(initialValue: item.dueDate ?? defaultDue)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
           
            HStack(spacing: 16) {
                HStack {
                    TextField("Title", text: $title)
                        .onSubmit(saveChanges)
                }

                // Icon-only segmented control for priority
                Picker("", selection: $priority) {
                    ForEach(ToDoPriority.allCases, id: \.self) { p in
                        priorityIcon(for: p)
                            .tag(p)
                            .accessibilityLabel(label(for: p))
                    }
                }
                .pickerStyle(.segmented)
                .help("Priority") // Optional tooltip on macOS

            }

            // Always show date & time picker
            DatePicker(
                "Due Date",
                selection: $dueDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            
            Toggle("Completed", isOn: $isCompleted)
                .onChange(of: isCompleted) { _, newValue in
                    var updated = item
                    updated = ToDoItem(
                        id: updated.id,
                        title: updated.title,
                        isCompleted: newValue,
                        createdAt: updated.createdAt,
                        note: updated.note,
                        priority: updated.priority,
                        dueDate: dueDate
                    )
                    vm.update(item: updated)
                }

            Section("Note") {
                TextEditor(text: $note)
                    .frame(minHeight: 55)
            }

        }
        .padding(.all, 32)
        .navigationTitle("Details")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { saveChanges() }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func saveChanges() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var updated = item
        // Rebuild ToDoItem with new values (struct is immutable externally)
        updated = ToDoItem(
            id: updated.id,
            title: trimmed,
            isCompleted: isCompleted,
            createdAt: updated.createdAt,
            note: note,
            priority: priority,
            dueDate: dueDate
        )

        vm.update(item: updated)
        dismiss()
    }

    private func label(for p: ToDoPriority) -> String {
        switch p {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    // Icon resembling the provided image: 1/2/3 exclamation marks in colored circles.
    // Colors updated to match priority:
    // - low: blue
    // - medium: orange
    // - high: red
    // Increased frames to make the segmented control taller/bigger.
    private func priorityIcon(for p: ToDoPriority) -> some View {
        let (bg, symbol): (Color, String) = {
            switch p {
            case .low:
                return (.blue, "exclamationmark")
            case .medium:
                return (.orange, "exclamationmark.2")
            case .high:
                return (.red, "exclamationmark.3")
            }
        }()

        return ZStack {
            Circle()
                .fill(bg)
                .frame(width: 34, height: 34)
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: 40, height: 40)
        .accessibilityHidden(true)
    }
}

#if DEBUG
#Preview {
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
    let sample = ToDoItem(title: "title")

    return NavigationStack {
        ToDoDetailView(vm: vm, item: sample)
    }
    .modelContainer(container)
}
#endif
