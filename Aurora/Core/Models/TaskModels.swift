//
//  TaskModels.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//

import Foundation
import SwiftUI

enum TaskPriority: String, Codable, CaseIterable, Identifiable, Sendable {
  case none = "None"
  case low = "Low"
  case medium = "Medium"
  case high = "High"

  var id: String { rawValue }

  var color: Color {
    switch self {
    case .none: return .gray
    case .low: return .blue
    case .medium: return .orange
    case .high: return .red
    }
  }
}

struct Task: Identifiable, Codable, Sendable, Equatable {
  let id: UUID
  var title: String
  var date: Date?
  var category: TaskCategory
  var isCompleted: Bool
  var isFlagged: Bool
  var hasReminder: Bool
  var notes: String
  var url: String
  var priority: TaskPriority

  init(
    id: UUID = UUID(),
    title: String,
    notes: String = "",
    url: String = "",
    date: Date? = nil,
    priority: TaskPriority = .none,
    category: TaskCategory = .personal,
    isCompleted: Bool = false,
    isFlagged: Bool = false,
    hasReminder: Bool = false
  ) {
    self.id = id
    self.title = title
    self.notes = notes
    self.url = url
    self.date = date
    self.priority = priority
    self.category = category
    self.isCompleted = isCompleted
    self.isFlagged = isFlagged
    self.hasReminder = hasReminder
  }

  var time: String {
    guard let date = date else { return "" }
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    return formatter.string(from: date).uppercased()
  }
}

struct TaskCategory: Identifiable, Codable, Hashable, Sendable {
  let id: UUID
  var name: String
  var colorHex: String
  var iconName: String

  init(id: UUID = UUID(), name: String, colorHex: String, iconName: String) {
    self.id = id
    self.name = name
    self.colorHex = colorHex
    self.iconName = iconName
  }

  static let reminders = TaskCategory(
    name: "Reminders", colorHex: "#007AFF", iconName: "list.bullet")
  static let personal = TaskCategory(name: "Personal", colorHex: "#B366F3", iconName: "person.fill")
  static let work = TaskCategory(name: "Work", colorHex: "#66B3FF", iconName: "briefcase.fill")
  static let shopping = TaskCategory(name: "Shopping", colorHex: "#66D980", iconName: "cart.fill")
  static let health = TaskCategory(name: "Health", colorHex: "#FF6680", iconName: "heart.fill")

  static let defaults: [TaskCategory] = [.reminders, .personal, .work, .shopping, .health]
}

enum TaskFilter: String, CaseIterable, Identifiable, Sendable {
  case all = "All"
  case today = "Today"
  case upcoming = "Upcoming"
  case flagged = "Flagged"

  var id: String { rawValue }
}

/// Settings for app customization that need to be persisted
struct AppSettings: Codable {
  var visibleSmartLists: [SmartListType]
  var visibleCategories: [UUID]
  var smartListOrder: [SmartListType]
  var pinnedHomeSmartLists: [SmartListType]
  var pinnedHomeCategoryIds: [UUID]
  var weekStartsOnMonday: Bool

  init(
    visibleSmartLists: [SmartListType] = [],
    visibleCategories: [UUID] = [],
    smartListOrder: [SmartListType] = [],
    pinnedHomeSmartLists: [SmartListType] = [.flagged],
    pinnedHomeCategoryIds: [UUID] = [],
    weekStartsOnMonday: Bool = true
  ) {
    self.visibleSmartLists = visibleSmartLists
    self.visibleCategories = visibleCategories
    self.smartListOrder = smartListOrder
    self.pinnedHomeSmartLists = pinnedHomeSmartLists
    self.pinnedHomeCategoryIds = pinnedHomeCategoryIds
    self.weekStartsOnMonday = weekStartsOnMonday
  }
}
