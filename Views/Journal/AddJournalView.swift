//
//  AddJournalView.swift
//  Aurora
//
//  Created by souhail on 12/4/25.
//

import SwiftUI

struct AddJournalView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(TaskStore.self) var taskStore
    
    @State private var title = ""
    @State private var bodyText = ""
    @State private var date = Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .font(.headline)
                    
                    DatePicker("Date", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section {
                    TextEditor(text: $bodyText)
                        .frame(minHeight: 200)
                        .font(.body)
                } header: {
                    Text("Entry")
                }
            }
            .navigationTitle("New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .disabled(title.isEmpty && bodyText.isEmpty)
                }
            }
        }
    }
    
    private func saveEntry() {
        let entry = JournalEntry(title: title.isEmpty ? "Untitled" : title, body: bodyText, date: date)
        taskStore.addJournalEntry(entry)
        dismiss()
    }
}

#Preview {
    AddJournalView()
        .environment(TaskStore())
}
