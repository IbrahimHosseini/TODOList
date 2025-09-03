//
//  ContentView.swift
//  testAI
//
//  Created by Mahsa on 6/12/1404 AP.
//

import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    // Hold the actual view model as a StateObject so SwiftUI observes its @Published changes.
    @StateObject private var viewModelBox = ViewModelBox()
    @State private var newTitle: String = ""

    var body: some View {
        Group {
            if let vm = viewModelBox.viewModel {
                ToDoListScreen(vm: vm, newTitle: $newTitle)
            } else {
                ProgressView("Loading…")
            }
        }
        .task {
            // Initialize VM once when modelContext is available.
            if viewModelBox.viewModel == nil {
                let vm = ToDoListViewModel(context: modelContext)
                viewModelBox.viewModel = vm
                await vm.load()
            }
        }
    }
}

