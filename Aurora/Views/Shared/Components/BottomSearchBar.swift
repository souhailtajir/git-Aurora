import SwiftUI

struct BottomSearchBar: View {
  @Binding var text: String
  @Binding var isSearching: Bool
  var placeholder: String = "Search"
  @FocusState private var isFocused: Bool

  // Aurora purple accent color
  private let purpleAccent = Color(red: 0.6, green: 0.4, blue: 0.9)

  var body: some View {
    HStack(spacing: 12) {
      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 18, weight: .medium))
          .foregroundStyle(purpleAccent)

        TextField(placeholder, text: $text)
          .font(.system(size: 17))
          .textFieldStyle(.plain)
          .focused($isFocused)
          .submitLabel(.search)
          .tint(purpleAccent)

        if text.isEmpty {
          Image(systemName: "mic.fill")
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
        } else {
          Button {
            text = ""
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.system(size: 16))
              .foregroundStyle(purpleAccent.opacity(0.7))
          }
          .buttonStyle(.plain)
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 12)
      .glassEffect(.regular)
      .clipShape(Capsule())

      if isSearching || !text.isEmpty {
        Button {
          dismissSearch()
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(purpleAccent)
        }
        .frame(width: 44, height: 44)
        .contentShape(Circle())
        .glassEffect(.regular)
        .clipShape(Circle())
        .transition(.move(edge: .trailing).combined(with: .opacity))
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .onAppear {
      if isSearching { isFocused = true }
    }
    .onChange(of: isSearching) { _, newValue in
      if newValue { isFocused = true }
    }
    .onChange(of: isFocused) { _, newValue in
      if newValue {
        withAnimation { isSearching = true }
      }
    }
  }

  private func dismissSearch() {
    // Dismiss keyboard first
    UIApplication.shared.sendAction(
      #selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)

    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
      text = ""
      isSearching = false
      isFocused = false
    }
  }
}

#Preview {
  ZStack(alignment: .bottom) {
    Color.blue
    BottomSearchBar(text: .constant(""), isSearching: .constant(true))
  }
}
