//
//  Theme.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//

import SwiftUI

enum Theme {
  static let primary = Color(red: 0.4, green: 0.35, blue: 0.9)
  static let secondary = Color(red: 0.5, green: 0.4, blue: 0.95)
  static let tint = Color(red: 0.4, green: 0.35, blue: 0.9)  // Mapped to primary for consistency

  // Light mode gradients
  static let backgroundTop = Color(red: 0.85, green: 0.8, blue: 0.95)
  static let backgroundBottom = Color(red: 0.9, green: 0.85, blue: 0.95)

  // Dark mode gradients
  static let darkBackgroundTop = Color(red: 0.12, green: 0.1, blue: 0.2)
  static let darkBackgroundBottom = Color(red: 0.18, green: 0.15, blue: 0.25)

  // Insights Card Gradients (Deep Purple/Indigo)
  static let insightsGradientTop = Color(hex: "56559C")  // Muted Indigo
  static let insightsGradientBottom = Color(hex: "3F3E7A")  // Deep Purple

  // Task Row Background
  static let taskRowBackground = Color(red: 0.88, green: 0.84, blue: 0.95)

  // Filter Chip Colors
  static let chipFlagged = Color(red: 1.0, green: 0.5, blue: 0.3)  // Orange
  static let chipWork = Color(red: 0.4, green: 0.7, blue: 1.0)  // Blue
  static let chipPersonal = Color(red: 0.7, green: 0.4, blue: 0.95)  // Purple
  static let chipShopping = Color(red: 0.4, green: 0.85, blue: 0.5)  // Green

  // Category Colors
  static let flagColor = Color(red: 1.0, green: 0.6, blue: 0.0)
  static let workColor = Color(red: 0.4, green: 0.7, blue: 1.0)
  static let personalColor = Color(red: 0.7, green: 0.4, blue: 0.95)
  static let shoppingColor = Color(red: 0.4, green: 0.85, blue: 0.5)
  static let healthColor = Color(red: 1.0, green: 0.4, blue: 0.5)

  static var auroraBackground: some View {
    AuroraBackgroundView()
  }

  // Helper function to get category color
  static func categoryColor(for category: TaskCategory) -> Color {
    Color(hex: category.colorHex)
  }
}

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a: UInt64
    let r: UInt64
    let g: UInt64
    let b: UInt64
    switch hex.count {
    case 3:  // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:  // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:  // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (1, 1, 1, 0)
    }

    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}

extension View {
  @ViewBuilder

  func auroraBackground() -> some View {
    background(AuroraBackgroundView())
  }
}

struct AuroraBackgroundView: View {
  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    ZStack {
      if colorScheme == .dark {
        // Dark Mode: Deep black with purple aurora gradient
        Color.black

        LinearGradient(
          colors: [
            Color(hex: "5B50A0").opacity(0.4),  // Purple
            Color(hex: "2D1B69").opacity(0.2),  // Deep indigo
            .clear,
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      } else {
        // Light Mode: Soft lavender with subtle purple gradient
        Color(red: 0.96, green: 0.95, blue: 0.98)  // Very light lavender base

        LinearGradient(
          colors: [
            Color(hex: "E8D4FF").opacity(0.5),  // Soft purple
            Color(hex: "D4C4FF").opacity(0.3),  // Light lavender
            .clear,
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
    }
    .ignoresSafeArea()
  }
}
