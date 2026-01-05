//
//  DeletedEntriesView.swift
//  Aurora
//

import SwiftUI

struct DeletedEntriesView: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        // Header
        VStack(alignment: .leading, spacing: 4) {
          Text("Recently Deleted")
            .font(.system(size: 28, weight: .bold))
          Text("\(taskStore.deletedJournalEntries.count) entries")
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
        }
        .padding(.top, 16)

        // Empty state or entries
        if taskStore.deletedJournalEntries.isEmpty {
          VStack(spacing: 12) {
            Image(systemName: "trash")
              .font(.system(size: 36))
              .foregroundStyle(.secondary.opacity(0.5))
            Text("No deleted entries")
              .font(.system(size: 15))
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 60)
        } else {
          ForEach(taskStore.deletedJournalEntries) { entry in
            deletedRowContent(entry)
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
        .frame(width: 40, height: 40)
        .glassEffect(.regular)
        .clipShape(Circle())
      }
    }
  }

  private func deletedRowContent(_ entry: JournalEntry) -> some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(entry.title.isEmpty ? "Untitled" : entry.title)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.primary)
          .lineLimit(1)

        if let deletedAt = entry.deletedAt {
          Text("Deleted \(deletedAt.formatted(.relative(presentation: .named)))")
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      Button {
        withAnimation {
          taskStore.restoreJournalEntry(entry)
        }
      } label: {
        Text("Restore")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(Theme.tint)
      }

      Button {
        withAnimation {
          taskStore.permanentlyDeleteJournalEntry(entry)
        }
      } label: {
        Image(systemName: "trash")
          .font(.system(size: 14))
          .foregroundStyle(.red)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .glassEffect(.regular)
  }
}
