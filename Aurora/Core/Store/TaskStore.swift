//
//  TaskStore.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//

import Observation
import SwiftUI

@Observable
final class TaskStore {
  var tasks: [Task] = []
  var categories: [TaskCategory] = []
  var journalEntries: [JournalEntry] = []
  var deletedJournalEntries: [JournalEntry] = []
  var addTaskTrigger: AddTaskTrigger = .none
  var addJournalTrigger: Bool = false

  // Smart list visibility settings
  var visibleSmartLists: Set<SmartListType> = [.today, .all, .flagged] {
    didSet { scheduleSaveSettings() }
  }
  var visibleCategories: Set<UUID> = [] {
    didSet { scheduleSaveSettings() }
  }
  var smartListOrder: [SmartListType] = [] {
    didSet { scheduleSaveSettings() }
  }
  var pinnedHomeSmartLists: [SmartListType] = [.flagged] {
    didSet { scheduleSaveSettings() }
  }
  var pinnedHomeCategoryIds: [UUID] = [] {
    didSet { scheduleSaveSettings() }
  }
  var myListsExpanded: Bool = true

  enum AddTaskTrigger {
    case none, home, tasks
  }

  // MARK: - Debounce Infrastructure
  private let saveQueue = DispatchQueue(label: "com.aurora.save", qos: .utility)
  private var pendingTasksSave: DispatchWorkItem?
  private var pendingJournalSave: DispatchWorkItem?
  private var pendingCategoriesSave: DispatchWorkItem?
  private var pendingSettingsSave: DispatchWorkItem?
  private let saveDebounceInterval: TimeInterval = 0.5

  init() {
    load()
  }

  // MARK: - Task Management
  func addTask(_ task: Task) {
    tasks.append(task)
    scheduleSaveTasks()
  }

  func updateTask(_ task: Task) {
    if let index = tasks.firstIndex(where: { $0.id == task.id }) {
      tasks[index] = task
        scheduleSaveTasks()
    }
  }

  func deleteTask(_ task: Task) {
    tasks.removeAll { $0.id == task.id }
    scheduleSaveTasks()
  }

  func toggleTaskCompletion(_ task: Task) {
    if let index = tasks.firstIndex(where: { $0.id == task.id }) {
      tasks[index].isCompleted.toggle()
      scheduleSaveTasks()
    }
  }

  func clearCompletedTasks() {
    tasks.removeAll { $0.isCompleted }
    scheduleSaveTasks()
  }

  // MARK: - Category Management
  func addCategory(_ category: TaskCategory) {
    categories.append(category)
    scheduleSaveCategories()
  }

  func deleteCategory(_ category: TaskCategory) {
    categories.removeAll { $0.id == category.id }
    scheduleSaveCategories()
  }

  func updateCategory(_ category: TaskCategory) {
    if let index = categories.firstIndex(where: { $0.id == category.id }) {
      categories[index] = category
      scheduleSaveCategories()
    }
  }

  // MARK: - Journal Management
  func addJournalEntry(_ entry: JournalEntry) {
    journalEntries.append(entry)
    scheduleSaveJournal()
  }

  func deleteJournalEntry(_ entry: JournalEntry) {
    var deletedEntry = entry
    deletedEntry.deletedAt = Date()
    journalEntries.removeAll { $0.id == entry.id }
    deletedJournalEntries.append(deletedEntry)
    scheduleSaveJournal()
    scheduleSaveDeletedJournal()
  }

  func permanentlyDeleteJournalEntry(_ entry: JournalEntry) {
    deletedJournalEntries.removeAll { $0.id == entry.id }
    scheduleSaveDeletedJournal()
  }

  func restoreJournalEntry(_ entry: JournalEntry) {
    var restoredEntry = entry
    restoredEntry.deletedAt = nil
    deletedJournalEntries.removeAll { $0.id == entry.id }
    journalEntries.append(restoredEntry)
    scheduleSaveJournal()
    scheduleSaveDeletedJournal()
  }

