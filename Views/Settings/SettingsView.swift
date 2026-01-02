//
//  SettingsView.swift
//  Aurora
//
//  Created by souhail on 12/18/25.
//

import SwiftUI

struct SettingsView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment(UserProfileStore.self) private var userProfileStore
  @State private var showingBirthDatePicker = false
  @State private var showingAppearanceSettings = false
  @State private var showingNotificationSettings = false

  var body: some View {
    NavigationStack {
      ZStack {
        Theme.auroraBackground

        ScrollView(showsIndicators: false) {
          VStack(spacing: 24) {
            // Hero Profile Section
            HeroProfileView(
              profile: userProfileStore.profile,
              onEdit: { showingBirthDatePicker = true }
            )

            // Display Preferences
            SettingsSection(title: "Display") {
              VStack(spacing: 0) {
                PickerRow(
                  icon: "sparkles",
                  iconColor: .purple,
                  title: "Celestial Mode",
                  selection: Binding(
                    get: { userProfileStore.profile.celestialDisplayMode },
                    set: { userProfileStore.updateCelestialDisplayMode($0) }
                  )
                )
              }
            }

            // App Settings
            SettingsSection(title: "App Settings") {
              VStack(spacing: 0) {
                Button {
                  showingAppearanceSettings = true
                } label: {
                  SettingsRow(
                    icon: "paintbrush.fill",
                    iconColor: .blue,
                    title: "Appearance",
                    value: "System"
                  )
                }
                .buttonStyle(.plain)

                CustomDivider()

                Button {
                  showingNotificationSettings = true
                } label: {
                  SettingsRow(
                    icon: "bell.fill",
                    iconColor: .red,
                    title: "Notifications",
                    value: "Enabled"
                  )
                }
                .buttonStyle(.plain)
              }
            }

            // About
            SettingsSection(title: "About") {
              VStack(spacing: 0) {
                SettingsRow(
                  icon: "info.circle.fill",
                  iconColor: .gray,
                  title: "Version",
                  value: "1.0.0",
                  showChevron: false
                )

                CustomDivider()

                Button {
                  if let url = URL(string: "https://example.com/privacy") {
                    UIApplication.shared.open(url)
                  }
                } label: {
                  SettingsRow(
                    icon: "hand.raised.fill",
                    iconColor: .green,
                    title: "Privacy Policy",
                    value: ""
                  )
                }
                .buttonStyle(.plain)
              }
            }
          }
          .padding(.horizontal, 16)
          .padding(.top, 20)
          .padding(.bottom, 100)
        }
      }
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            dismiss()
          } label: {
            ZStack {
              Image(systemName: "xmark")
                    .foregroundStyle(Theme.primary)
            }
          }
        }
      }
      .sheet(isPresented: $showingBirthDatePicker) {
        BirthDatePickerView(
          userProfileStore: userProfileStore, isPresented: $showingBirthDatePicker)
      }
      .sheet(isPresented: $showingAppearanceSettings) {
        AppearanceSettingsView(isPresented: $showingAppearanceSettings)
      }
      .sheet(isPresented: $showingNotificationSettings) {
        NotificationSettingsView(isPresented: $showingNotificationSettings)
      }
    }
  }
}

// MARK: - Components

struct HeroProfileView: View {
  let profile: UserProfile
  let onEdit: () -> Void

