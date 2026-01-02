//
//  UserProfile.swift
//  Aurora
//
//  Created by souhail on 12/18/25.
//

import Foundation

struct UserProfile: Codable {
    var name: String
    var email: String
    var birthDate: Date?
    var celestialDisplayMode: CelestialDisplayMode
    
    /// Computed zodiac sign based on birth date
    var zodiacSign: ZodiacSign {
        guard let birthDate = birthDate else {
            return .aries // Default to Aries if no birth date
        }
        return ZodiacSign.from(birthDate: birthDate)
    }
    
    /// Ruling planet based on zodiac sign
    var rulingPlanet: Planet {
        zodiacSign.rulingPlanet
    }
    
    /// Default profile
    static let `default` = UserProfile(
        name: "User",
        email: "user@example.com",
        birthDate: nil,
        celestialDisplayMode: .zodiacPlanet
    )
}
