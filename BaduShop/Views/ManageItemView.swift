// ManageItemView.swift
// BaduShop
// Version: 24
// Created by Marcus Silva on 07/06/25.
// Updated on 19/06/25 with improved speech parsing for compound names and flexible dictation patterns.
// Updated on 19/06/25 to fix compilation errors in parseTextToItem and ImagePicker.
// Updated on 19/06/25 to fix compound name parsing issues and improve quantity/unit recognition.
// Updated on 19/06/25 to fix parsing of compound names without quantities (e.g., "Pimentão Vermelho").
// Updated on 19/06/25 to fix excessive whitespace in names and incorrect preposition handling.
// Updated on 19/06/25 to add duplicate item alert and fix compilation errors.
// Updated on 19/06/25 to dismiss view after saving items.
// Updated on 19/06/25 to ensure OCR button visibility by reordering form.
// Updated on 19/06/25 to fix empty form issue by removing ScrollView.
// Updated on 19/06/25 to reduce OCR button prominence and add clearable text fields.
// Updated on 19/06/25 to use existing SpeechRecognizer and align with isRecording state.
// Updated on 19/06/25 to fix compilation errors by using clearTranscript() instead of resetTranscript().
// Updated on 20/06/25 to improve OCR/speech parsing for numbers, units (e.g., dúzia, potes), and names.
// Updated on 20/06/25 to fix compilation errors (speech authorization, VNRecognizeTextRequest) and add new units (e.g., saco, frasco, lata).
// Updated on 20/06/25 to fix structural errors causing scope and top-level statement issues.
// Updated on 20/06/25 to fix ImagePicker compilation errors in coordinator delegate method.
// Updated on 20/06/25 to fix parsing errors for number indicators (e.g., "Filtro de Café número 100").
// Updated on 20/06/25 to fix parsing for initial numeric quantities (e.g., "2 Detergente Incolor") with robust number detection.

import SwiftUI
import NaturalLanguage
import Vision
import UIKit

