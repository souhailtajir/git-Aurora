import SwiftUI

struct BottomSearchBar: View {
  @Binding var text: String
  @Binding var isSearching: Bool
  var placeholder: String = "Search"
  @FocusState private var isFocused: Bool

  var body: some View {
    HStack(spacing: 12) {
      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass")
          .font(.system(size: 18))
          .foregroundStyle(.secondary)

        TextField(placeholder, text: $text)
          .font(.system(size: 17))
          .textFieldStyle(.plain)
          .focused($isFocused)
          .submitLabel(.search)

        if text.isEmpty {
          Image(systemName: "mic.fill")  // Mic when empty? Or always? Image shows it.
            .font(.system(size: 14))
            .foregroundStyle(.secondary)
        } else {
          Button {
            text = ""
          } label: {
            Image(systemName: "xmark.circle.fill")
              .foregroundStyle(.secondary)
          }
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 12)
      .glassEffect(.regular)
      .clipShape(Capsule())

      if isSearching || !text.isEmpty {
        Button {
          withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            text = ""
            isSearching = false
            isFocused = false
          }
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 16, weight: .semibold))  // The image shows an X, maybe circle?
          // Image shows (X) in a circle maybe? Or just X.
          // The image has a close button: (X) circle.
          // Let's use xmark.circle.fill style for the outside button if that matches?
          // Wait, standard iOS behavior is "Cancel" text.
          // The user image shows an `X` button to the right of the search bar.
          // It looks like a circle button with X.
        }
        .buttonStyle(.plain)
        .padding(10)
        .background(.ultraThinMaterial)
        .clipShape(Circle())
        .glassEffect(.regular)
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
}

#Preview {
  ZStack(alignment: .bottom) {
    Color.blue
    BottomSearchBar(text: .constant(""), isSearching: .constant(true))
  }
}
