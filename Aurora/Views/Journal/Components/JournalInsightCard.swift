//
//  JournalInsightCard.swift
//  Aurora
//
//  Astrology-themed insight card for journal stats
//

import SwiftUI

struct JournalInsightCard: View {
  let totalEntries: Int
  let entriesThisMonth: Int

  private let starColor = Color(red: 0.95, green: 0.85, blue: 0.6)

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Header with stars
      HStack {
        Image(systemName: "sparkles")
          .font(.system(size: 24, weight: .medium))
          .foregroundStyle(starColor)

        Spacer()

        // Decorative stars
        HStack(spacing: 8) {
          Image(systemName: "star.fill")
            .font(.system(size: 10))
            .foregroundStyle(starColor.opacity(0.6))
          Image(systemName: "star.fill")
            .font(.system(size: 14))
            .foregroundStyle(starColor.opacity(0.8))
          Image(systemName: "star.fill")
            .font(.system(size: 10))
            .foregroundStyle(starColor.opacity(0.6))
        }
      }

      // Main content
      VStack(alignment: .leading, spacing: 8) {
        Text("Your Journey")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(.secondary)

        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text("\(totalEntries)")
            .font(.system(size: 42, weight: .bold))
            .foregroundStyle(.primary)

          Text("entries")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.secondary)
        }
      }

      // Bottom insight
      HStack {
        Image(systemName: "moon.stars.fill")
          .font(.system(size: 14))
          .foregroundStyle(Theme.secondary)

        Text("\(entriesThisMonth) this month")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(.secondary)

        Spacer()

        // Constellation decoration
        HStack(spacing: 3) {
          Circle()
            .fill(starColor.opacity(0.4))
            .frame(width: 3, height: 3)
          Circle()
            .fill(starColor.opacity(0.6))
            .frame(width: 4, height: 4)
          Circle()
            .fill(starColor.opacity(0.4))
            .frame(width: 3, height: 3)
        }
      }
    }
    .padding(20)
    .frame(maxWidth: .infinity, alignment: .leading)
    .glassEffect(.clear.tint(Theme.tint.opacity(0.2)))
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()
    JournalInsightCard(totalEntries: 47, entriesThisMonth: 12)
      .padding()
  }
}