struct ManageItemView: View {
    @ObservedObject var viewModel: ManageItemViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.managedObjectContext) private var context
    @StateObject private var speechRecognizer = SpeechRecognizer()
    
    @State private var isShowingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var isProcessingOCR = false
    @State private var ocrErrorMessage: String?
    
    private let quantityFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.minimumIntegerDigits = 1
        return formatter
    }()
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Informações do Item")) {
                    // OCR Button
                    Button(action: {
                        isShowingImagePicker = true
                        print("OCR button tapped")
                    }) {
                        HStack {
                            Image(systemName: "camera")
                            Text("Escanear Lista por Foto")
                        }
                        .foregroundColor(.blue)
                    }
                    .accessibilityLabel("Escanear itens por foto")
                    
                    // Nome field with microphone
                    HStack(spacing: 10) {
                        ClearableTextField(placeholder: "Nome", text: $viewModel.name)
                        Button(action: toggleRecording) {
                            Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                                .foregroundColor(.white)
                                .padding(8)
                                .background(speechRecognizer.isRecording ? Color.red : Color.blue)
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Gravar item por voz")
                    }
                    
                    // Quantidade field
                    HStack(spacing: 15) {
                        Text("Quantidade")
                        Spacer()
                        Button(action: {
                            if viewModel.quantity > 0.0 {
                                viewModel.quantity = max(0.0, viewModel.quantity - 1)
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                                .padding(5)
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(PlainButtonStyle())
                        
                        TextField("", value: $viewModel.quantity, formatter: quantityFormatter)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .frame(width: 80)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: viewModel.quantity) { newValue in
                                if newValue < 0 {
                                    viewModel.quantity = 0
                                }
                            }
                            .simultaneousGesture(TapGesture().onEnded { })
                        
                        Button(action: {
                            viewModel.quantity += 1
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                                .padding(5)
                        }
                        .contentShape(Rectangle())
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    ClearableTextField(placeholder: "Unidade", text: $viewModel.unit)
                    ClearableTextField(placeholder: "Seção da Loja", text: $viewModel.storeSection)
                    
                    Toggle("Item comprado", isOn: $viewModel.isPicked)
                }
                
                if viewModel.isEditMode {
                    Section {
                        Button(role: .destructive) {
                            viewModel.delete()
                            dismiss()
                        } label: {
                            Label("Excluir Item", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(viewModel.isEditMode ? "Editar Item" : "Novo Item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        if viewModel.isValid() {
                            viewModel.save()
                            if !viewModel.showDuplicateAlert {
                                dismiss()
                            }
                        }
                    }
                    .disabled(isProcessingOCR)
                }
            }
            .onChange(of: speechRecognizer.transcript) { newText in
                parseSpeechInput(newText)
            }
            .onChange(of: selectedImage) { image in
                if let image = image {
                    processOCR(image: image)
                }
            }
            .sheet(isPresented: $isShowingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .alert("Erro no OCR", isPresented: Binding<Bool>(
                get: { ocrErrorMessage != nil },
                set: { if !$0 { ocrErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(ocrErrorMessage ?? "Erro desconhecido")
            }
            .alert("Item Duplicado", isPresented: $viewModel.showDuplicateAlert) {
                Button("Adicionar Mesmo Assim") {
                    viewModel.saveItem(viewModel.pendingItems)
                    dismiss()
                }
                Button("Cancelar", role: .cancel) {
                    viewModel.pendingItems = []
                }
            } message: {
                if viewModel.duplicateItems.isEmpty {
                    Text("O item '\(viewModel.name)' já existe na lista. Deseja adicionar mesmo assim?")
                } else {
                    let names = viewModel.duplicateItems.map { $0.name }.joined(separator: ", ")
                    Text("Os itens \(names) já existem na lista. Deseja adicionar mesmo assim?")
                }
            }
            .onAppear {
                speechRecognizer.requestAuthorization { _ in }
                print("ManageItemView appeared with \(viewModel.isEditMode ? "edit" : "create") mode")
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
    
    private func processOCR(image: UIImage) {
        isProcessingOCR = true
        print("Initiating OCR processing...")
        
        let request = VNRecognizeTextRequest { request, error in
            defer { self.isProcessingOCR = false }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.ocrErrorMessage = "Erro ao processar imagem: \(error.localizedDescription)"
                    print("OCR error: \(error.localizedDescription)")
                }
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    self.ocrErrorMessage = "Nenhum texto detectado na imagem."
                    print("No text detected")
                }
                return
            }
            
            let lines = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }
            
            print("Extracted text: \(lines.joined(separator: "\n"))")
            
            var items: [ShoppingItem] = []
            for line in lines {
                if let item = parseTextToItem(line) {
                    items.append(item)
                    print("Parsed item: \(item.name) - \(item.quantity) \(item.unit)")
                }
            }
            
            DispatchQueue.main.async {
                if !items.isEmpty {
                    self.viewModel.saveMultipleItems(items)
                    if !self.viewModel.showDuplicateAlert {
                        self.dismiss()
                    }
                } else {
                    self.ocrErrorMessage = "Nenhum item válido extraído da imagem."
                    print("No valid items extracted")
                }
            }
        }
        
        request.recognitionLanguages = ["pt-BR"]
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        
        guard let cgImage = image.cgImage else {
            isProcessingOCR = false
            ocrErrorMessage = "Não foi possível processar a imagem."
            print("Error: Invalid image")
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            isProcessingOCR = false
            ocrErrorMessage = "Erro ao realizar OCR: \(error.localizedDescription)"
            print("OCR error: \(error.localizedDescription)")
        }
    }
    
    private func parseTextToItem(_ text: String) -> ShoppingItem? {
        print("Parsing text: \(text)")
        
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.setLanguage(.portuguese, range: text.startIndex..<text.endIndex)
        let normalizedText = text.lowercased().replacingOccurrences(of: ",", with: ".")
        tagger.string = normalizedText
        
        let numberWords: [String: Double] = [
            "zero": 0, "um": 1, "uma": 1, "dois": 2, "duas": 2, "três": 3, "quatro": 4, "cinco": 5,
            "seis": 6, "sete": 7, "oito": 8, "nove": 9, "dez": 10,
            "onze": 11, "doze": 12, "treze": 13, "quatorze": 14, "quinze": 15,
            "dezesseis": 16, "dezessete": 17, "dezoito": 18, "dezenove": 19,
            "vinte": 20, "trinta": 30, "quarenta": 40, "cinquenta": 50,
            "meio": 0.5
        ]
        
        let units = [
            "quilo", "quilos", "kg", "kilo", "kilos",
            "grama", "gramas", "g",
            "litro", "litros", "l",
            "mililitro", "mililitros", "ml",
            "unidade", "unidades", "un",
            "pacote", "pacotes",
            "dúzia", "duzias",
            "pote", "potes",
            "caixa", "caixas",
            "lata", "latas",
            "garrafa", "garrafas",
            "vidro", "vidros",
            "saco", "sacos",
            "frasco", "frascos",
            "sachê", "sache", "sachet", "sachês",
            "rodelas", "rodela",
            "tablete", "tabletes",
            "fardo", "fardos",
            "bandeja", "bandejas",
            "pacotinho", "pacotinhos",
            "rolo", "rolos",
            "tubo", "tubos",
            "galão", "galões"
        ]
        
        let unitNormalization: [String: String] = [
            "quilos": "Quilo", "kilos": "Quilo", "kg": "Quilo",
            "gramas": "Grama", "g": "Grama",
            "litros": "Litro", "l": "Litro",
            "mililitros": "Mililitro", "ml": "Mililitro",
            "unidades": "Unidade", "un": "Unidade",
            "pacotes": "Pacote",
            "dúzia": "Dúzia", "duzias": "Dúzia",
            "potes": "Pote",
            "caixas": "Caixa",
            "latas": "Lata",
            "garrafas": "Garrafa",
            "vidros": "Vidro",
            "sacos": "Saco",
            "frascos": "Frasco",
            "sachês": "Sachê", "sache": "Sachê", "sachet": "Sachê",
            "rodelas": "Rodela",
            "tabletes": "Tablete",
            "fardos": "Fardo",
            "bandejas": "Bandeja",
            "pacotinhos": "Pacotinho",
            "rolos": "Rolo",
            "tubos": "Tubo",
            "galões": "Galão"
        ]
        
        let stopwords = ["e", "com", "de"]
        let nameNumberIndicators = ["número", "numero", "tamanho"]
        
        var quantity: Double = 1.0
        var unit: String? = nil
        var nameTokens: [String] = []
        var usedForQuantity: Set<String> = []
        var usedForUnit: Set<String> = []
        var isAfterNumberIndicator = false
        var isFirstWord = true
        var lastWasUnit = false
        
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "pt_BR")
        numberFormatter.numberStyle = .decimal
        
        tagger.enumerateTags(in: normalizedText.startIndex..<normalizedText.endIndex, unit: .word, scheme: .lexicalClass) { tag, range in
            let word = String(normalizedText[range]).lowercased()
            print("Word: \(word), Tag: \(tag?.rawValue ?? "none"), UsedForQuantity: \(usedForQuantity.contains(word)), UsedForUnit: \(usedForUnit.contains(word))")
            
            if tag == .whitespace || word.trimmingCharacters(in: .whitespaces).isEmpty {
                print("Ignoring whitespace: \(word)")
                return true
            }
            
            // Handle initial quantity
            if isFirstWord && !isAfterNumberIndicator {
                if let number = numberFormatter.number(from: word)?.doubleValue {
                    quantity = number
                    usedForQuantity.insert(word)
                    print("Numeric quantity detected via formatter: \(number)")
                    isFirstWord = false
                    return true
                } else if let number = numberWords[word] {
                    quantity = number
                    usedForQuantity.insert(word)
                    print("Word quantity detected: \(number)")
                    isFirstWord = false
                    return true
                }
            }
            
            // Handle number indicators (e.g., "número 100")
            if nameNumberIndicators.contains(word) {
                isAfterNumberIndicator = true
                nameTokens.append(word)
                print("Number indicator detected: \(word)")
                isFirstWord = false
                return true
            }
            
            // Handle numbers after indicators
            if (tag == .number || numberWords[word] != nil || numberFormatter.number(from: word) != nil) && isAfterNumberIndicator {
                nameTokens.append(word)
                print("Number included in name after indicator: \(word)")
                isAfterNumberIndicator = false
                isFirstWord = false
                return true
            }
            
            // Handle units
            if units.contains(word) && !usedForQuantity.contains(word) && !isAfterNumberIndicator {
                unit = unitNormalization[word] ?? word.capitalized
                usedForUnit.insert(word)
                lastWasUnit = true
                print("Unit detected: \(unit!)")
                isFirstWord = false
                return true
            }
            
            // Handle name tokens
            if !usedForQuantity.contains(word) && !usedForUnit.contains(word) && !stopwords.contains(word) && !isAfterNumberIndicator {
                nameTokens.append(word)
                print("Name token added: \(word)")
            } else if word == "de" && lastWasUnit {
                print("Ignoring 'de' after unit: \(word)")
            } else {
                print("Ignoring word: \(word), Used for quantity: \(usedForQuantity.contains(word)), Used for unit: \(usedForUnit.contains(word)), Stopword: \(stopwords.contains(word)), AfterNumberIndicator: \(isAfterNumberIndicator)")
            }
            
            lastWasUnit = false
            isFirstWord = false
            return true
        }
        
        // Clean name tokens
        var cleanedNameTokens: [String] = []
        var isFirstToken = true
        for token in nameTokens {
            if isFirstToken && token == "de" {
                print("Ignoring initial preposition 'de'")
                isFirstToken = false
                continue
            }
            cleanedNameTokens.append(token)
            isFirstToken = false
        }
        
        if let lastToken = cleanedNameTokens.last, lastToken == "de" {
            cleanedNameTokens.removeLast()
            print("Ignoring final preposition 'de'")
        }
        
        let rawName = cleanedNameTokens.joined(separator: " ")
        let normalizedName = rawName.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression).trimmingCharacters(in: .whitespaces)
        let finalName = normalizedName.split(separator: " ").enumerated().map { (index, word) in
            let lowerWord = word.lowercased()
            if lowerWord == "de" && index > 0 {
                return lowerWord
            }
            return word.capitalized
        }.joined(separator: " ")
        
        print("Raw name: \(rawName)")
        print("Normalized name: \(normalizedName)")
        print("Final name: \(finalName)")
        
        if !finalName.isEmpty {
            print("Item created - Name: \(finalName), Quantity: \(quantity), Unit: \(unit ?? "Unidade")")
            return ShoppingItem(
                name: finalName,
                quantity: quantity,
                unit: unit ?? "Unidade",
                storeSection: "",
                isPicked: false
            )
        }
        
        print("No valid item created")
        return nil
    }
    
    private func parseSpeechInput(_ text: String) {
        if let item = parseTextToItem(text) {
            viewModel.name = item.name
            viewModel.quantity = item.quantity
            viewModel.unit = item.unit
            print("Results - Name: \(viewModel.name), Quantity: \(viewModel.quantity), Unit: \(viewModel.unit)")
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
