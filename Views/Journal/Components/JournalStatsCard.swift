//
//  JournalStatsCard.swift
//  Aurora
//
//  Created by souhail on 1/2/26.
//

import SwiftUI

enum InsightsPeriod: String, CaseIterable, Identifiable {
  case week = "Week"
  case month = "Month"
  case year = "Year"

  var id: String { rawValue }

  var weeksToShow: Int {
    switch self {
    case .week: return 2
    case .month: return 5
    case .year: return 52
    }
  }
}

/// GitHub-style square activity grid with native Picker
struct JournalActivityCard: View {
  let entries: [JournalEntry]
  @Binding var selectedPeriod: InsightsPeriod

  private let rows = 7  // days per week

  private var contributionGrid: [[Int]] {
    let weeks = selectedPeriod.weeksToShow
    var grid = Array(repeating: Array(repeating: 0, count: rows), count: weeks)

    let calendar = Calendar.current
    let today = Date()

    guard let startDate = calendar.date(byAdding: .day, value: -(weeks * 7) + 1, to: today) else {
      return grid
    }

    for entry in entries {
      let daysDiff = calendar.dateComponents([.day], from: startDate, to: entry.date).day ?? -1
      if daysDiff >= 0 && daysDiff < weeks * 7 {
        let weekIndex = daysDiff / 7
        let dayIndex = daysDiff % 7
        if weekIndex < weeks && dayIndex < rows {
          grid[weekIndex][dayIndex] += 1
        }
      }
    }

    return grid
  }

  private var entryCount: Int {
    let calendar = Calendar.current
    let now = Date()

    switch selectedPeriod {
    case .week:
      guard let date = calendar.date(byAdding: .weekOfYear, value: -2, to: now) else { return 0 }
      return entries.filter { $0.date >= date }.count
    case .month:
      guard let date = calendar.date(byAdding: .month, value: -1, to: now) else { return 0 }
      return entries.filter { $0.date >= date }.count
    case .year:
      return entries.filter { calendar.isDate($0.date, equalTo: now, toGranularity: .year) }.count
    }
  }

  private var cellSize: CGFloat {
    switch selectedPeriod {
    case .week: return 24
    case .month: return 16
    case .year: return 5
    }
  }

  private var cellSpacing: CGFloat {
    switch selectedPeriod {
    case .week: return 4
    case .month: return 3
    case .year: return 2
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Header with Picker
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Activity")
            .font(.system(size: 18, weight: .bold))

          Text("\(entryCount) entries")
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
        }

        Spacer()

        // Native segmented Picker
        Picker("Period", selection: $selectedPeriod) {
          ForEach(InsightsPeriod.allCases) { period in
            Text(period.rawValue).tag(period)
          }
        }
        .pickerStyle(.segmented)
        .frame(width: 180)
      }

      // GitHub-style grid
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: cellSpacing) {
          ForEach(0..<selectedPeriod.weeksToShow, id: \.self) { week in
            VStack(spacing: cellSpacing) {
              ForEach(0..<rows, id: \.self) { day in
                RoundedRectangle(cornerRadius: cellSize > 10 ? 4 : 2)
                  .fill(colorForCount(contributionGrid[week][day]))
                  .frame(width: cellSize, height: cellSize)
              }
            }
          }
        }
      }
      .frame(maxWidth: .infinity)

      // Legend
      HStack(spacing: 4) {
        Spacer()

        Text("Less")
          .font(.system(size: 11))
          .foregroundStyle(.tertiary)

        ForEach(0..<5, id: \.self) { level in
          RoundedRectangle(cornerRadius: 2)
            .fill(colorForLevel(level))
            .frame(width: 10, height: 10)
        }

        Text("More")
          .font(.system(size: 11))
          .foregroundStyle(.tertiary)
      }
    }
    .padding(16)
    .glassEffect(.regular)
  }

  private func colorForCount(_ count: Int) -> Color {
    switch count {
    case 0: return Theme.tint.opacity(0.08)
    case 1: return Theme.tint.opacity(0.35)
    case 2: return Theme.tint.opacity(0.55)
    case 3: return Theme.tint.opacity(0.75)
    default: return Theme.tint
    }
  }

  private func colorForLevel(_ level: Int) -> Color {
    colorForCount(level)
  }
}

/// Card showing journaling streak
struct JournalStreakCard: View {
  let streak: Int

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("Streak")
          .font(.system(size: 14))
          .foregroundStyle(.secondary)

        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text("\(streak)")
            .font(.system(size: 28, weight: .bold))
            .foregroundStyle(.orange)

          Text("days")
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      Image(systemName: "flame.fill")
        .font(.system(size: 32))
        .foregroundStyle(.orange.gradient)
    }
    .padding(16)
    .glassEffect(.regular)
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()

    VStack(spacing: 16) {
      JournalActivityCard(entries: [], selectedPeriod: .constant(.week))
      JournalStreakCard(streak: 7)
    }
    .padding()
  }
}
