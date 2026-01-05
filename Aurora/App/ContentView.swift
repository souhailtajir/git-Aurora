//
//  ContentView.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//

import SwiftUI

struct ContentView: View {
  @Environment(TaskStore.self) var taskStore
  @State private var selectedTab: Int = 0
  @State private var showingAddTask = false

  var body: some View {
    ZStack(alignment: .top) {
      TabView(selection: $selectedTab) {
        Tab("Home", systemImage: "house.fill", value: 0) {
          HomeView()
        }

        Tab("Tasks", systemImage: "list.bullet", value: 1) {
          TasksView()
        }

        Tab("Journal", systemImage: "book.fill", value: 2) {
          JournalView()
        }

        Tab("Calendar", systemImage: "calendar", value: 3) {
          CalendarView()
        }

        // Dynamic Action Tab
        Tab(value: 4, role: .search) {
          EmptyView()
        } label: {
          if selectedTab == 2 {
            Label("Entry", systemImage: "square.and.pencil")
          } else {
            Label("Add", systemImage: "plus")
          }
        }
      }
      .tabViewStyle(.sidebarAdaptable)
      .tint(Theme.primary)

      // Global Status Bar Vignette (iOS 26 Look)
      LinearGradient(
        colors: [.black.opacity(0.6), .clear],
        startPoint: .top,
        endPoint: .bottom
      )
      .frame(height: 140)
      .ignoresSafeArea()
      .allowsHitTesting(false)
    }
    .onChange(of: selectedTab) { oldValue, newValue in
      if newValue == 4 {
        // Revert to previous tab
        withAnimation(.smooth(duration: 0.2)) {
          selectedTab = oldValue
        }

        // Trigger appropriate action
        if oldValue == 2 {
          // Trigger journal add via TaskStore (handled in JournalView)
          taskStore.addJournalTrigger = true
        } else {
          showingAddTask = true
        }
      }
    }
    .sheet(isPresented: $showingAddTask) {
      TaskSheet()
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
  }
}

// MARK: - Category Picker View

struct CategoryPickerView: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss
  @Binding var selectedCategory: TaskCategory

  var body: some View {
    List {
      ForEach(taskStore.categories) { category in
        Button {
          selectedCategory = category
          dismiss()
        } label: {
          HStack {
            ZStack {
              RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: category.colorHex))
                .frame(width: 28, height: 28)

              Image(systemName: category.iconName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
            }

            Text(category.name)
              .foregroundStyle(.primary)

            Spacer()

            if category.id == selectedCategory.id {
              Image(systemName: "checkmark")
                .foregroundStyle(Theme.primary)
            }
          }
        }
      }
    }
    .navigationTitle("List")
    .navigationBarTitleDisplayMode(.inline)
  }
}
