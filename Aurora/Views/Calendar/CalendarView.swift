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
  @State private var searchText = ""
  @State private var agendaExpanded = true
  @State private var isSearching = false
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
        if isSearching {
          BottomSearchBar(text: $searchText, isSearching: $isSearching)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
      .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSearching)
      .toolbar {
        ToolbarItemGroup(placement: .topBarTrailing) {
          Button("Search", systemImage: "magnifyingglass") {
            withAnimation {
              isSearching = true
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
