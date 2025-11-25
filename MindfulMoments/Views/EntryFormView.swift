import SwiftUI
import SwiftData

struct EntryFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: EntryFormViewModel

    init(entryToEdit: Entry?) {
        _viewModel = StateObject(wrappedValue: EntryFormViewModel(entryToEdit: entryToEdit))
    }

    var body: some View {
        Form {
            Section {
                DatePicker(
                    "Date",
                    selection: $viewModel.date,
                    displayedComponents: [.date, .hourAndMinute]
                )
            }

            // Category section
            Section("Category") {
                Picker("Category", selection: $viewModel.category) {
                    ForEach(viewModel.categoryOptions, id: \.self) { cat in
                        Text(cat).tag(cat)
                    }
                }
            }

            Section("Mood") {
                HStack {
                    ForEach(viewModel.moodOptions, id: \.self) { mood in
                        Button {
                            viewModel.mood = mood
                        } label: {
                            Text(mood)
                                .font(.largeTitle)
                                .padding(4)
                                .background(
                                    viewModel.mood == mood
                                    ? Color.accentColor.opacity(0.2)
                                    : Color.clear
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Reflection") {
                VStack(alignment: .leading, spacing: 8) {

                    if let prompt = viewModel.currentPrompt {
                        Text(prompt)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }

                    HStack {
                        Button {
                            viewModel.pickRandomPrompt()
                        } label: {
                            Label("New prompt", systemImage: "sparkles")
                        }
                        .buttonStyle(.borderless)

                        Button {
                            viewModel.insertCurrentPromptIntoContent()
                        } label: {
                            Label("Use prompt", systemImage: "text.badge.plus")
                        }
                        .buttonStyle(.borderless)
                        .disabled(viewModel.currentPrompt == nil)
                    }

                    TextEditor(text: $viewModel.content)
                        .frame(minHeight: 150)
                }
            }
        }
        .navigationTitle(viewModel.title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    do {
                        try viewModel.save(using: context)
                        dismiss()
                    } catch {
                        print("Failed to save entry: \(error)")
                    }
                }
                .disabled(!viewModel.canSave)
            }
        }
    }
}
