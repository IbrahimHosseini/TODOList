//
//  ViewModelBox.swift
//  testAI
//
//  Created by Mahsa on 6/12/1404 AP.
//

import SwiftUI
import Combine

// A container to allow late-binding a @StateObject view model after modelContext becomes available.
final class ViewModelBox: ObservableObject {
    @Published var viewModel: ToDoListViewModel?
}
