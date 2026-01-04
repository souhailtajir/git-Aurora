//
//  JournalView.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//  Redesigned to match TasksView UI/UX patterns
//

import SwiftUI

struct JournalView: View {
  @Environment(TaskStore.self) var taskStore
  @State private var searchText = ""
  @State private var isSearching = false
  @State private var showingSettings = false
  @State private var navigationPath = NavigationPath()
  @State private var recentEntriesExpanded = true

  // Purple accent
  private let purpleAccent = Color(red: 0.6, green: 0.4, blue: 0.9)

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
      ScrollView {
        VStack(spacing: 16) {
          if !searchText.isEmpty {
            searchResultsView
          } else {
            mainContentView
          }
        }
        .padding(.horizontal, 16)
      }
      .scrollIndicators(.hidden)
      .background(Color.clear.auroraBackground())
      .navigationTitle("Journal")
      .toolbarTitleDisplayMode(.inlineLarge)
      .safeAreaPadding(.top, 8)
      .safeAreaInset(edge: .bottom) {
        if isSearching {
          BottomSearchBar(
            text: $searchText, isSearching: $isSearching, placeholder: "Search journals..."
          )
          .transition(.move(edge: .bottom).combined(with: .opacity))
        }
      }
      .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSearching)
      .toolbar {
        ToolbarItemGroup(placement: .topBarTrailing) {
          Button("Search", systemImage: "magnifyingglass") {
            withAnimation {
              isSearching = true
            }
          }
        }

        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            Button {
              navigationPath.append(JournalDestination.allJournals)
            } label: {
              Label("All Journals", systemImage: "books.vertical")
            }

            Button {
              navigationPath.append(JournalDestination.recentlyDeleted)
            } label: {
              Label("Recently Deleted", systemImage: "trash")
            }
          } label: {
            Image(systemName: "ellipsis")
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
        if newValue {
          addNewEntry()
          taskStore.addJournalTrigger = false
        }
      }
      .navigationDestination(for: JournalEntry.self) { entry in
        JournalEntryView(
          entry: Binding(
            get: { taskStore.journalEntries.first { $0.id == entry.id } ?? entry },
            set: { updatedEntry in
              if let index = taskStore.journalEntries.firstIndex(where: { $0.id == entry.id }) {
                taskStore.journalEntries[index] = updatedEntry
              }
            }
          )
        )
      }
      .navigationDestination(for: JournalDestination.self) { destination in
        switch destination {
        case .allJournals:
          AllJournalsView()
        case .recentlyDeleted:
          DeletedJournalView()
        }
      }
      .sheet(isPresented: $showingSettings) {
        SettingsView()
      }
    }
  }

  // MARK: - Main Content

  private var mainContentView: some View {
    VStack(spacing: 20) {
      statsCardsGrid
      journalActionsSection
      recentEntriesSection
    }
  }

  // MARK: - Stats Cards Grid (like SmartListCards)

  private var statsCardsGrid: some View {
    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
      // Entries This Year Card
      JournalStatCard(
        icon: "book.fill",
        iconColor: purpleAccent,
        count: entriesThisYear,
        title: "This Year"
      )

      // Streak Card
      JournalStatCard(
        icon: "flame.fill",
        iconColor: .orange,
        count: currentStreak,
        title: "Day Streak"
      )
    }
  }

  // MARK: - Journal Actions Section

  private var journalActionsSection: some View {
    VStack(spacing: 8) {
      // All Journals row
      Button {
        navigationPath.append(JournalDestination.allJournals)
      } label: {
        HStack(spacing: 12) {
          Image(systemName: "books.vertical.fill")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(purpleAccent)

          Text("All Journals")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.primary)

          Spacer()

          Text("\(taskStore.journalEntries.count)")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.secondary)

          Image(systemName: "chevron.right")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .glassEffect(.regular)
      }
      .buttonStyle(.plain)

      // Recently Deleted row
      Button {
        navigationPath.append(JournalDestination.recentlyDeleted)
      } label: {
        HStack(spacing: 12) {
          Image(systemName: "trash")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.gray)

          Text("Recently Deleted")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.primary)

          Spacer()

          if taskStore.deletedJournalEntries.count > 0 {
            Text("\(taskStore.deletedJournalEntries.count)")
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
  }

  // MARK: - Recent Entries Section (like My Lists)

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
        if taskStore.journalEntries.isEmpty {
          emptyStateView
        } else {
          VStack(spacing: 8) {
            ForEach(filteredEntries.prefix(5)) { entry in
              journalEntryRow(for: entry)
            }
          }
          .transition(.opacity.combined(with: .move(edge: .top)))
        }
      }
    }
  }

  private func journalEntryRow(for entry: JournalEntry) -> some View {
    Button {
      navigationPath.append(entry)
    } label: {
      HStack(spacing: 12) {
        // Color indicator
        RoundedRectangle(cornerRadius: 2)
          .fill(purpleAccent)
          .frame(width: 4, height: 36)

        VStack(alignment: .leading, spacing: 4) {
          Text(entry.title.isEmpty ? "Untitled" : entry.title)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.primary)
            .lineLimit(1)

          Text(entry.date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
            .font(.system(size: 13))
            .foregroundStyle(.secondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(.tertiary)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 14)
      .glassEffect(.regular)
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

  // MARK: - Empty State

  private var emptyStateView: some View {
    VStack(spacing: 16) {
      Image(systemName: "book.closed.fill")
        .font(.system(size: 40))
        .foregroundStyle(purpleAccent.opacity(0.5))

      Text("No journal entries yet")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(.secondary)

      Text("Tap + to start writing")
        .font(.system(size: 14))
        .foregroundStyle(.tertiary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
  }

  // MARK: - Search Results

  private var searchResultsView: some View {
    VStack(spacing: 8) {
      if filteredEntries.isEmpty {
        VStack(spacing: 12) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 36))
            .foregroundStyle(.secondary)
          Text("No results found")
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
          Text("Try a different search term")
            .font(.system(size: 13))
            .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
      } else {
        ForEach(filteredEntries) { entry in
          journalEntryRow(for: entry)
        }
      }
    }
  }

  // MARK: - Helpers

  private func addNewEntry() {
    let newEntry = JournalEntry(title: "", body: "", date: Date())
    taskStore.addJournalEntry(newEntry)
    navigationPath.append(newEntry)
  }

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

// MARK: - Navigation Destination Enum

enum JournalDestination: Hashable {
  case allJournals
  case recentlyDeleted
}

// MARK: - Journal Stat Card (like SmartListCard)

struct JournalStatCard: View {
  let icon: String
  let iconColor: Color
  let count: Int
  let title: String

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        Image(systemName: icon)
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(iconColor)

        Spacer()

        Text("\(count)")
          .font(.system(size: 24, weight: .bold))
          .foregroundStyle(iconColor)
      }

      Spacer()

      Text(title)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(.primary)
        .lineLimit(1)
    }
    .padding(16)
    .frame(height: 90)
    .frame(maxWidth: .infinity, alignment: .leading)
    .glassEffect(.clear.tint(iconColor.opacity(0.3)))
  }
}
