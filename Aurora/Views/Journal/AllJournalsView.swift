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
  @State private var searchText = ""
  @State private var navigationPath = NavigationPath()

  private let purpleAccent = Color(red: 0.6, green: 0.4, blue: 0.9)

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
    NavigationStack(path: $navigationPath) {
      ScrollView {
        VStack(spacing: 16) {
          // Header
          VStack(alignment: .leading, spacing: 4) {
            Text("All Journals")
              .font(.system(size: 32, weight: .bold))
              .foregroundStyle(.primary)

            Text("\(taskStore.journalEntries.count) entries")
              .font(.system(size: 14))
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.top, 60)

          // Search
          HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 16))
              .foregroundStyle(.secondary)

            TextField("Search entries...", text: $searchText)
              .textFieldStyle(.plain)
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 12)
          .glassEffect(.regular)
          .clipShape(Capsule())

          if taskStore.journalEntries.isEmpty {
            emptyState
          } else {
            // Grouped entries
            ForEach(groupedEntries, id: \.key) { group in
              VStack(alignment: .leading, spacing: 10) {
                Text(group.key)
                  .font(.system(size: 14, weight: .semibold))
                  .foregroundStyle(purpleAccent)
                  .padding(.horizontal, 4)
                  .padding(.top, 8)

                VStack(spacing: 8) {
                  ForEach(group.entries) { entry in
                    journalRow(for: entry)
                  }
                }
              }
            }
          }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 100)
      }
      .scrollIndicators(.hidden)
      .background(Color.clear.auroraBackground())
      .navigationBarBackButtonHidden(true)
      .toolbar(.hidden, for: .tabBar)
      .overlay(alignment: .topLeading) {
        backButton
      }
      .navigationDestination(for: JournalEntry.self) { entry in
        JournalEntryView(
          entry: Binding(
            get: { taskStore.journalEntries.first { $0.id == entry.id } ?? entry },
            set: { updatedEntry in
              if let index = taskStore.journalEntries.firstIndex(where: { $0.id == entry.id }) {
                taskStore.journalEntries[index] = updatedEntry
              }
            }
          )
        )
      }
    }
  }

  // MARK: - Back Button

  private var backButton: some View {
    Button {
      dismiss()
    } label: {
      Image(systemName: "chevron.left")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.secondary)
        .frame(width: 40, height: 40)
        .glassEffect(.regular)
        .clipShape(Circle())
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
  }

  // MARK: - Journal Row

  private func journalRow(for entry: JournalEntry) -> some View {
    Button {
      navigationPath.append(entry)
    } label: {
      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 2)
          .fill(purpleAccent)
          .frame(width: 4, height: 36)

        VStack(alignment: .leading, spacing: 4) {
          Text(entry.title.isEmpty ? "Untitled" : entry.title)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.primary)
            .lineLimit(1)

          HStack(spacing: 8) {
            Text(entry.date.formatted(.dateTime.hour().minute()))
              .font(.system(size: 13))
              .foregroundStyle(.secondary)

            if !entry.body.isEmpty {
              Text("•")
                .foregroundStyle(.tertiary)

              Text(entry.body.prefix(30) + (entry.body.count > 30 ? "..." : ""))
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
                .lineLimit(1)
            }
          }
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.tertiary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .glassEffect(.regular)
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

  // MARK: - Empty State

  private var emptyState: some View {
    VStack(spacing: 16) {
      Image(systemName: "book.closed")
        .font(.system(size: 40))
        .foregroundStyle(.secondary.opacity(0.5))

      Text("No Journal Entries")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.secondary)

      Text("Start journaling to see entries here")
        .font(.system(size: 14))
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 60)
  }
}
