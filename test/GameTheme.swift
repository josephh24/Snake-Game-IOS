//
//  GameTheme.swift
//  test
//
//  Created by jose pablo sanchez guillen on 21/11/25.
//

import SwiftUI

enum GameTheme: String, CaseIterable {
    case classic = "Clásico"
    case neon = "Neón"
    case pixel = "Pixel"

    var cellSize: CGFloat {
        switch self {
        case .classic, .neon: return 20
        case .pixel: return 28
        }
    }

    var backgroundColor: Color {
        switch self {
        case .classic: return .black
        case .neon: return Color(red: 0.02, green: 0.02, blue: 0.08)
        case .pixel: return Color(red: 0.10, green: 0.10, blue: 0.10)
        }
    }

    var gridLineColor: Color {
        switch self {
        case .classic: return .gray.opacity(0.20)
        case .neon: return .cyan.opacity(0.16)
        case .pixel: return .white.opacity(0.18)
        }
    }

    var snakeColor: Color {
        switch self {
        case .classic: return .green
        case .neon: return Color.cyan
        case .pixel: return Color.green.opacity(0.85)
        }
    }

    var foodColor: Color {
        switch self {
        case .classic: return .red
        case .neon: return .pink
        case .pixel: return .orange
        }
    }

    var hudTextColor: Color {
        switch self {
        case .classic:
            return .white
        case .neon:
            return .white
        case .pixel:
            return .white
        }
    }
}
