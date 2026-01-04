//
//  JournalDashboardView.swift
//  Aurora
//
//  Created by antigravity on 12/24/25.
//

import LocalAuthentication
import SwiftUI

struct JournalDashboardView: View {
  @Environment(TaskStore.self) var taskStore
  let entries: [JournalEntry]

  @Binding var showDeletedJournal: Bool
  @Binding var showAllJournals: Bool

  private var entriesThisYear: Int {
    entries.filter {
      Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .year)
    }.count
  }

  private var currentStreak: Int {
    calculateStreak()
  }

  var body: some View {
    VStack(spacing: 16) {
      // Insights Card (Purple Gradient)
      ZStack(alignment: .topLeading) {
        RoundedRectangle(cornerRadius: 24)
          .fill(
            LinearGradient(
              colors: [Theme.insightsGradientTop, Theme.insightsGradientBottom],
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            )
          )

        VStack(alignment: .leading, spacing: 8) {
          Text("Insights")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white.opacity(0.9))

          Spacer()

          Text("\(entriesThisYear)")
            .font(.system(size: 48, weight: .bold))
            .foregroundStyle(.white)

          HStack(spacing: 4) {
            Text("Entries")
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(.white.opacity(0.9))
            Text("This Year")
              .font(.system(size: 14, weight: .medium))
              .foregroundStyle(.white.opacity(0.6))
          }
        }
        .padding(20)
      }
      .frame(height: 160)

      // Streak Card
      VStack(alignment: .leading, spacing: 0) {
        HStack(alignment: .top) {
          Image(systemName: "flame.fill")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.orange)

          Spacer()

          Text("\(currentStreak)")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.orange)
        }

        Spacer()

        Text("Day Streak")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.orange)
      }
      .padding(20)
      .frame(height: 110)
      .frame(maxWidth: .infinity, alignment: .leading)
      .glassEffect(.clear)
      .clipShape(RoundedRectangle(cornerRadius: 24))

      // Journals Section
      VStack(alignment: .leading, spacing: 12) {
        Text("Journals")
          .font(.system(size: 22, weight: .bold))
          .foregroundStyle(.primary)
          .padding(.horizontal, 4)

        // Journal Row
        Button {
          showAllJournals = true
        } label: {
          HStack(spacing: 12) {
            // Glyph only - no square background
            Image(systemName: "paperplane.fill")
              .font(.system(size: 20, weight: .medium))
              .foregroundStyle(Theme.tint)
              .frame(width: 32, height: 32)

            Text("Journal")
              .font(.system(size: 16, weight: .medium))
              .foregroundStyle(.primary)

            Spacer()

            Text("\(entries.count)")
              .font(.system(size: 16))
              .foregroundStyle(.secondary)

            Image(systemName: "chevron.right")
              .font(.system(size: 14))
              .foregroundStyle(.secondary.opacity(0.5))
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.clear)
        .glassEffect(.clear)

        // Recently Deleted Row
        Button {
          showDeletedJournal = true
        } label: {
          HStack(spacing: 12) {
            // Glyph only - no square background
            Image(systemName: "trash")
              .font(.system(size: 20, weight: .medium))
              .foregroundStyle(.gray)
              .frame(width: 32, height: 32)

            Text("Recently Deleted")
              .font(.system(size: 16, weight: .medium))
              .foregroundStyle(.primary)

            Spacer()

            if taskStore.deletedJournalEntries.count > 0 {
              Text("\(taskStore.deletedJournalEntries.count)")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            }

            Image(systemName: "chevron.right")
              .font(.system(size: 14))
              .foregroundStyle(.secondary.opacity(0.5))
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(Color.clear)
        .glassEffect(.clear)
      }
    }
    .padding(.horizontal, 16)
  }

  // MARK: - Face ID Authentication
  private func authenticateWithBiometrics() {
    let context = LAContext()
    var error: NSError?

    // First check if any authentication is available
    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
      // No authentication available, just open
      showDeletedJournal = true
      return
    }

    // Try biometrics first, then fallback to passcode
    let policy: LAPolicy =
      context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
      ? .deviceOwnerAuthenticationWithBiometrics
      : .deviceOwnerAuthentication

    context.evaluatePolicy(
      policy,
      localizedReason: "Authenticate to access Recently Deleted"
    ) { success, authError in
      DispatchQueue.main.async {
        if success {
          showDeletedJournal = true
        } else if let laError = authError as? LAError {
          // User cancelled - don't open
          if laError.code == .userCancel || laError.code == .userFallback {
            return
          }
          // Other error - open anyway for development/simulator
          showDeletedJournal = true
        }
      }
    }
  }

  private func calculateStreak() -> Int {
    let sortedDates = entries.map { $0.date }.sorted(by: >)
    guard let latest = sortedDates.first else { return 0 }

    if !Calendar.current.isDateInToday(latest) && !Calendar.current.isDateInYesterday(latest) {
      return 0
    }

    var streak = 1
    var previousDate = latest

    for date in sortedDates.dropFirst() {
      if Calendar.current.isDate(date, inSameDayAs: previousDate) {
        continue
      }

      if let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: previousDate),
        Calendar.current.isDate(date, inSameDayAs: dayBefore)
      {
        streak += 1
        previousDate = date
      } else {
        break
      }
    }

    return streak
  }
}