  var body: some View {
    HStack(spacing: 20) {
      // Info Column
      VStack(alignment: .leading, spacing: 8) {
        VStack(alignment: .leading, spacing: 4) {
          Text(profile.name)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(.primary)

          Text(profile.email)
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }

        // Zodiac Info
        HStack(spacing: 6) {
          Image(systemName: profile.zodiacSign.symbol)
            .font(.system(size: 14))
            .foregroundStyle(Theme.primary)

          Text(
            "\(profile.zodiacSign.rawValue) • \(profile.birthDate?.formatted(.dateTime.day().month(.abbreviated)) ?? "Set Date")"
          )
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 10)
        .background(Theme.secondary.opacity(0.1))
        .clipShape(Capsule())

        Button(action: onEdit) {
          Text("Edit Profile")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.secondary)
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
      }

      Spacer()

      // Avatar
      Circle()
        .fill(
          LinearGradient(
            colors: [Theme.secondary, Theme.primary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .frame(width: 84, height: 84)
        .overlay(
          Text(profile.name.prefix(1))
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
        )
        .shadow(color: Theme.secondary.opacity(0.4), radius: 12, x: 0, y: 6)
    }
    .frame(maxWidth: .infinity)
    .padding(24)
    .background(.regularMaterial)  // Slightly stronger material for hero
    .clipShape(RoundedRectangle(cornerRadius: 24))
  }
}

struct SettingsSection<Content: View>: View {
  let title: String
  let content: Content

  init(title: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(.secondary)
        .textCase(.uppercase)
        .padding(.leading, 8)

      VStack(spacing: 0) {
        content
      }
      .padding(.vertical, 4)
      .background(.regularMaterial)  // Native-like background
      .clipShape(RoundedRectangle(cornerRadius: 16))
    }
  }
}

struct SettingsRow: View {
  let icon: String
  let iconColor: Color
  let title: String
  let value: String
  var showChevron: Bool = true

  var body: some View {
    HStack(spacing: 14) {
      // Icon Container
      ZStack {
        RoundedRectangle(cornerRadius: 8)
          .fill(iconColor)
          .frame(width: 32, height: 32)

        Image(systemName: icon)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.white)
      }

      Text(title)
        .font(.system(size: 16, weight: .regular))
        .foregroundStyle(.primary)

      Spacer()

      if !value.isEmpty {
        Text(value)
          .font(.system(size: 16))
          .foregroundStyle(.secondary)
      }

      if showChevron {
        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(.tertiary)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .contentShape(Rectangle())  // Better tap area
  }
}

struct PickerRow: View {
  let icon: String
  let iconColor: Color
  let title: String
  @Binding var selection: CelestialDisplayMode

  var body: some View {
    HStack(spacing: 14) {
      ZStack {
        RoundedRectangle(cornerRadius: 8)
          .fill(iconColor)
          .frame(width: 32, height: 32)

        Image(systemName: icon)
          .font(.system(size: 16, weight: .semibold))
          .foregroundStyle(.white)
      }

      Text(title)
        .font(.system(size: 16, weight: .regular))
        .foregroundStyle(.primary)

      Spacer()

      Picker("", selection: $selection) {
        Text("Planet").tag(CelestialDisplayMode.zodiacPlanet)
        Text("Moon").tag(CelestialDisplayMode.moonPhase)
      }
      .pickerStyle(.menu)  // Specific native look
      .tint(.secondary)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)  // Slightly less vertical padding for Picker alignment
  }
}

struct CustomDivider: View {
  var body: some View {
    Divider()
      .padding(.leading, 62)  // Aligns with text start
  }
}

// MARK: - Appearance Settings View

struct AppearanceSettingsView: View {
  @Binding var isPresented: Bool
  @State private var selectedAppearance = "System"

  var body: some View {
    NavigationStack {
      ZStack {
        Theme.auroraBackground

        List {
          Section {
            ForEach(["Light", "Dark", "System"], id: \.self) { option in
              Button {
                selectedAppearance = option
              } label: {
                HStack {
                  Text(option)
                    .foregroundStyle(.primary)
                  Spacer()
                  if selectedAppearance == option {
                    Image(systemName: "checkmark")
                      .foregroundStyle(Theme.secondary)
                  }
                }
              }
            }
          } header: {
            Text("Appearance Mode")
          }
        }
        .scrollContentBackground(.hidden)
      }
      .navigationTitle("Appearance")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            isPresented = false
          }
          .foregroundStyle(Theme.secondary)
        }
      }
    }
  }
}

// MARK: - Notification Settings View

struct NotificationSettingsView: View {
  @Binding var isPresented: Bool
  @State private var notificationsEnabled = true
  @State private var dailyReminders = true
  @State private var taskAlerts = true

  var body: some View {
    NavigationStack {
      ZStack {
        Theme.auroraBackground

        List {
          Section {
            Toggle("Enable Notifications", isOn: $notificationsEnabled)
          }

          Section {
            Toggle("Daily Reminders", isOn: $dailyReminders)
              .disabled(!notificationsEnabled)

            Toggle("Task Alerts", isOn: $taskAlerts)
              .disabled(!notificationsEnabled)
          } header: {
            Text("Notification Types")
          }
        }
        .scrollContentBackground(.hidden)
      }
      .navigationTitle("Notifications")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            isPresented = false
          }
          .foregroundStyle(Theme.secondary)
        }
      }
    }
  }
}

#Preview {
  SettingsView()
    .environment(UserProfileStore())
}
