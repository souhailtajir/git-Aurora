//
//  UserProfileStore.swift
//  Aurora
//
//  Created by souhail on 12/18/25.
//

import Foundation
import SwiftUI

@Observable
class UserProfileStore {
    private static let userProfileKey = "userProfile"
    
    var profile: UserProfile {
        didSet {
            saveProfile()
        }
    }
    
    init() {
        self.profile = UserProfileStore.loadProfile()
    }
    
    private static func loadProfile() -> UserProfile {
        guard let data = UserDefaults.standard.data(forKey: userProfileKey),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return .default
        }
        return profile
    }
    
    private func saveProfile() {
        guard let data = try? JSONEncoder().encode(profile) else { return }
        UserDefaults.standard.set(data, forKey: UserProfileStore.userProfileKey)
    }
    
    func updateBirthDate(_ date: Date?) {
        profile.birthDate = date
    }
    
    func updateName(_ name: String) {
        profile.name = name
    }
    
    func updateEmail(_ email: String) {
        profile.email = email
    }
    
    func updateCelestialDisplayMode(_ mode: CelestialDisplayMode) {
        profile.celestialDisplayMode = mode
    }
}
