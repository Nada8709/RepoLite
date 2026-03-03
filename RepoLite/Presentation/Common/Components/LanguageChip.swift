//
//  LanguageChip.swift
//  RepoLite
//
//  Created by Nada Ashraf on 03/03/2026.
//

import SwiftUI

struct LanguageChip: View {
    let language: String

    var body: some View {
        Text(language)
            .font(.caption2.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        switch language.lowercased() {
        case "swift":
            return .orange
        case "kotlin":
            return .purple
        case "python":
            return .blue
        case "javascript":
            return .yellow
        case "typescript":
            return .cyan
        case "go":
            return .teal
        case "rust":
            return Color(.systemBrown)
        case "java":
            return .red
        case "c++", "c":
            return Color(.systemIndigo)
        default:           return .gray
        }
    }
}
