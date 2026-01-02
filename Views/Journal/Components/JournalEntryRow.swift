//
//  JournalEntryRow.swift
//  Aurora
//
//  Created by antigravity on 12/24/25.
//

import SwiftUI

struct JournalEntryRow: View {
  let entry: JournalEntry

  var body: some View {
    HStack(spacing: 12) {
      // Color indicator
      RoundedRectangle(cornerRadius: 2)
        .fill(Theme.tint)
        .frame(width: 4, height: 32)

      // Content
      VStack(alignment: .leading, spacing: 4) {
        Text(entry.title.isEmpty ? "Untitled" : entry.title)
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(Theme.primary)
          .lineLimit(1)

        if !entry.body.isEmpty {
          Text(entry.body)
            .font(.system(size: 13))
            .foregroundStyle(Theme.secondary)
            .lineLimit(1)
        }
      }

      Spacer()

      // Date/Time
      Text(entry.date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(Theme.secondary.opacity(0.7))
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .glassEffect(.regular)
  }
}
