//
//  BottomSearchBar.swift
//  Aurora
//
//  Created by souhail on 1/3/26.
//

import SwiftUI

struct BottomSearchBar: View {
  @Binding var searchText: String
  @Binding var showSearch: Bool
  var placeholder: String = "Search"
  var focusState: FocusState<Bool>.Binding

  var body: some View {
    HStack(spacing: 12) {
      // Search Field
      HStack(spacing: 8) {
        Image(systemName: "magnifyingglass")
          .foregroundStyle(Theme.tint)

        TextField(placeholder, text: $searchText)
          .focused(focusState)
          .tint(Theme.tint)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .glassEffect(.regular)
      .clipShape(RoundedRectangle(cornerRadius: 16))

      // Cancel Button
      Button {
        withAnimation(.easeInOut) {
          searchText = ""
          showSearch = false
          focusState.wrappedValue = false
        }
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 20, weight: .semibold))
          .foregroundStyle(.primary)
          .frame(width: 42, height: 42)
          .glassEffect(.regular)
          .clipShape(Circle())
      }
    }
    .padding(.horizontal)
    .padding(.top, 8)
    .padding(.bottom, 10)
  }
}
