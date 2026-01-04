//
//  JournalEntryView.swift
//  Aurora
//
//  Navigation-based journal entry view
//

import PhotosUI
import SwiftUI

struct JournalEntryView: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss
  @Binding var entry: JournalEntry

  @State private var showPhotoPicker = false
  @State private var selectedPhotoItem: PhotosPickerItem?
  @State private var showCamera = false
  @FocusState private var titleFocused: Bool
  @FocusState private var bodyFocused: Bool

  private let purpleAccent = Color(red: 0.6, green: 0.4, blue: 0.9)

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 24) {
        // Title
        TextField(
          "Title",
          text: Binding(
            get: { entry.title },
            set: { newValue in
              entry.title = newValue
              saveEntry()
            }
          )
        )
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(.primary)
        .focused($titleFocused)
        .submitLabel(.next)
        .onSubmit { bodyFocused = true }

        // Body
        ZStack(alignment: .topLeading) {
          if entry.body.isEmpty {
            Text("Start writing...")
              .font(.system(size: 17))
              .foregroundStyle(.secondary.opacity(0.6))
              .padding(.top, 8)
          }

          TextEditor(
            text: Binding(
              get: { entry.body },
              set: { newValue in
                entry.body = newValue
                saveEntry()
              }
            )
          )
          .font(.system(size: 17))
          .foregroundStyle(.primary)
          .scrollContentBackground(.hidden)
          .frame(minHeight: 300)
          .focused($bodyFocused)
        }

        // Images
        if !entry.images.isEmpty {
          imagesGrid
        }

        Spacer(minLength: 120)
      }
      .padding(.horizontal, 20)
      .padding(.top, 16)
    }
    .background(Color.clear.auroraBackground())
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar(.hidden, for: .tabBar)
    .safeAreaInset(edge: .bottom) {
      bottomToolbar
    }
    .toolbar {
      ToolbarItem(placement: .principal) {
        Text(entry.date.formatted(.dateTime.month(.abbreviated).day().year()))
          .font(.system(size: 15, weight: .medium))
          .foregroundStyle(.secondary)
      }

      ToolbarItemGroup(placement: .topBarTrailing) {
        Menu {
          ForEach(JournalTheme.allCases, id: \.self) { theme in
            Button {
              entry.theme = theme
              saveEntry()
            } label: {
              HStack {
                Text(theme.rawValue)
                if entry.theme == theme {
                  Image(systemName: "checkmark")
                }
              }
            }
          }
        } label: {
          Image(systemName: "paintpalette")
            .font(.system(size: 16))
        }
      }
    }
    .onAppear {
      if entry.title.isEmpty && entry.body.isEmpty {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
          titleFocused = true
        }
      }
    }
    .fullScreenCover(isPresented: $showCamera) {
      CameraPickerView(isPresented: $showCamera) { image in
        if let data = image.jpegData(compressionQuality: 0.8) {
          entry.images.append(data)
          saveEntry()
        }
      }
      .ignoresSafeArea()
    }
  }

  // MARK: - Images Grid

  private var imagesGrid: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Photos")
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(.secondary)

      LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
        ForEach(Array(entry.images.enumerated()), id: \.offset) { index, imageData in
          if let uiImage = UIImage(data: imageData) {
            ZStack(alignment: .topTrailing) {
              Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 90, height: 90)
                .clipShape(RoundedRectangle(cornerRadius: 12))

              Button {
                withAnimation {
                  entry.images.remove(at: index)
                  saveEntry()
                }
              } label: {
                Image(systemName: "xmark.circle.fill")
                  .font(.system(size: 18))
                  .symbolRenderingMode(.palette)
                  .foregroundStyle(.white, .black.opacity(0.6))
              }
              .offset(x: 6, y: -6)
            }
          }
        }
      }
    }
  }

  // MARK: - Bottom Toolbar

  private var bottomToolbar: some View {
    HStack {
      Spacer()

      HStack(spacing: 20) {
        // Photo picker
        Button {
          showPhotoPicker = true
        } label: {
          Image(systemName: "photo")
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(purpleAccent)
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
                entry.images.append(data)
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
            .font(.system(size: 18, weight: .medium))
            .foregroundStyle(purpleAccent)
        }

        Divider()
          .frame(height: 20)

        // Word count
        Text("\(wordCount) words")
          .font(.system(size: 13, weight: .medium))
          .foregroundStyle(.secondary)
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
      .glassEffect(.regular)
      .clipShape(Capsule())

      Spacer()
    }
    .padding(.bottom, 12)
  }

  // MARK: - Helpers

  private func saveEntry() {
    taskStore.updateJournalEntry(entry)
  }

  private var wordCount: Int {
    let words = entry.body.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
    return words.count
  }
}
