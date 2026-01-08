//
//  JournalSuggestionsSheet.swift
//  Aurora
//

import SwiftUI

struct JournalSuggestionsSheet: View {
  @Environment(\.dismiss) private var dismiss
  var onSuggestionSelected: (String) -> Void

  private let suggestions: [(icon: String, title: String, prompt: String)] = [
    ("sun.horizon", "Morning Reflection", "How are you feeling this morning?"),
    ("heart.fill", "Gratitude", "List three things you're grateful for today."),
    ("brain.head.profile", "Mindfulness", "What thoughts are on your mind right now?"),
    ("star.fill", "Highlight", "What was the best moment of your day?"),
    ("moon.stars.fill", "Evening Reflection", "What went well today?"),
    ("lightbulb.fill", "Creative Spark", "Write about a recent idea or inspiration."),
  ]

  var body: some View {
    VStack(spacing: 0) {
      // Header
      HStack {
        Text("Writing Prompts")
          .font(.system(size: 18, weight: .semibold))
        Spacer()
        Button("Done") {
          dismiss()
        }
        .foregroundStyle(Theme.primary)
      }
      .padding(.horizontal, 20)
      .padding(.top, 20)
      .padding(.bottom, 16)

      // Prompts list
      ScrollView(showsIndicators: false) {
        VStack(spacing: 10) {
          ForEach(suggestions, id: \.title) { suggestion in
            Button {
              onSuggestionSelected(suggestion.prompt)
              dismiss()
            } label: {
              HStack(spacing: 14) {
                Image(systemName: suggestion.icon)
                  .font(.system(size: 20))
                  .foregroundStyle(Theme.primary)
                  .frame(width: 32)

                Text(suggestion.title)
                  .font(.system(size: 15, weight: .medium))
                  .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "plus")
                  .font(.system(size: 18))
                  .foregroundStyle(Theme.primary.opacity(0.6))
              }
              .padding(.horizontal, 14)
              .padding(.vertical, 12)
              .background {
                RoundedRectangle(cornerRadius: 12)
                      .glassEffect(.clear)
              }
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
      }
    }
    .presentationDetents([.height(380)])
    .presentationDragIndicator(.visible)
    .presentationCornerRadius(24)
  }
}
