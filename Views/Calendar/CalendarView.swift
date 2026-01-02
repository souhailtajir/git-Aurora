//
//  CalendarView.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//

import SwiftUI

struct CalendarView: View {

  @Environment(TaskStore.self) var taskStore
  @Environment(UserProfileStore.self) var userProfileStore
  @State private var editingTaskId: UUID? = nil
  @State private var selectedTaskForDetails: Task? = nil
  @FocusState private var focusedTaskId: UUID?
  @FocusState private var searchFocused: Bool
  @State private var searchText = ""
  @State private var agendaExpanded = true
  @State private var showSearch = false
  @Namespace private var namespace
  @State private var showingSettings = false
  @State private var showingNewTask = false

  var body: some View {
    NavigationStack {
      ZStack {
        Color.clear.auroraBackground()

        ScrollView {
          VStack(spacing: 20) {
            Text("Calendar view coming soon")
              .font(.system(size: 15))
              .foregroundStyle(.secondary)
              .padding()
          }
          .padding(.bottom, 100)
        }
      }
      .navigationTitle("Calendar")
      .toolbarTitleDisplayMode(.inlineLarge)
      .safeAreaPadding(.top, 8)
      .safeAreaInset(edge: .bottom) {
        if showSearch {
          BottomSearchBar(
            searchText: $searchText,
            showSearch: $showSearch,
            placeholder: "Search...",
            focusState: $searchFocused
          )
          .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
      .animation(.easeInOut(duration: 0.25), value: showSearch)
      .toolbar {
        ToolbarItemGroup(placement: .topBarTrailing) {
          Button("Search", systemImage: "magnifyingglass") {
            withAnimation(.easeInOut) {
              showSearch = true
              searchFocused = true
            }
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button("Add", systemImage: "plus") {
            showingNewTask = true
          }
        }
        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        ToolbarItem(placement: .topBarTrailing) {
          Button("Settings", systemImage: "gearshape") {
            showingSettings = true
          }
        }
      }
    }
  }
}
