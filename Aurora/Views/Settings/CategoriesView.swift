//
//  CategoriesView.swift
//  Aurora
//
//  Created by souhail on 12/1/25.
//

import SwiftUI

struct CategoriesView: View {
    @Environment(TaskStore.self) var taskStore
    @Environment(\.dismiss) var dismiss
    @State private var showingAddCategory = false
    @State private var categoryToEdit: TaskCategory?
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(taskStore.categories) { category in
                    Button(action: {
                        categoryToEdit = category
                    }) {
                        HStack {
                            Circle()
                                .fill(Color(hex: category.colorHex))
                                .frame(width: 12, height: 12)
                            
                            Image(systemName: category.iconName)
                                .foregroundStyle(Theme.secondary)
                            
                            Text(category.name)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(Theme.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary.opacity(0.5))
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { indexSet in
                    for index in indexSet {
                        taskStore.deleteCategory(taskStore.categories[index])
                    }
                }
            }
            .navigationTitle("Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingAddCategory = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddCategory) {
                CategoryEditView()
            }
            .sheet(item: $categoryToEdit) { category in
                CategoryEditView(category: category)
            }
        }
    }
}

struct CategoryEditView: View {
    @Environment(TaskStore.self) var taskStore
    @Environment(\.dismiss) var dismiss
    
    var category: TaskCategory?
    
    @State private var name: String = ""
    @State private var color: Color = .blue
    @State private var icon: String = "tag.fill"
    
    let icons = ["tag.fill", "briefcase.fill", "cart.fill", "heart.fill", "star.fill", "flag.fill", "book.fill", "gamecontroller.fill", "tv.fill", "music.note"]
    
    init(category: TaskCategory? = nil) {
        self.category = category
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Category Name", text: $name)
                    ColorPicker("Color", selection: $color)
                }
                
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(icons, id: \.self) { iconName in
                            Image(systemName: iconName)
                                .font(.system(size: 24))
                                .foregroundStyle(icon == iconName ? Theme.primary : .secondary)
                                .frame(width: 44, height: 44)
                                .background(icon == iconName ? Theme.primary.opacity(0.1) : Color.clear)
                                .clipShape(Circle())
                                .onTapGesture {
                                    icon = iconName
                                }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(category == nil ? "New Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                if let category = category {
                    name = category.name
                    color = Color(hex: category.colorHex)
                    icon = category.iconName
                }
            }
        }
    }
    
    private func save() {
        let hex = color.toHex() ?? "#000000"
        
        if let category = category {
            var updated = category
            updated.name = name
            updated.colorHex = hex
            updated.iconName = icon
            taskStore.updateCategory(updated)
        } else {
            let newCategory = TaskCategory(name: name, colorHex: hex, iconName: icon)
            taskStore.addCategory(newCategory)
        }
        dismiss()
    }
}

extension Color {
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if a != Float(1.0) {
            return String(format: "#%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}

#Preview {
    CategoriesView()
}
