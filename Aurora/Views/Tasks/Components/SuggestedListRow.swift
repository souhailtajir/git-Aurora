//
//  SuggestedListRow.swift
//  Aurora
//
//  Created by souhail on 12/29/25.
//

import SwiftUI

struct SuggestedListRow: View {
  let icon: String
  let iconColor: Color
  let title: String
  let subtitle: String
  let onAdd: () -> Void

  var body: some View {
    HStack(spacing: 12) {
      // Icon with colored background
      ZStack {
        Circle()
          .fill(iconColor)
          .frame(width: 36, height: 36)

        Image(systemName: icon)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.white)
      }

      // Title and subtitle
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.primary)

        Text(subtitle)
          .font(.system(size: 13))
          .foregroundStyle(.secondary)
      }

      Spacer()

      // Add button
      Button(action: onAdd) {
        Image(systemName: "plus.circle.fill")
          .font(.system(size: 24))
          .foregroundStyle(.blue)
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color.clear)
    .glassEffect(.clear)
  }
}

#Preview {
  ZStack {
    Color.black.ignoresSafeArea()

    VStack {
      SuggestedListRow(
        icon: "syringe.fill",
        iconColor: .green,
        title: "Suggested List: Groceries",
        subtitle: "Automatically categorizes items"
      ) {
        print("Add tapped")
      }
    }
    .padding()
  }
}
