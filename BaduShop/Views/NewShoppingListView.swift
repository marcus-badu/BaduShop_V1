// NewShoppingListView.swift
// BaduShop
// Version: 5
// Created by Marcus Silva on 07/06/25.
// Updated on 17/06/25 with improved UI layout and validation feedback.
// Updated on 19/06/25 to support editing existing shopping lists.
// Updated on 19/06/25 to add microphone button for list name and clearable text fields.
// Updated on 19/06/25 to fix compilation errors by using clearTranscript() instead of resetTranscript().

import SwiftUI

struct NewShoppingListView: View {
    @ObservedObject var viewModel: ShoppingListViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var context
    @StateObject private var speechRecognizer = SpeechRecognizer()
    private let isEditMode: Bool
    
    init(viewModel: ShoppingListViewModel, isEditMode: Bool = false) {
        self.viewModel = viewModel
        self.isEditMode = isEditMode
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Detalhes da Lista")) {
                    HStack(spacing: 10) {
                        ClearableTextField(placeholder: "Nome da Lista", text: $viewModel.name)
                        Button(action: toggleRecording) {
                            Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(speechRecognizer.isRecording ? Color.red : Color.blue)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Gravar nome da lista por voz")
                    }
                    
                    ClearableTextField(placeholder: "Nome do Mercado", text: $viewModel.marketName)
                    ClearableTextField(placeholder: "Localização da Loja", text: $viewModel.storeLocation)
                }
            }
            .navigationTitle(isEditMode ? "Editar Lista" : "Nova Lista")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        if viewModel.isValid() {
                            viewModel.saveList()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isValid())
                }
            }
            .onChange(of: speechRecognizer.transcript) { newText in
                parseSpeechInput(newText)
            }
            .onAppear {
                speechRecognizer.requestAuthorization { _ in }
                print("NewShoppingListView appeared with \(isEditMode ? "edit" : "create") mode")
            }
        }
    }
    
    private func toggleRecording() {
        if speechRecognizer.isRecording {
            speechRecognizer.stopTranscribing()
        } else {
            speechRecognizer.clearTranscript()
            speechRecognizer.startTranscribing()
        }
        print("Recording toggled: \(speechRecognizer.isRecording)")
    }
    
    private func parseSpeechInput(_ text: String) {
        let normalizedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalizedText.isEmpty {
            viewModel.name = normalizedText.capitalized
            print("Nome da lista atualizado via voz: \(viewModel.name)")
        }
    }
}
