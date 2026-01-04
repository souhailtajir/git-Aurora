//
//  JournalView.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//

import SwiftUI

struct JournalView: View {
  @Environment(TaskStore.self) var taskStore
  @State private var selectedEntry: JournalEntry? = nil
  @State private var searchText = ""
  @State private var showDeletedJournal = false
  @State private var showAllJournals = false
  @State private var showingSettings = false
  @State private var showingNewEntry = false
  @State private var isSearching = false

  var filteredEntries: [JournalEntry] {
    let sorted = taskStore.journalEntries.sorted(by: { $0.date > $1.date })
    if searchText.isEmpty {
      return sorted
    }
    return sorted.filter {
      $0.title.localizedCaseInsensitiveContains(searchText)
        || $0.body.localizedCaseInsensitiveContains(searchText)
    }
  }

  var body: some View {
    NavigationStack {
      Group {
        if taskStore.journalEntries.isEmpty {
          emptyState
        } else {
          List {
            JournalDashboardView(
              entries: taskStore.journalEntries,
              showDeletedJournal: $showDeletedJournal,
              showAllJournals: $showAllJournals
            )
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            Text("Recent Entries")
              .font(.system(size: 18, weight: .bold))
              .foregroundStyle(Theme.primary)
              .listRowInsets(EdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16))
              .listRowBackground(Color.clear)
              .listRowSeparator(.hidden)

            ForEach(filteredEntries) { entry in
              JournalEntryRow(entry: entry)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .onTapGesture { selectedEntry = entry }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                  Button(role: .destructive) {
                    withAnimation { taskStore.deleteJournalEntry(entry) }
                  } label: {
                    Label("", systemImage: "trash.fill")
                  }
                }
            }
          }
          .listStyle(.plain)
          .scrollContentBackground(.hidden)
          .scrollIndicators(.hidden)
        }
      }
      .background(Color.clear.auroraBackground())
      .navigationTitle("Journal")
      .toolbarTitleDisplayMode(.inlineLarge)
      .safeAreaPadding(.top, 8)
      .safeAreaInset(edge: .bottom) {
        if isSearching {
          BottomSearchBar(
            text: $searchText, isSearching: $isSearching, placeholder: "Search journals..."
          )
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
            addNewEntry()
          }
        }

        ToolbarSpacer(.fixed, placement: .topBarTrailing)
        ToolbarItem(placement: .topBarTrailing) {
          Button("Settings", systemImage: "gearshape") {
            showingSettings = true
          }
        }
      }
      .onChange(of: taskStore.addJournalTrigger) { _, newValue in
        if newValue {
          addNewEntry()
          taskStore.addJournalTrigger = false
        }
      }
      .fullScreenCover(item: $selectedEntry) { entry in
        JournalComposerView(
          entry: Binding(
            get: { entry },
            set: { updatedEntry in
              if let index = taskStore.journalEntries.firstIndex(where: { $0.id == entry.id }) {
                taskStore.journalEntries[index] = updatedEntry
                selectedEntry = updatedEntry
              }
            }
          ),
          onDismiss: { selectedEntry = nil }
        )
      }
      .navigationDestination(isPresented: $showDeletedJournal) {
        DeletedJournalView()
      }
      .navigationDestination(isPresented: $showAllJournals) {
        AllJournalsView()
      }
      .sheet(isPresented: $showingSettings) {
        SettingsView()
      }
    }
  }

  private var emptyState: some View {
    VStack(spacing: 16) {
      Spacer()
      Image(systemName: "book.closed.fill")
        .font(.system(size: 48))
        .foregroundStyle(Theme.secondary.opacity(0.4))
      Text("Start your journal")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(Theme.primary)
      Text("Capture your thoughts, ideas, and memories.")
        .font(.system(size: 14))
        .foregroundStyle(Theme.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func addNewEntry() {
    let newEntry = JournalEntry(title: "", body: "", date: Date())
    taskStore.addJournalEntry(newEntry)
    withAnimation { selectedEntry = newEntry }
  }
}
