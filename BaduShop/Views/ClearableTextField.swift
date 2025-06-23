// ClearableTextField.swift
// BaduShop
// Version: 1
// Created by Marcus Silva on 19/06/25.
// Custom TextField with native iOS clear button.

import SwiftUI

struct ClearableTextField: UIViewRepresentable {
    let placeholder: String
    @Binding var text: String
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.placeholder = placeholder
        textField.clearButtonMode = .whileEditing
        textField.borderStyle = .roundedRect
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: ClearableTextField
        
        init(_ parent: ClearableTextField) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
        
        func textFieldShouldClear(_ textField: UITextField) -> Bool {
            parent.text = ""
            return true
        }
    }
}