  func cleanupOldDeletedEntries() {
    let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    let hadEntries = !deletedJournalEntries.isEmpty
    deletedJournalEntries.removeAll { entry in
      guard let deletedAt = entry.deletedAt else { return false }
      return deletedAt < thirtyDaysAgo
    }
    if hadEntries {
      scheduleSaveDeletedJournal()
    }
  }

  func updateJournalEntry(_ entry: JournalEntry) {
    if let index = journalEntries.firstIndex(where: { $0.id == entry.id }) {
      journalEntries[index] = entry
      scheduleSaveJournal()
    }
  }

  // MARK: - Debounced Save Scheduling
  private func scheduleSaveTasks() {
    pendingTasksSave?.cancel()
    let workItem = DispatchWorkItem { [weak self] in
      self?.performSaveTasks()
    }
    pendingTasksSave = workItem
    saveQueue.asyncAfter(deadline: .now() + saveDebounceInterval, execute: workItem)
  }

  private func scheduleSaveCategories() {
    pendingCategoriesSave?.cancel()
    let workItem = DispatchWorkItem { [weak self] in
      self?.performSaveCategories()
    }
    pendingCategoriesSave = workItem
    saveQueue.asyncAfter(deadline: .now() + saveDebounceInterval, execute: workItem)
  }

  private func scheduleSaveJournal() {
    pendingJournalSave?.cancel()
    let workItem = DispatchWorkItem { [weak self] in
      self?.performSaveJournal()
    }
    pendingJournalSave = workItem
    saveQueue.asyncAfter(deadline: .now() + saveDebounceInterval, execute: workItem)
  }

  private func scheduleSaveDeletedJournal() {
    // Deleted journal saves immediately (less frequent operation)
    saveQueue.async { [weak self] in
      self?.performSaveDeletedJournal()
    }
  }

  private func scheduleSaveSettings() {
    pendingSettingsSave?.cancel()
    let workItem = DispatchWorkItem { [weak self] in
      self?.performSaveSettings()
    }
    pendingSettingsSave = workItem
    saveQueue.asyncAfter(deadline: .now() + saveDebounceInterval, execute: workItem)
  }

