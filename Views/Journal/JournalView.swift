//
//  JournalView.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//

import LocalAuthentication
import SwiftUI

struct JournalView: View {
  @Environment(TaskStore.self) var taskStore
  @FocusState private var searchFocused: Bool
  @State private var searchText = ""
  @State private var showingSettings = false
  @State private var showSearch = false
  @State private var journalsExpanded = true
  @State private var recentEntriesExpanded = true
  @State private var navigationPath = NavigationPath()
  @State private var selectedInsightsPeriod: InsightsPeriod = .week

  private var filteredEntries: [JournalEntry] {
    let sorted = taskStore.journalEntries.sorted(by: { $0.date > $1.date })
    if searchText.isEmpty {
      return sorted
    }
    return sorted.filter {
      $0.title.localizedCaseInsensitiveContains(searchText)
        || $0.body.localizedCaseInsensitiveContains(searchText)
    }
  }

  private var recentEntries: [JournalEntry] {
    Array(filteredEntries.prefix(5))
  }

  private var entriesThisYear: Int {
    taskStore.journalEntries.filter {
      Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .year)
    }.count
  }

  private var currentStreak: Int {
    calculateStreak()
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      Group {
        if taskStore.journalsLocked {
          lockedStateView
        } else if taskStore.journalEntries.isEmpty {
          emptyState
        } else {
          mainContent
        }
      }
      .background(Color.clear.auroraBackground())
      .navigationTitle("Journal")
      .toolbarTitleDisplayMode(.inlineLarge)
      .safeAreaInset(edge: .bottom) {
        if showSearch {
          BottomSearchBar(
            searchText: $searchText,
            showSearch: $showSearch,
            placeholder: "Search journals...",
            focusState: $searchFocused
          )
          .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
      .animation(.easeInOut(duration: 0.25), value: showSearch)
      .toolbar {
        ToolbarItemGroup(placement: .topBarTrailing) {
          Button("Search", systemImage: "magnifyingglass") {
            withAnimation(.easeInOut) {
              showSearch = true
              searchFocused = true
            }
          }
          .disabled(taskStore.journalsLocked)
        }

        ToolbarItem(placement: .topBarTrailing) {
          Button {
            toggleLock()
          } label: {
            Image(systemName: taskStore.journalsLocked ? "lock.fill" : "lock.open")
          }
        }

        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        ToolbarItem(placement: .topBarTrailing) {
          Button("Settings", systemImage: "gearshape") {
            showingSettings = true
          }
        }
      }
      .onChange(of: taskStore.addJournalTrigger) { _, newValue in
        if newValue && !taskStore.journalsLocked {
          addNewEntry()
          taskStore.addJournalTrigger = false
        }
      }
      .navigationDestination(for: JournalEntry.self) { entry in
        JournalEntryView(entry: entry)
          .toolbar(.hidden, for: .tabBar)
      }
      .navigationDestination(for: String.self) { destination in
        switch destination {
        case "allJournals":
          AllJournalsView()
            .toolbar(.hidden, for: .tabBar)
        case "deletedJournals":
          DeletedJournalView()
            .toolbar(.hidden, for: .tabBar)
        default:
          EmptyView()
        }
      }
      .sheet(isPresented: $showingSettings) {
        SettingsView()
      }
    }
  }

  // MARK: - Main Content

  private var mainContent: some View {
    ScrollView(showsIndicators: false) {
      VStack(spacing: 16) {
        if !searchText.isEmpty {
          searchResultsView
        } else {
          // Stats Section
          statsSection

          // Journals Section
          journalsSection

          // Recent Entries Section
          recentEntriesSection
        }
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 100)
    }
  }

  // MARK: - Stats Section

  private var statsSection: some View {
    VStack(spacing: 12) {
      // GitHub-style activity chart
      JournalActivityCard(
        entries: taskStore.journalEntries,
        selectedPeriod: $selectedInsightsPeriod
      )

      // Streak card
      JournalStreakCard(streak: currentStreak)
    }
  }

  // MARK: - Journals Section

  private var journalsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Button {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
          journalsExpanded.toggle()
        }
      } label: {
        HStack {
          Text("Journals")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.primary)

          Image(systemName: journalsExpanded ? "chevron.down" : "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.secondary)
            .contentTransition(.symbolEffect(.replace))

          Spacer()
        }
        .padding(.horizontal, 4)
      }
      .buttonStyle(.plain)

      if journalsExpanded {
        VStack(spacing: 8) {
          // All Journals Row
          journalListRow(
            icon: "book.fill",
            iconColor: Theme.tint,
            title: "All Journals",
            count: taskStore.journalEntries.count,
            destination: "allJournals"
          )

          // Recently Deleted Row
          journalListRow(
            icon: "trash",
            iconColor: .gray,
            title: "Recently Deleted",
            count: taskStore.deletedJournalEntries.count,
            destination: "deletedJournals"
          )
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
  }

  private func journalListRow(
    icon: String, iconColor: Color, title: String, count: Int, destination: String
  ) -> some View {
    Button {
      navigationPath.append(destination)
    } label: {
      HStack(spacing: 12) {
        Image(systemName: icon)
          .font(.system(size: 18, weight: .semibold))
          .foregroundStyle(iconColor)

        Text(title)
          .font(.system(size: 16, weight: .medium))
          .foregroundStyle(.primary)

        Spacer()

        if count > 0 {
          Text("\(count)")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.secondary)
        }

        Image(systemName: "chevron.right")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.tertiary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .glassEffect(.regular)
    }
    .buttonStyle(.plain)
  }

  // MARK: - Recent Entries Section

  private var recentEntriesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Button {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
          recentEntriesExpanded.toggle()
        }
      } label: {
        HStack {
          Text("Recent Entries")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.primary)

          Image(systemName: recentEntriesExpanded ? "chevron.down" : "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.secondary)
            .contentTransition(.symbolEffect(.replace))

          Spacer()
        }
        .padding(.horizontal, 4)
      }
      .buttonStyle(.plain)

      if recentEntriesExpanded {
        if recentEntries.isEmpty {
          VStack(spacing: 12) {
            Image(systemName: "book.closed")
              .font(.system(size: 36))
              .foregroundStyle(.secondary)
            Text("No journal entries yet")
              .font(.system(size: 15))
              .foregroundStyle(.secondary)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 32)
        } else {
          VStack(spacing: 8) {
            ForEach(recentEntries) { entry in
              Button {
                navigationPath.append(entry)
              } label: {
                JournalEntryRow(entry: entry)
              }
              .buttonStyle(.plain)
              .contextMenu {
                Button(role: .destructive) {
                  withAnimation { taskStore.deleteJournalEntry(entry) }
                } label: {
                  Label("Delete", systemImage: "trash")
                }
              }
            }
          }
          .transition(.opacity.combined(with: .move(edge: .top)))
        }
      }
    }
  }

  // MARK: - Search Results

  private var searchResultsView: some View {
    VStack(spacing: 8) {
      ForEach(filteredEntries) { entry in
        Button {
          navigationPath.append(entry)
        } label: {
          JournalEntryRow(entry: entry)
        }
        .buttonStyle(.plain)
      }
    }
  }

  // MARK: - Locked State

  private var lockedStateView: some View {
    VStack(spacing: 24) {
      Spacer()

      Image(systemName: "lock.fill")
        .font(.system(size: 64))
        .foregroundStyle(Theme.secondary.opacity(0.6))

      Text("Journals Locked")
        .font(.system(size: 24, weight: .bold))
        .foregroundStyle(Theme.primary)

      Text("Use Face ID to unlock your journals")
        .font(.system(size: 15))
        .foregroundStyle(Theme.secondary)
        .multilineTextAlignment(.center)

      Button {
        authenticateToUnlock()
      } label: {
        Label("Unlock with Face ID", systemImage: "faceid")
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.white)
          .padding(.horizontal, 24)
          .padding(.vertical, 14)
          .background(Theme.tint)
          .clipShape(Capsule())
      }
      .padding(.top, 8)

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Empty State

  private var emptyState: some View {
    VStack(spacing: 16) {
      Spacer()
      Image(systemName: "book.closed.fill")
        .font(.system(size: 48))
        .foregroundStyle(Theme.secondary.opacity(0.4))
      Text("Start your journal")
        .font(.system(size: 18, weight: .semibold))
        .foregroundStyle(Theme.primary)
      Text("Capture your thoughts, ideas, and memories.")
        .font(.system(size: 14))
        .foregroundStyle(Theme.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  // MARK: - Actions

  private func addNewEntry() {
    let newEntry = JournalEntry(title: "", body: "", date: Date())
    taskStore.addJournalEntry(newEntry)
    withAnimation {
      navigationPath.append(newEntry)
    }
  }

  private func toggleLock() {
    if taskStore.journalsLocked {
      authenticateToUnlock()
    } else {
      // Lock immediately without authentication
      withAnimation {
        taskStore.journalsLocked = true
      }
    }
  }

  private func authenticateToUnlock() {
    let context = LAContext()
    var error: NSError?

    guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
      // No authentication available, just unlock
      withAnimation {
        taskStore.journalsLocked = false
      }
      return
    }

    let policy: LAPolicy =
      context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
      ? .deviceOwnerAuthenticationWithBiometrics
      : .deviceOwnerAuthentication

    context.evaluatePolicy(
      policy,
      localizedReason: "Unlock your journals"
    ) { success, _ in
      DispatchQueue.main.async {
        if success {
          withAnimation {
            taskStore.journalsLocked = false
          }
        }
      }
    }
  }

  // MARK: - Helpers

  private func calculateStreak() -> Int {
    let sortedDates = taskStore.journalEntries.map { $0.date }.sorted(by: >)
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
