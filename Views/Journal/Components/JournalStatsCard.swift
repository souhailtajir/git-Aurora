//
//  JournalStatsCard.swift
//  Aurora
//
//  Created by souhail on 1/2/26.
//

import SwiftUI

/// Information about a specific day in the activity grid
private struct DayInfo: Identifiable, Equatable {
  let id = UUID()
  let date: Date
  let entryCount: Int

  static func == (lhs: DayInfo, rhs: DayInfo) -> Bool {
    lhs.id == rhs.id
  }
}

/// GitHub-style square activity grid with tap-to-reveal day info
struct JournalActivityCard: View {
  let entries: [JournalEntry]

  @State private var selectedDay: DayInfo?

  fileprivate static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
  }()

  private let cellSize: CGFloat = 14
  private let cellSpacing: CGFloat = 3

  /// Start date: January 1, 2026
  private var startDate: Date {
    var components = DateComponents()
    components.year = 2026
    components.month = 1
    components.day = 1
    return Calendar.current.date(from: components) ?? Date()
  }

  /// Calculate weeks to show - show at least 4 weeks for visual consistency
  private var weeksToShow: Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let start = calendar.startOfDay(for: startDate)
    let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
    // Show current week + buffer, minimum 4 weeks for better visual
    return min(max((days / 7) + 4, 4), 52)
  }

  /// Build grid data: [week][dayOfWeek] -> (date, count, isFuture)
  private var gridData: [(date: Date, count: Int, isFuture: Bool)] {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    // Build entry count lookup
    var entriesByDate: [Date: Int] = [:]
    for entry in entries {
      let dayStart = calendar.startOfDay(for: entry.date)
      entriesByDate[dayStart, default: 0] += 1
    }

    var data: [(date: Date, count: Int, isFuture: Bool)] = []

    for week in 0..<weeksToShow {
      for dayOfWeek in 0..<7 {
        let daysFromStart = week * 7 + dayOfWeek
        if let date = calendar.date(byAdding: .day, value: daysFromStart, to: startDate) {
          let isFuture = date > today
          let count = isFuture ? 0 : (entriesByDate[date] ?? 0)
          data.append((date: date, count: count, isFuture: isFuture))
        }
      }
    }

    return data
  }

  private var totalEntries: Int {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let start = calendar.startOfDay(for: startDate)
    return entries.filter { $0.date >= start && $0.date <= today }.count
  }

  var body: some View {
    GeometryReader { geometry in
      let availableWidth = geometry.size.width - 32  // padding
      let availableHeight = geometry.size.height - 80  // header + legend + padding

      // Calculate optimal number of columns based on available width
      let optimalColumns = Int((availableWidth + cellSpacing) / (cellSize + cellSpacing))
      let columnsToShow = max(optimalColumns, 1)

      // Calculate dynamic cell size to fill the space
      let dynamicCellSize =
        (availableWidth - CGFloat(columnsToShow - 1) * cellSpacing) / CGFloat(columnsToShow)
      let dynamicRowHeight = (availableHeight - 6 * cellSpacing) / 7
      let finalCellSize = min(dynamicCellSize, dynamicRowHeight)

      VStack(alignment: .leading, spacing: 12) {
        // Header with entries count on right
        HStack {
          Text("Activity")
            .font(.system(size: 18, weight: .bold))

          Spacer()

          Text("\(totalEntries) entries")
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
        }

        // Grid that fills available space
        HStack(alignment: .top, spacing: cellSpacing) {
          ForEach(0..<columnsToShow, id: \.self) { column in
            VStack(spacing: cellSpacing) {
              ForEach(0..<7, id: \.self) { row in
                let index = column * 7 + row
                if index < gridData.count {
                  let data = gridData[index]
                  DaySquare(
                    date: data.date,
                    entryCount: data.count,
                    cellSize: finalCellSize,
                    selectedDay: $selectedDay
                  )
                } else {
                  // Placeholder for empty cells
                  RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: finalCellSize, height: finalCellSize)
                }
              }
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        // Legend
        HStack(spacing: 4) {
          Spacer()

          Text("Less")
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)

          ForEach(0..<5, id: \.self) { level in
            RoundedRectangle(cornerRadius: 2)
              .fill(colorForCount(level))
              .frame(width: 10, height: 10)
          }

          Text("More")
            .font(.system(size: 11))
            .foregroundStyle(.tertiary)
        }
      }
      .padding(16)
    }
    .frame(height: 220)
    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
  }

  private func colorForCount(_ count: Int) -> Color {
    switch count {
    case 0: return Color.gray.opacity(0.15)
    case 1: return Theme.tint.opacity(0.4)
    case 2: return Theme.tint.opacity(0.6)
    case 3: return Theme.tint.opacity(0.8)
    default: return Theme.tint
    }
  }
}

/// Individual day square with tap interaction
private struct DaySquare: View {
  let date: Date
  let entryCount: Int
  let cellSize: CGFloat
  @Binding var selectedDay: DayInfo?

  @State private var showPopover = false

  private var isSelected: Bool {
    selectedDay?.date == date
  }

  var body: some View {
    RoundedRectangle(cornerRadius: 3)
      .fill(colorForCount(entryCount))
      .frame(width: cellSize, height: cellSize)
      .overlay {
        if isSelected {
          RoundedRectangle(cornerRadius: 3)
            .stroke(Theme.tint, lineWidth: 1.5)
        }
      }
      .onTapGesture {
        let dayInfo = DayInfo(date: date, entryCount: entryCount)
        if selectedDay?.date == date {
          selectedDay = nil
          showPopover = false
        } else {
          selectedDay = dayInfo
          showPopover = true
        }
      }
      .popover(isPresented: $showPopover, arrowEdge: .top) {
        VStack(alignment: .leading, spacing: 6) {
          Text(JournalActivityCard.dateFormatter.string(from: date))
            .font(.system(size: 14, weight: .semibold))

          Text(
            entryCount == 0
              ? "No entries" : "\(entryCount) \(entryCount == 1 ? "entry" : "entries")"
          )
          .font(.system(size: 13))
          .foregroundStyle(.secondary)
        }
        .padding(12)
        .presentationCompactAdaptation(.popover)
      }
      .onChange(of: selectedDay) { _, newValue in
        if newValue?.date != date {
          showPopover = false
        }
      }
  }

  private func colorForCount(_ count: Int) -> Color {
    switch count {
    case 0: return Color.gray.opacity(0.15)
    case 1: return Theme.tint.opacity(0.4)
    case 2: return Theme.tint.opacity(0.6)
    case 3: return Theme.tint.opacity(0.8)
    default: return Theme.tint
    }
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
      JournalActivityCard(entries: [])
      JournalStreakCard(streak: 7)
    }
    .padding()
  }
}
