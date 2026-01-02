//
//  DeletedJournalView.swift
//  Aurora
//
//  Created by antigravity on 12/25/25.
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
    ZStack(alignment: .top) {
      Color.clear.auroraBackground()

      if taskStore.deletedJournalEntries.isEmpty {
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
            Text("Recently Deleted")
              .font(.system(size: 32, weight: .bold))
              .foregroundStyle(Theme.primary)

            Text(
              "Entries are available here for 30 days. After that time, entries will be permanently deleted."
            )
            .font(.system(size: 14))
            .foregroundStyle(Theme.secondary)
          }
          .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16))
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)

          // Grouped entries by days remaining
          ForEach(groupedEntries, id: \.daysRemaining) { group in
            Section {
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
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                  Button {
                    withAnimation {
                      taskStore.restoreJournalEntry(entry)
                    }
                  } label: {
                    Label("", systemImage: "arrow.uturn.backward")
                  }
                  .tint(.green)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                  Button(role: .destructive) {
                    withAnimation {
                      taskStore.permanentlyDeleteJournalEntry(entry)
                    }
                  } label: {
                    Label("", systemImage: "trash.fill")
                  }
                }
              }
            } header: {
              Text("\(group.daysRemaining) Days Remaining")
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
  }

  // MARK: - Header
  private var headerView: some View {
    VStack(spacing: 0) {
      HStack {
        // Back button or Select All
        if isSelecting {
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
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Theme.tint)
          }
        } else {
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
        }

        Spacer()

        // Selection Actions & Done Button
        if !taskStore.deletedJournalEntries.isEmpty {
          HStack(spacing: 8) {
            if isSelecting && !selectedEntries.isEmpty {
              // Recover Button
              Button {
                withAnimation {
                  for entryId in selectedEntries {
                    if let entry = taskStore.deletedJournalEntries.first(where: { $0.id == entryId }
                    ) {
                      taskStore.restoreJournalEntry(entry)
                    }
                  }
                  selectedEntries.removeAll()
                  isSelecting = false
                }
              } label: {
                Image(systemName: "arrow.uturn.backward")
                  .font(.system(size: 14, weight: .bold))
                  .foregroundStyle(.white)
                  .frame(width: 32, height: 32)
                  .background(Circle().fill(Color.green))
              }
              .transition(.scale.combined(with: .opacity))

              // Delete Button
              Button {
                withAnimation {
                  for entryId in selectedEntries {
                    if let entry = taskStore.deletedJournalEntries.first(where: { $0.id == entryId }
                    ) {
                      taskStore.permanentlyDeleteJournalEntry(entry)
                    }
                  }
                  selectedEntries.removeAll()
                  isSelecting = false
                }
              } label: {
                Image(systemName: "trash.fill")
                  .font(.system(size: 14, weight: .bold))
                  .foregroundStyle(.white)
                  .frame(width: 32, height: 32)
                  .background(Circle().fill(Color.red))
              }
              .transition(.scale.combined(with: .opacity))
            }

            // Select / Done Button
            Button {
              withAnimation {
                isSelecting.toggle()
                if !isSelecting {
                  selectedEntries.removeAll()
                }
              }
            } label: {
              Text(isSelecting ? "Done" : "Select")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Theme.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                  Capsule()
                    .fill(.clear)
                    .glassEffect(.clear)
                )
            }
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.top, 8)
      .frame(height: 50)
    }
  }

  // MARK: - Empty State
  private var emptyState: some View {
    VStack(spacing: 16) {
      Spacer()

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
    .glassEffect(.clear)
    .contentShape(Rectangle())
    .onTapGesture {
      if isSelecting {
        onSelect()
      }
    }
  }
}
