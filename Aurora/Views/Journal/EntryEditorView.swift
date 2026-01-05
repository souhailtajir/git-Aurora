//
//  EntryEditorView.swift
//  Aurora
//

import PhotosUI
import SwiftUI

struct EntryEditorView: View {
  @Environment(TaskStore.self) var taskStore
  @Environment(\.dismiss) var dismiss
  let entryId: UUID

  @State private var title = ""
  @State private var entryBody = ""
  @State private var hasLoaded = false
  @State private var selectedPhoto: PhotosPickerItem?
  @FocusState private var titleFocused: Bool
  @FocusState private var bodyFocused: Bool

  private var entry: JournalEntry? {
    taskStore.journalEntries.first { $0.id == entryId }
  }

  var body: some View {
    Group {
      if entry != nil {
        editorContent
      } else {
        emptyState
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.clear.auroraBackground())
    .navigationBarBackButtonHidden(true)
    .toolbar(.hidden, for: .tabBar)
    .toolbar {
      ToolbarItemGroup(placement: .topBarLeading) {
        Button {
          dismiss()
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(.primary)
        }
        .glassEffect(.regular)
      }

      ToolbarItemGroup(placement: .principal) {
        HStack(spacing: 24) {
          Button {
            // Text formatting
          } label: {
            Text("Aa")
              .font(.system(size: 18, weight: .semibold))
              .foregroundStyle(.primary)
          }

          Button {
            // Style/theme
          } label: {
            Image(systemName: "circle")
              .font(.system(size: 18, weight: .medium))
              .foregroundStyle(.primary)
          }

          Button {
            // More options
          } label: {
            Image(systemName: "ellipsis")
              .font(.system(size: 18, weight: .medium))
              .foregroundStyle(.primary)
          }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .glassEffect(.regular)
        .clipShape(Capsule())
      }

      ToolbarItemGroup(placement: .topBarTrailing) {
        Button {
          dismiss()
        } label: {
          Image(systemName: "checkmark")
            .font(.system(size: 18, weight: .bold))
            .foregroundStyle(.white)
        }
        .glassEffect(.regular.tint(Theme.primary).interactive())
      }
    }
    .safeAreaInset(edge: .bottom) {
      bottomToolbar
    }
    .onAppear {
      loadEntry()
    }
  }

  // MARK: - Bottom Toolbar

  private var bottomToolbar: some View {
    HStack(spacing: 28) {
      Button {
        // AI writing suggestions
      } label: {
        Image(systemName: "sparkles")
          .font(.system(size: 22))
          .foregroundStyle(Theme.tint)
      }

      PhotosPicker(selection: $selectedPhoto, matching: .images) {
        Image(systemName: "photo.on.rectangle")
          .font(.system(size: 22))
          .foregroundStyle(Theme.tint)
      }
      .onChange(of: selectedPhoto) { _, newItem in
        if let item = newItem {
          loadPhoto(item)
        }
      }

      Button {
        // Camera
      } label: {
        Image(systemName: "camera")
          .font(.system(size: 22))
          .foregroundStyle(Theme.tint)
      }

      Button {
        // Voice recording
      } label: {
        Image(systemName: "waveform")
          .font(.system(size: 22))
          .foregroundStyle(Theme.tint)
      }

      Button {
        // Location
      } label: {
        Image(systemName: "location")
          .font(.system(size: 22))
          .foregroundStyle(Theme.tint)
      }

      Button {
        // More attachments
      } label: {
        Image(systemName: "wand.and.stars")
          .font(.system(size: 22))
          .foregroundStyle(Theme.tint)
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 10)
    .glassEffect(.regular)
    .clipShape(Capsule())
    .padding(.horizontal, 24)
    .padding(.bottom, 8)
  }

  // MARK: - Editor Content

  private var editorContent: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 12) {
        // Title field
        TextField("Title", text: $title)
          .font(.system(size: 22, weight: .medium))
          .foregroundStyle(.primary)
          .focused($titleFocused)
          .submitLabel(.next)
          .onSubmit { bodyFocused = true }
          .onChange(of: title) { _, _ in save() }

        Divider()
          .background(.secondary.opacity(0.3))

        // Body editor
        ZStack(alignment: .topLeading) {
          if entryBody.isEmpty {
            Text("Start writing...")
              .font(.system(size: 17))
              .foregroundStyle(.secondary.opacity(0.5))
              .padding(.top, 8)
          }

          TextEditor(text: $entryBody)
            .font(.system(size: 17))
            .foregroundStyle(.primary)
            .scrollContentBackground(.hidden)
            .frame(minHeight: 300)
            .focused($bodyFocused)
            .onChange(of: entryBody) { _, _ in save() }
        }

        // Images
        if let entry = entry, !entry.images.isEmpty {
          imagesGrid(entry.images)
        }

        Spacer(minLength: 100)
      }
      .padding(.horizontal, 20)
      .padding(.top, 16)
    }
  }

  // MARK: - Empty State

  private var emptyState: some View {
    VStack(spacing: 16) {
      Image(systemName: "doc.questionmark")
        .font(.system(size: 40))
        .foregroundStyle(.secondary)
      Text("Entry not found")
        .font(.system(size: 16))
        .foregroundStyle(.secondary)
    }
  }

  // MARK: - Images Grid

  private func imagesGrid(_ images: [Data]) -> some View {
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
      ForEach(Array(images.enumerated()), id: \.offset) { index, data in
        if let uiImage = UIImage(data: data) {
          ZStack(alignment: .topTrailing) {
            Image(uiImage: uiImage)
              .resizable()
              .scaledToFill()
              .frame(width: 80, height: 80)
              .clipShape(RoundedRectangle(cornerRadius: 10))

            Button {
              removeImage(at: index)
            } label: {
              Image(systemName: "xmark.circle.fill")
                .font(.system(size: 18))
                .symbolRenderingMode(.palette)
                .foregroundStyle(.white, .black.opacity(0.5))
            }
            .offset(x: 4, y: -4)
          }
        }
      }
    }
  }

  // MARK: - Actions

  private func loadEntry() {
    guard !hasLoaded, let entry = entry else { return }
    title = entry.title
    entryBody = entry.body
    hasLoaded = true

    if entry.title.isEmpty && entry.body.isEmpty {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
        titleFocused = true
      }
    }
  }

  private func save() {
    guard hasLoaded, var entry = entry else { return }
    entry.title = title
    entry.body = entryBody
    taskStore.updateJournalEntry(entry)
  }

  private func loadPhoto(_ item: PhotosPickerItem) {
    AsyncTask {
      if let data = try? await item.loadTransferable(type: Data.self) {
        guard var entry = entry else { return }
        entry.images.append(data)
        taskStore.updateJournalEntry(entry)
        selectedPhoto = nil
      }
    }
  }

  private func removeImage(at index: Int) {
    guard var entry = entry else { return }
    entry.images.remove(at: index)
    taskStore.updateJournalEntry(entry)
  }
}
