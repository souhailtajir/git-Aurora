//
//  AllEntriesView.swift
//  Aurora
//

import SwiftUI

struct AllEntriesView: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss
  @State private var searchText = ""
  @State private var selectedEntry: JournalEntry?

  private var entries: [JournalEntry] {
    let sorted = taskStore.journalEntries.sorted { $0.date > $1.date }
    if searchText.isEmpty { return sorted }
    return sorted.filter {
      $0.title.localizedCaseInsensitiveContains(searchText)
        || $0.body.localizedCaseInsensitiveContains(searchText)
    }
  }

  private var grouped: [(String, [JournalEntry])] {
    let dict = Dictionary(grouping: entries) { entry in
      entry.date.formatted(.dateTime.month(.wide).year())
    }
    return dict.sorted { a, b in
      guard
        let d1 = entries.first(where: { $0.date.formatted(.dateTime.month(.wide).year()) == a.key }
        )?.date,
        let d2 = entries.first(where: { $0.date.formatted(.dateTime.month(.wide).year()) == b.key }
        )?.date
      else { return a.key > b.key }
      return d1 > d2
    }
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        // Header
        VStack(alignment: .leading, spacing: 4) {
          Text("All Entries")
            .font(.system(size: 28, weight: .bold))
          Text("\(taskStore.journalEntries.count) entries")
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
        }
        .padding(.top, 16)

        // Search
        HStack(spacing: 10) {
          Image(systemName: "magnifyingglass")
            .foregroundStyle(.secondary)
          TextField("Search", text: $searchText)
            .textFieldStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .glassEffect(.regular)
        .clipShape(Capsule())

        // Empty state or entries
        if entries.isEmpty {
          VStack(spacing: 12) {
            Image(systemName: "book.closed")
              .font(.system(size: 36))
              .foregroundStyle(.secondary.opacity(0.5))
            Text("No entries yet")
              .font(.system(size: 15))
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 60)
        } else {
          // Grouped entries
          ForEach(grouped, id: \.0) { month, monthEntries in
            VStack(alignment: .leading, spacing: 8) {
              Text(month)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.tint)
                .padding(.horizontal, 4)

              ForEach(monthEntries) { entry in
                Button {
                  selectedEntry = entry
                } label: {
                  entryRowContent(entry)
                }
                .buttonStyle(.plain)
              }
            }
          }
        }
      }
      .padding(.horizontal, 16)
    }
    .scrollIndicators(.hidden)
    .background(Color.clear.auroraBackground())
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button {
          dismiss()
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(Theme.tint)
        }
      }
    }
    .navigationDestination(for: JournalEntry.self) { entry in
      EntryEditorView(entryId: entry.id)
    }
    .navigationDestination(item: $selectedEntry) { entry in
      EntryEditorView(entryId: entry.id)
    }
  }

  private func entryRowContent(_ entry: JournalEntry) -> some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(entry.title.isEmpty ? "Untitled" : entry.title)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.primary)
          .lineLimit(1)

        Text(entry.date.formatted(.dateTime.hour().minute()))
          .font(.system(size: 13))
          .foregroundStyle(.secondary)
      }

      Spacer()

      Image(systemName: "chevron.right")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.tertiary)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .glassEffect(.regular)
  }
}
