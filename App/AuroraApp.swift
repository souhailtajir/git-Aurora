//
//  AuroraApp.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//

import SwiftUI

@main
struct AuroraApp: App {
  @State private var taskStore = TaskStore()
  @State private var userProfileStore = UserProfileStore()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .environment(taskStore)
        .environment(userProfileStore)
        .preferredColorScheme(.dark)
    }
  }
}
