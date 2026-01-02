//
//  InlineExpandedJournalRow.swift
//  Aurora
//
//  Created by souhail on 12/7/25.
//

import SwiftUI

struct InlineExpandedJournalRow: View {
    let entry: JournalEntry
    @Environment(TaskStore.self) var taskStore
    var onCollapse: () -> Void
    
    @State private var draftEntry: JournalEntry
    @State private var showDatePicker = false
    @FocusState private var isFocused: Bool
    
    init(entry: JournalEntry, onCollapse: @escaping () -> Void) {
        self.entry = entry
        self.onCollapse = onCollapse
        _draftEntry = State(initialValue: entry)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header: Date & Collapse
            HStack {
                Text(draftEntry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                
                Spacer()
                
                Button(action: onCollapse) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Theme.primary)
                        .background(Circle().fill(.white))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 10)
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                TextField("Title", text: $draftEntry.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Theme.primary)
                    .submitLabel(.next)
                
                TextEditor(text: $draftEntry.body)
                    .font(.body)
                    .foregroundStyle(Theme.primary.opacity(0.9))
                    .frame(minHeight: 150)
                    .scrollContentBackground(.hidden)
                    .focused($isFocused)
            }
            .padding(.horizontal, 20)
            
            // Toolbar (Apple Journal Style)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ToolbarButton(icon: "wand.and.stars")
                    ToolbarButton(icon: "photo")
                    ToolbarButton(icon: "camera")
                    ToolbarButton(icon: "mic")
                    ToolbarButton(icon: "location")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .onAppear {
            isFocused = true
        }
        .onChange(of: draftEntry.title) { taskStore.updateJournalEntry(draftEntry) }
        .onChange(of: draftEntry.body) { taskStore.updateJournalEntry(draftEntry) }
        .onChange(of: draftEntry.date) { taskStore.updateJournalEntry(draftEntry) }
    }
}

struct ToolbarButton: View {
    let icon: String
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Theme.secondary)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.secondary.opacity(0.1)))
        }
    }
}
