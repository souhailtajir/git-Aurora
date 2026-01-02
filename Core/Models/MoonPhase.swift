//
//  MoonPhase.swift
//  Aurora
//
//  Created by souhail on 12/19/25.
//

import Foundation

enum MoonPhase: String, CaseIterable {
    case newMoon = "New Moon"
    case waxingCrescent = "Waxing Crescent"
    case firstQuarter = "First Quarter"
    case waxingGibbous = "Waxing Gibbous"
    case fullMoon = "Full Moon"
    case waningGibbous = "Waning Gibbous"
    case lastQuarter = "Last Quarter"
    case waningCrescent = "Waning Crescent"
    
    // Detailed moon info struct
    struct MoonInfo {
        let phase: MoonPhase
        let illumination: Double
        let age: Double // Days since new moon
    }
    
    static func getInfo(for date: Date = Date()) -> MoonInfo {
        // Julian Date calculation
        let time = date.timeIntervalSince1970
        let jd = (time / 86400.0) + 2440587.5
        
        // Calculate moon's age (days since new moon)
        // Known new moon: January 6, 2000
        let knownNewMoon = 2451550.1
        let lunarCycle = 29.530588853
        
        let daysSinceKnownNew = jd - knownNewMoon
        let cyclesSince = daysSinceKnownNew / lunarCycle
        let age = (cyclesSince - floor(cyclesSince)) * lunarCycle
        
        // Determine phase (8 phases, each ~3.69 days)
        let phaseLength = lunarCycle / 8.0
        let phaseIndex = Int(floor(age / phaseLength)) % 8
        
        let phase: MoonPhase
        switch phaseIndex {
        case 0: phase = .newMoon
        case 1: phase = .waxingCrescent
        case 2: phase = .firstQuarter
        case 3: phase = .waxingGibbous
        case 4: phase = .fullMoon
        case 5: phase = .waningGibbous
        case 6: phase = .lastQuarter
        case 7: phase = .waningCrescent
        default: phase = .newMoon
        }
        
        // Calculate illumination (0-100%)
        // Age 0 = New Moon (0%), Age ~14.76 = Full Moon (100%)
        let normalizedAge = age / lunarCycle // 0 to 1
        let phaseAngle = normalizedAge * 2.0 * .pi
        let illumination = (1.0 - cos(phaseAngle)) / 2.0 * 100.0
        
        return MoonInfo(phase: phase, illumination: illumination, age: age)
    }
    
    // Backward compatibility helpers
    static func current(for date: Date = Date()) -> MoonPhase {
        return getInfo(for: date).phase
    }
    
    static func illumination(for date: Date = Date()) -> Double {
        return getInfo(for: date).illumination
    }
    
    var symbol: String {
        switch self {
        case .newMoon: return "🌑"
        case .waxingCrescent: return "🌒"
        case .firstQuarter: return "🌓"
        case .waxingGibbous: return "🌔"
        case .fullMoon: return "🌕"
        case .waningGibbous: return "🌖"
        case .lastQuarter: return "🌗"
        case .waningCrescent: return "🌘"
        }
    }
}

enum CelestialDisplayMode: String, Codable {
    case zodiacPlanet = "Zodiac Planet"
    case moonPhase = "Moon Phase"
}
