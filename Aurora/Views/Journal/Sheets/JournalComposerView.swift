//
//  JournalComposerView.swift
//  Aurora
//
//  Redesigned to match Apple Journal UI
//

import SwiftUI
import PhotosUI
import JournalingSuggestions

// Disambiguate Swift concurrency Task from our Task model
typealias AsyncTask = _Concurrency.Task

struct JournalComposerView: View {
    @Environment(TaskStore.self) var taskStore
    @Binding var entry: JournalEntry
    var onDismiss: () -> Void
    
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showSuggestionsPicker = false
    @State private var showTextFormatting = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            // Dynamic background based on theme
            backgroundForTheme
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                topToolbar
                editorContent
                bottomToolbar
            }
        }
        .onAppear { isFocused = true }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPickerView(isPresented: $showCamera) { image in
                if let data = image.jpegData(compressionQuality: 0.8) {
                    entry.images.append(data)
                    taskStore.updateJournalEntry(entry)
                }
            }
            .ignoresSafeArea()
        }
    }
    
    // MARK: - Top Toolbar (Apple Journal Style)
    private var topToolbar: some View {
        HStack(spacing: 16) {
            // Back button
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.2)))
            }
            
            Spacer()
            
            // Middle capsule: Text formatting + Theme + More
            HStack(spacing: 16) {
                Button(action: { showTextFormatting.toggle() }) {
                    Text("Aa")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                }
                
                Menu {
                    ForEach(JournalTheme.allCases, id: \.self) { theme in
                        Button(action: {
                            print("🎨 Changing theme to: \(theme.rawValue)")
                            withAnimation(.spring(response: 0.3)) {
                                entry.theme = theme
                            }
                            taskStore.updateJournalEntry(entry)
                        }) {
                            HStack {
                                Text(theme.rawValue)
                                if entry.theme == theme {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(.white)
                }
                
                Menu {
                    Button("Share") {}
                    Button("", role: .destructive) {}
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
            )
            
            Spacer()
            
            // Done button
            Button(action: onDismiss) {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.blue))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Editor Content
    private var editorContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Title
                TextField("Title", text: Binding(
                    get: { entry.title },
                    set: { newValue in
                        entry.title = newValue
                        taskStore.updateJournalEntry(entry)
                    }
                ))
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(entry.theme.textColor)
                .submitLabel(.next)
                
                // Body
                ZStack(alignment: .topLeading) {
                    if entry.body.isEmpty {
                        Text("Start writing...")
                            .font(.system(size: 17))
                            .foregroundStyle(entry.theme.textColor.opacity(0.4))
                            .padding(.top, 8)
                    }
                    
                    TextEditor(text: Binding(
                        get: { entry.body },
                        set: { newValue in
                            entry.body = newValue
                            taskStore.updateJournalEntry(entry)
                        }
                    ))
                    .font(.system(size: 17))
                    .foregroundStyle(entry.theme.textColor)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 300)
                    .focused($isFocused)
                }
                
                // Images
                if !entry.images.isEmpty {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                        ForEach(Array(entry.images.enumerated()), id: \.offset) { index, imageData in
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
    
    // MARK: - Bottom Toolbar (Capsule with all tools)
    private var bottomToolbar: some View {
        HStack(spacing: 0) {
            Spacer()
            
            HStack(spacing: 24) {
                // Magic wand (Suggestions)
                Button(action: {
                    print("✨ Opening suggestions picker")
                    showSuggestionsPicker = true
                }) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                }
                .journalingSuggestionsPicker(isPresented: $showSuggestionsPicker) { suggestion in
                    AsyncTask {
                        print("📝 Received suggestion: \(suggestion.title)")
                        await handleSuggestion(suggestion)
                    }
                }
                
                // Gallery
                Button(action: { 
                    print("🖼️ Opening photo picker")
                    showPhotoPicker = true 
                }) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                }
                .photosPicker(
                    isPresented: $showPhotoPicker,
                    selection: $selectedPhotoItem,
                    matching: .images
                )
                .onChange(of: selectedPhotoItem) { oldItem, newItem in
                    if let item = newItem {
                        AsyncTask {
                            print("📸 Processing selected photo")
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                entry.images.append(data)
                                taskStore.updateJournalEntry(entry)
                                selectedPhotoItem = nil
                                print("✅ Photo added successfully")
                            }
                        }
                    }
                }
                
                // Camera
                Button(action: { 
                    print("📷 Opening camera")
                    showCamera = true 
                }) {
                    Image(systemName: "camera")
                        .font(.system(size: 22))
                        .foregroundStyle(.white)
                }
                
                // Audio (placeholder)
                Button(action: {}) {
                    Image(systemName: "waveform")
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .disabled(true)
                
                // Location (placeholder)
                Button(action: {}) {
                    Image(systemName: "location")
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .disabled(true)
                
                // More options
                Button(action: {}) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white.opacity(0.5))
                }
                .disabled(true)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.15))
                    .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: -4)
            )
            
            Spacer()
        }
        .padding(.bottom, 32)
    }
    
    // MARK: - Background
    @ViewBuilder
    private var backgroundForTheme: some View {
        switch entry.theme {
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
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        }
    }
    
    // MARK: - Handlers
    private func handleSuggestion(_ suggestion: JournalingSuggestion) async {
        print("💡 Applying suggestion: \(suggestion.title)")
        entry.title = suggestion.title
        taskStore.updateJournalEntry(entry)
        print("✅ Suggestion applied successfully")
    }
}
