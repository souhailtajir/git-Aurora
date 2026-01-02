//
//  DeletedJournalView.swift
//  Aurora
//
//  Created by souhail on 12/25/25.
//

import SwiftUI

struct DeletedJournalView: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss
  @State private var isSelecting = false
  @State private var selectedEntries: Set<UUID> = []

  // Group entries by days remaining
  private var groupedEntries: [(daysRemaining: Int, entries: [JournalEntry])] {
    let grouped = Dictionary(grouping: taskStore.deletedJournalEntries) { entry -> Int in
      guard let deletedAt = entry.deletedAt else { return 30 }
      let deleteDate = Calendar.current.date(byAdding: .day, value: 30, to: deletedAt) ?? Date()
      return max(0, Calendar.current.dateComponents([.day], from: Date(), to: deleteDate).day ?? 0)
    }
    return grouped.sorted { $0.key < $1.key }.map { (daysRemaining: $0.key, entries: $0.value) }
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(spacing: 16) {
        if taskStore.deletedJournalEntries.isEmpty {
          emptyState
        } else {
          // Info text
          Text(
            "Entries are available here for 30 days. After that time, entries will be permanently deleted."
          )
          .font(.system(size: 14))
          .foregroundStyle(Theme.secondary)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, 4)

          // Grouped entries by days remaining
          ForEach(groupedEntries, id: \.daysRemaining) { group in
            VStack(alignment: .leading, spacing: 8) {
              // Days remaining header
              Text("\(group.daysRemaining) Days Remaining")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.tint)
                .padding(.horizontal, 4)
                .padding(.top, 8)

              // Entries
              ForEach(group.entries) { entry in
                DeletedEntryCard(
                  entry: entry,
                  isSelecting: isSelecting,
                  isSelected: selectedEntries.contains(entry.id),
                  onSelect: {
                    if selectedEntries.contains(entry.id) {
                      selectedEntries.remove(entry.id)
                    } else {
                      selectedEntries.insert(entry.id)
                    }
                  },
                  onRecover: {
                    withAnimation {
                      taskStore.restoreJournalEntry(entry)
                    }
                  },
                  onDelete: {
                    withAnimation {
                      taskStore.permanentlyDeleteJournalEntry(entry)
                    }
                  }
                )
                .contextMenu {
                  Button {
                    withAnimation { taskStore.restoreJournalEntry(entry) }
                  } label: {
                    Label("Recover", systemImage: "arrow.uturn.backward")
                  }

                  Button(role: .destructive) {
                    withAnimation { taskStore.permanentlyDeleteJournalEntry(entry) }
                  } label: {
                    Label("Delete Permanently", systemImage: "trash")
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
    .navigationTitle("Recently Deleted")
    .toolbarTitleDisplayMode(.inlineLarge)
    .safeAreaPadding(.top, 8)
    .toolbar {
      ToolbarItemGroup(placement: .topBarTrailing) {
        if !taskStore.deletedJournalEntries.isEmpty {
          if isSelecting && !selectedEntries.isEmpty {
            // Recover Button
            Button {
              withAnimation {
                for entryId in selectedEntries {
                  if let entry = taskStore.deletedJournalEntries.first(where: { $0.id == entryId })
                  {
                    taskStore.restoreJournalEntry(entry)
                  }
                }
                selectedEntries.removeAll()
                isSelecting = false
              }
            } label: {
              Image(systemName: "arrow.uturn.backward")
                .foregroundStyle(.green)
            }

            // Delete Button
            Button(role: .destructive) {
              withAnimation {
                for entryId in selectedEntries {
                  if let entry = taskStore.deletedJournalEntries.first(where: { $0.id == entryId })
                  {
                    taskStore.permanentlyDeleteJournalEntry(entry)
                  }
                }
                selectedEntries.removeAll()
                isSelecting = false
              }
            } label: {
              Image(systemName: "trash")
            }
          }

          // Select / Done Button
          Button(isSelecting ? "Done" : "Select") {
            withAnimation {
              isSelecting.toggle()
              if !isSelecting {
                selectedEntries.removeAll()
              }
            }
          }
        }
      }

      if isSelecting {
        ToolbarItem(placement: .topBarLeading) {
          Button {
            withAnimation {
              if selectedEntries.count == taskStore.deletedJournalEntries.count {
                selectedEntries.removeAll()
              } else {
                selectedEntries = Set(taskStore.deletedJournalEntries.map { $0.id })
              }
            }
          } label: {
            Text(
              selectedEntries.count == taskStore.deletedJournalEntries.count
                ? "Deselect All" : "Select All"
            )
            .foregroundStyle(Theme.tint)
          }
        }
      }
    }
  }

  // MARK: - Empty State

  private var emptyState: some View {
    VStack(spacing: 16) {
      Spacer()
        .frame(height: 100)

      Image(systemName: "trash")
        .font(.system(size: 48))
        .foregroundStyle(Theme.secondary.opacity(0.4))

      Text("No Deleted Entries")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(Theme.primary)

      Text("Entries you delete will appear here for 30 days.")
        .font(.system(size: 14))
        .foregroundStyle(Theme.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)

      Spacer()
    }
    .frame(maxWidth: .infinity)
  }
}

// MARK: - Deleted Entry Card

struct DeletedEntryCard: View {
  let entry: JournalEntry
  let isSelecting: Bool
  let isSelected: Bool
  let onSelect: () -> Void
  let onRecover: () -> Void
  let onDelete: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      if isSelecting {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 22))
          .foregroundStyle(isSelected ? Theme.tint : Theme.secondary.opacity(0.5))
      }

      VStack(alignment: .leading, spacing: 8) {
        // Title
        Text(entry.title.isEmpty ? "Untitled" : entry.title)
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(Theme.primary)
          .lineLimit(1)

        // Date
        Text(entry.date.formatted(.dateTime.weekday(.wide).month(.abbreviated).day().year()))
          .font(.system(size: 13))
          .foregroundStyle(Theme.secondary.opacity(0.7))
      }

      Spacer()
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .glassEffect(.regular)
    .contentShape(Rectangle())
    .onTapGesture {
      if isSelecting {
        onSelect()
      }
    }
  }
}
