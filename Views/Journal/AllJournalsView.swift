//
//  AllJournalsView.swift
//  Aurora
//
//  Created by antigravity on 12/25/25.
//

import SwiftUI

struct AllJournalsView: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss
  @State private var selectedEntry: JournalEntry? = nil
  @State private var searchText = ""

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
    ZStack(alignment: .top) {
      Color.clear.auroraBackground()

      if taskStore.journalEntries.isEmpty {
        emptyState
      } else {
        List {
          // Spacer for header
          Color.clear
            .frame(height: 60)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

          // Title section
          VStack(alignment: .leading, spacing: 8) {
            Text("All Journals")
              .font(.system(size: 32, weight: .bold))
              .foregroundStyle(Theme.primary)

            Text("\(taskStore.journalEntries.count) entries")
              .font(.system(size: 14))
              .foregroundStyle(Theme.secondary)
          }
          .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)

          // Search field
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
          .clipShape(Capsule())
          .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)

          // Grouped entries by month
          ForEach(groupedEntries, id: \.key) { group in
            Section {
              ForEach(group.entries) { entry in
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
            } header: {
              Text(group.key)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.tint)
                .textCase(nil)
            }
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
          }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
      }

      // Header
      headerView
    }
    .navigationBarBackButtonHidden(true)
    .fullScreenCover(item: $selectedEntry, onDismiss: { selectedEntry = nil }) { entry in
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
  }

  // MARK: - Header
  private var headerView: some View {
    HStack {
      // Back button - fixed hit area
      Button {
        dismiss()
      } label: {
        Image(systemName: "chevron.left")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(Theme.secondary)
          .frame(width: 40, height: 40)
          .background(
            Circle()
              .fill(.clear)
              .glassEffect(.clear)
          )
      }
      .contentShape(Circle())

      Spacer()
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
  }

  // MARK: - Empty State
  private var emptyState: some View {
    VStack(spacing: 16) {
      Spacer()

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
  }
}
