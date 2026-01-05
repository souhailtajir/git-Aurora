//
//  JournalLockService.swift
//  Aurora
//
//  FaceID authentication for journal locking
//

import LocalAuthentication
import SwiftUI

@MainActor
@Observable
final class JournalLockService {
  var isLocked = false

  func lock() {
    isLocked = true
  }

  func unlock() async -> Bool {
    let context = LAContext()
    var error: NSError?

    guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
      // Fallback: if no biometrics, just unlock
      isLocked = false
      return true
    }

    do {
      let success = try await context.evaluatePolicy(
        .deviceOwnerAuthenticationWithBiometrics,
        localizedReason: "Unlock your journal"
      )
      if success {
        isLocked = false
      }
      return success
    } catch {
      return false
    }
  }

  func toggleLock() async {
    if isLocked {
      _ = await unlock()
    } else {
      lock()
    }
  }
}
