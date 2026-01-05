//
//  JournalEntryRow.swift
//  Aurora
//
//  Entry row matching TasksView styling
//

import SwiftUI

struct JournalEntryRow: View {
  @Environment(TaskStore.self) var taskStore
  let entry: JournalEntry
  let onTap: () -> Void

  private var timeText: String {
    entry.date.formatted(.dateTime.hour().minute())
  }

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: 12) {
        // Title
        Text(entry.title.isEmpty ? "Untitled" : entry.title)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.primary)
          .lineLimit(1)

        Spacer()

        // Time
        Text(timeText)
          .font(.system(size: 14))
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .glassEffect(.regular)
    }
    .buttonStyle(.plain)
    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
      Button(role: .destructive) {
        withAnimation {
          taskStore.deleteJournalEntry(entry)
        }
      } label: {
        Label("Delete", systemImage: "trash")
      }
    }
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()
    VStack(spacing: 8) {
      JournalEntryRow(
        entry: JournalEntry(title: "Morning Thoughts", body: "", date: Date()),
        onTap: {}
      )
      JournalEntryRow(
        entry: JournalEntry(title: "", body: "", date: Date()),
        onTap: {}
      )
    }
    .padding()
    .environment(TaskStore())
  }
}