  // MARK: - Persistence (Background Thread)
  private func getDocumentsDirectory() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
  }

  private func performSaveTasks() {
    let tasksToSave = tasks
    let url = getDocumentsDirectory().appendingPathComponent("tasks.json")
    do {
      let data = try JSONEncoder().encode(tasksToSave)
      try data.write(to: url, options: .atomic)
    } catch {
      print("Failed to save tasks: \(error)")
    }
  }

  private func performSaveCategories() {
    let categoriesToSave = categories
    let url = getDocumentsDirectory().appendingPathComponent("categories.json")
    do {
      let data = try JSONEncoder().encode(categoriesToSave)
      try data.write(to: url, options: .atomic)
    } catch {
      print("Failed to save categories: \(error)")
    }
  }

  private func performSaveJournal() {
    let entriesToSave = journalEntries
    let url = getDocumentsDirectory().appendingPathComponent("journal.json")
    do {
      let data = try JSONEncoder().encode(entriesToSave)
      try data.write(to: url, options: .atomic)
    } catch {
      print("Failed to save journal: \(error)")
    }
  }

  private func performSaveDeletedJournal() {
    let entriesToSave = deletedJournalEntries
    let url = getDocumentsDirectory().appendingPathComponent("deleted_journal.json")
    do {
      let data = try JSONEncoder().encode(entriesToSave)
      try data.write(to: url, options: .atomic)
    } catch {
      print("Failed to save deleted journal: \(error)")
    }
  }

  private func performSaveSettings() {
    let settings = AppSettings(
      visibleSmartLists: Array(visibleSmartLists),
      visibleCategories: Array(visibleCategories),
      smartListOrder: smartListOrder,
      pinnedHomeSmartLists: Array(pinnedHomeSmartLists),
      pinnedHomeCategoryIds: Array(pinnedHomeCategoryIds)
    )
    let url = getDocumentsDirectory().appendingPathComponent("settings.json")
    do {
      let data = try JSONEncoder().encode(settings)
      try data.write(to: url, options: .atomic)
    } catch {
      print("Failed to save settings: \(error)")
    }
  }

  // Force immediate save (call before app termination)
  func saveImmediately() {
    pendingTasksSave?.cancel()
    pendingJournalSave?.cancel()
    pendingCategoriesSave?.cancel()
    pendingSettingsSave?.cancel()

    saveQueue.sync {
      performSaveTasks()
      performSaveCategories()
      performSaveJournal()
      performSaveDeletedJournal()
      performSaveSettings()
    }
  }

  private func load() {
    let tasksUrl = getDocumentsDirectory().appendingPathComponent("tasks.json")
    let categoriesUrl = getDocumentsDirectory().appendingPathComponent("categories.json")
    let journalUrl = getDocumentsDirectory().appendingPathComponent("journal.json")

    // Load Categories
    do {
      let data = try Data(contentsOf: categoriesUrl)
      categories = try JSONDecoder().decode([TaskCategory].self, from: data)
    } catch {
      categories = TaskCategory.defaults
      scheduleSaveCategories()
    }

    // Load Tasks
    do {
      let data = try Data(contentsOf: tasksUrl)
      tasks = try JSONDecoder().decode([Task].self, from: data)
    } catch {
      loadSampleData()
      scheduleSaveTasks()
    }

    // Load Journal
    do {
      let data = try Data(contentsOf: journalUrl)
      journalEntries = try JSONDecoder().decode([JournalEntry].self, from: data)
    } catch {
      journalEntries = []
    }

    // Load Deleted Journal
    let deletedJournalUrl = getDocumentsDirectory().appendingPathComponent("deleted_journal.json")
    do {
      let data = try Data(contentsOf: deletedJournalUrl)
      deletedJournalEntries = try JSONDecoder().decode([JournalEntry].self, from: data)
      cleanupOldDeletedEntries()
    } catch {
      deletedJournalEntries = []
    }

    // Load Settings
    let settingsUrl = getDocumentsDirectory().appendingPathComponent("settings.json")
    do {
      let data = try Data(contentsOf: settingsUrl)
      let settings = try JSONDecoder().decode(AppSettings.self, from: data)
      visibleSmartLists = Set(settings.visibleSmartLists)
      visibleCategories = Set(settings.visibleCategories)
      smartListOrder = settings.smartListOrder
      pinnedHomeSmartLists = settings.pinnedHomeSmartLists
      pinnedHomeCategoryIds = settings.pinnedHomeCategoryIds
    } catch {
      // Use defaults
      visibleSmartLists = [.today, .all, .flagged]
      smartListOrder = []
      pinnedHomeSmartLists = [.flagged]
      pinnedHomeCategoryIds = []
    }
  }

  private func loadSampleData() {
    let calendar = Calendar.current
    let now = Date()

    tasks = [
      Task(
        title: "Follow up with a client",
        date: calendar.date(bySettingHour: 10, minute: 30, second: 0, of: now), priority: .medium,
        category: .work, hasReminder: true),
      Task(
        title: "Send design mocks",
        date: calendar.date(bySettingHour: 13, minute: 30, second: 0, of: now), priority: .high,
        category: .work, isFlagged: true, hasReminder: true),
      Task(
        title: "Prepare for a meeting",
        date: calendar.date(bySettingHour: 15, minute: 0, second: 0, of: now), priority: .medium,
        category: .work, hasReminder: true),
      Task(
        title: "Groceries", date: calendar.date(bySettingHour: 21, minute: 30, second: 0, of: now),
        priority: .low, category: .shopping, hasReminder: true),
      Task(
        title: "Wish SOUHAIL a Happy Birthday",
        date: calendar.date(bySettingHour: 23, minute: 45, second: 0, of: now), priority: .high,
        category: .personal, isFlagged: true, hasReminder: true),
    ]
  }
}
