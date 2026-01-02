//
//  JournalEntryView.swift
//  Aurora
//
//  Created by souhail on 1/2/26.
//

import JournalingSuggestions
import PhotosUI
import SwiftUI

struct JournalEntryView: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss

  let entry: JournalEntry

  @State private var title: String
  @State private var bodyText: String
  @State private var theme: JournalTheme
  @State private var images: [Data]

  @State private var showPhotoPicker = false
  @State private var selectedPhotoItem: PhotosPickerItem?
  @State private var showCamera = false
  @State private var showSuggestionsPicker = false
  @FocusState private var isFocused: Bool

  init(entry: JournalEntry) {
    self.entry = entry
    _title = State(initialValue: entry.title)
    _bodyText = State(initialValue: entry.body)
    _theme = State(initialValue: entry.theme)
    _images = State(initialValue: entry.images)
  }

  var body: some View {
    ZStack {
      backgroundForTheme
        .ignoresSafeArea()

      VStack(spacing: 0) {
        editorContent
        bottomToolbar
      }
    }
    .navigationBarBackButtonHidden(true)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Button {
          saveAndDismiss()
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "chevron.left")
              .font(.system(size: 16, weight: .semibold))
            Text("Journal")
              .font(.system(size: 17))
          }
          .foregroundStyle(theme.textColor)
        }
      }

      ToolbarItemGroup(placement: .topBarTrailing) {
        Button {
          // Text formatting placeholder
        } label: {
          Text("Aa")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(theme.textColor)
        }

        Menu {
          ForEach(JournalTheme.allCases, id: \.self) { themeOption in
            Button {
              withAnimation(.spring(response: 0.3)) {
                theme = themeOption
                saveEntry()
              }
            } label: {
              HStack {
                Text(themeOption.rawValue)
                if theme == themeOption {
                  Image(systemName: "checkmark")
                }
              }
            }
          }
        } label: {
          Image(systemName: "paintpalette.fill")
            .font(.system(size: 17))
            .foregroundStyle(theme.textColor)
        }

        Menu {
          Button("Share") {}
          Button(role: .destructive) {
            taskStore.deleteJournalEntry(entry)
            dismiss()
          } label: {
            Label("Delete", systemImage: "trash")
          }
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(theme.textColor)
        }
      }
    }
    .toolbarBackground(.hidden, for: .navigationBar)
    .onAppear { isFocused = true }
    .onDisappear { saveEntry() }
    .fullScreenCover(isPresented: $showCamera) {
      CameraPickerView(isPresented: $showCamera) { image in
        if let data = image.jpegData(compressionQuality: 0.8) {
          images.append(data)
          saveEntry()
        }
      }
      .ignoresSafeArea()
    }
  }

  // MARK: - Editor Content

  private var editorContent: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        // Title
        TextField("Title", text: $title)
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(theme.textColor)
          .submitLabel(.next)
          .onChange(of: title) { _, _ in saveEntry() }

        // Body
        ZStack(alignment: .topLeading) {
          if bodyText.isEmpty {
            Text("Start writing...")
              .font(.system(size: 17))
              .foregroundStyle(theme.textColor.opacity(0.4))
              .padding(.top, 8)
          }

          TextEditor(text: $bodyText)
            .font(.system(size: 17))
            .foregroundStyle(theme.textColor)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 300)
            .focused($isFocused)
            .onChange(of: bodyText) { _, _ in saveEntry() }
        }

        // Images
        if !images.isEmpty {
          LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
            ForEach(Array(images.enumerated()), id: \.offset) { _, imageData in
              if let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                  .resizable()
                  .scaledToFill()
                  .frame(width: 100, height: 100)
                  .clipShape(RoundedRectangle(cornerRadius: 16))
              }
            }
          }
        }
      }
      .padding(.horizontal, 24)
      .padding(.top, 8)
    }
  }

  // MARK: - Bottom Toolbar

  private var bottomToolbar: some View {
    HStack(spacing: 0) {
      Spacer()

      HStack(spacing: 24) {
        // Magic wand (Suggestions)
        Button {
          showSuggestionsPicker = true
        } label: {
          Image(systemName: "wand.and.stars")
            .font(.system(size: 22))
            .foregroundStyle(theme.textColor)
        }
        .journalingSuggestionsPicker(isPresented: $showSuggestionsPicker) { suggestion in
          AsyncTask {
            await handleSuggestion(suggestion)
          }
        }

        // Gallery
        Button {
          showPhotoPicker = true
        } label: {
          Image(systemName: "photo.on.rectangle")
            .font(.system(size: 22))
            .foregroundStyle(theme.textColor)
        }
        .photosPicker(
          isPresented: $showPhotoPicker,
          selection: $selectedPhotoItem,
          matching: .images
        )
        .onChange(of: selectedPhotoItem) { _, newItem in
          if let item = newItem {
            AsyncTask {
              if let data = try? await item.loadTransferable(type: Data.self) {
                images.append(data)
                saveEntry()
                selectedPhotoItem = nil
              }
            }
          }
        }

        // Camera
        Button {
          showCamera = true
        } label: {
          Image(systemName: "camera")
            .font(.system(size: 22))
            .foregroundStyle(theme.textColor)
        }

        // Audio (placeholder)
        Button {
        } label: {
          Image(systemName: "waveform")
            .font(.system(size: 22))
            .foregroundStyle(theme.textColor.opacity(0.5))
        }
        .disabled(true)

        // Location (placeholder)
        Button {
        } label: {
          Image(systemName: "location")
            .font(.system(size: 22))
            .foregroundStyle(theme.textColor.opacity(0.5))
        }
        .disabled(true)
      }
      .padding(.horizontal, 24)
      .padding(.vertical, 16)
      .background(
        Capsule()
          .fill(
            theme == .system || theme == .midnight || theme == .aurora
              ? Color.white.opacity(0.15)
              : Color.black.opacity(0.1)
          )
          .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: -4)
      )

      Spacer()
    }
    .padding(.bottom, 32)
  }

  // MARK: - Background

  @ViewBuilder
  private var backgroundForTheme: some View {
    switch theme {
    case .system:
      LinearGradient(
        colors: [Color.black, Color(hex: "1a1a1a")],
        startPoint: .top,
        endPoint: .bottom
      )
    case .oldPaper:
      Color(hex: "F4ECD8")
        .overlay {
          Image(systemName: "paperplane")
            .resizable()
            .foregroundStyle(.black.opacity(0.02))
            .rotationEffect(.degrees(15))
            .scaleEffect(2)
        }
    case .midnight:
      LinearGradient(
        colors: [Color.black, Color(hex: "0a0a0a")],
        startPoint: .top,
        endPoint: .bottom
      )
    case .aurora:
      ZStack {
        Color.black
        LinearGradient(
          colors: [
            Color(hex: "5B50A0").opacity(0.4),
            Color(hex: "2D1B69").opacity(0.2),
            .clear,
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      }
    }
  }

  // MARK: - Actions

  private func saveEntry() {
    var updatedEntry = entry
    updatedEntry.title = title
    updatedEntry.body = bodyText
    updatedEntry.theme = theme
    updatedEntry.images = images
    taskStore.updateJournalEntry(updatedEntry)
  }

  private func saveAndDismiss() {
    saveEntry()
    dismiss()
  }

  private func handleSuggestion(_ suggestion: JournalingSuggestion) async {
    title = suggestion.title
    saveEntry()
  }
}
