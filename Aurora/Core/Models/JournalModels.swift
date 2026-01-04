//
//  JournalModels.swift
//  Aurora
//
//  Created by souhail on 12/4/25.
//

import Foundation
import SwiftUI

struct JournalEntry: Identifiable, Codable, Hashable, Sendable {
  var id: UUID = UUID()
  var title: String
  var body: String
  var date: Date
  var theme: JournalTheme = .system
  var images: [Data] = []
  var deletedAt: Date? = nil
}

enum JournalTheme: String, Codable, CaseIterable, Sendable {
  case system = "Default"
  case oldPaper = "Old Paper"
  case midnight = "Midnight"
  case aurora = "Aurora"

  var backgroundColor: Color {
    switch self {
    case .system: return Theme.backgroundTop
    case .oldPaper: return Color(hex: "F4ECD8")
    case .midnight: return .black
    case .aurora: return .black
    }
  }

  var textColor: Color {
    switch self {
    case .system: return Theme.primary
    case .oldPaper: return Color(hex: "3C3C3C")
    case .midnight: return .white
    case .aurora: return .white
    }
  }

  var accentColor: Color {
    switch self {
    case .system: return Theme.primary
    case .oldPaper: return Color(hex: "8B4513")
    case .midnight: return Color(hex: "6B46C1")
    case .aurora: return Color(hex: "00F0FF")
    }
  }
}
