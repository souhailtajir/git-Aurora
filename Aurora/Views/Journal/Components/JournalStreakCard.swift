//
//  JournalStreakCard.swift
//  Aurora
//
//  Wider streak card for journal writing streaks
//

import SwiftUI

struct JournalStreakCard: View {
  let streak: Int

  var body: some View {
    HStack(spacing: 16) {
      // Flame icon
      ZStack {
        Circle()
          .fill(.orange.opacity(0.2))
          .frame(width: 48, height: 48)

        Image(systemName: "flame.fill")
          .font(.system(size: 24, weight: .medium))
          .foregroundStyle(.orange)
      }

      // Text content
      VStack(alignment: .leading, spacing: 4) {
        Text("Writing Streak")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(.secondary)

        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text("\(streak)")
            .font(.system(size: 28, weight: .bold))
            .foregroundStyle(.orange)

          Text(streak == 1 ? "day" : "days")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      // Streak indicator dots
      HStack(spacing: 4) {
        ForEach(0..<min(streak, 7), id: \.self) { index in
          Circle()
            .fill(.orange.opacity(0.3 + Double(index) * 0.1))
            .frame(width: 6, height: 6)
        }
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity)
    .glassEffect(.regular.tint(.orange.opacity(0.15)))
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()
    VStack(spacing: 16) {
      JournalStreakCard(streak: 5)
      JournalStreakCard(streak: 1)
      JournalStreakCard(streak: 12)
    }
    .padding()
  }
}
