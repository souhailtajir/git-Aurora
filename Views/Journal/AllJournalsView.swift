//
//  AllJournalsView.swift
//  Aurora
//
//  Created by souhail on 12/25/25.
//

import SwiftUI

struct AllJournalsView: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss
  @FocusState private var searchFocused: Bool
  @State private var searchText = ""
  @State private var showSearch = false
  @State private var navigationPath = NavigationPath()

  private var sortedEntries: [JournalEntry] {
    let sorted = taskStore.journalEntries.sorted(by: { $0.date > $1.date })
    if searchText.isEmpty {
      return sorted
    }
    return sorted.filter {
      $0.title.localizedCaseInsensitiveContains(searchText)
        || $0.body.localizedCaseInsensitiveContains(searchText)
    }
  }

  // Group entries by month/year
  private var groupedEntries: [(key: String, entries: [JournalEntry])] {
    let grouped = Dictionary(grouping: sortedEntries) { entry -> String in
      entry.date.formatted(.dateTime.month(.wide).year())
    }
    return grouped.sorted { first, second in
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "MMMM yyyy"
      guard let date1 = dateFormatter.date(from: first.key),
        let date2 = dateFormatter.date(from: second.key)
      else {
        return first.key > second.key
      }
      return date1 > date2
    }.map { (key: $0.key, entries: $0.value) }
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(spacing: 16) {
        if taskStore.journalEntries.isEmpty {
          emptyState
        } else {
          // Header info
          VStack(alignment: .leading, spacing: 4) {
            Text("\(taskStore.journalEntries.count) entries")
              .font(.system(size: 14))
              .foregroundStyle(Theme.secondary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 4)

          // Search field
          searchField

          // Grouped entries by month
          if sortedEntries.isEmpty && !searchText.isEmpty {
            ContentUnavailableView.search(text: searchText)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else {
            ForEach(groupedEntries, id: \.key) { group in
              VStack(alignment: .leading, spacing: 8) {
                // Month header
                Text(group.key)
                  .font(.system(size: 14, weight: .semibold))
                  .foregroundStyle(Theme.tint)
                  .padding(.horizontal, 4)
                  .padding(.top, 8)

                // Entries
                ForEach(group.entries) { entry in
                  Button {
                    navigationPath.append(entry)
                  } label: {
                    JournalEntryRow(entry: entry)
                  }
                  .buttonStyle(.plain)
                  .contextMenu {
                    Button(role: .destructive) {
                      withAnimation { taskStore.deleteJournalEntry(entry) }
                    } label: {
                      Label("Delete", systemImage: "trash")
                    }
                  }
                }
              }
            }
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 100)
    }
    .background(Color.clear.auroraBackground())
    .navigationTitle("All Journals")
    .toolbarTitleDisplayMode(.inlineLarge)
    .safeAreaPadding(.top, 8)
    .safeAreaInset(edge: .bottom) {
      if showSearch {
        BottomSearchBar(
          searchText: $searchText,
          showSearch: $showSearch,
          placeholder: "Search journals...",
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
    }
    .navigationDestination(for: JournalEntry.self) { entry in
      JournalEntryView(entry: entry)
    }
  }

  // MARK: - Search Field

  private var searchField: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 16))
        .foregroundStyle(.secondary)

      TextField("Search entries...", text: $searchText)
        .textFieldStyle(.plain)
        .foregroundStyle(Theme.primary)
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 10)
    .glassEffect(.regular)
  }

  // MARK: - Empty State

  private var emptyState: some View {
    VStack(spacing: 16) {
      Spacer()
        .frame(height: 100)

      Image(systemName: "book.closed")
        .font(.system(size: 48))
        .foregroundStyle(Theme.secondary.opacity(0.4))

      Text("No Journal Entries")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(Theme.primary)

      Text("Start journaling to see your entries here.")
        .font(.system(size: 14))
        .foregroundStyle(Theme.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)

      Spacer()
    }
    .frame(maxWidth: .infinity)
  }
}
