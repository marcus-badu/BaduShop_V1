# BaduShop_V1
App for creating, maintaining and using shopping lists.
The secondary objective of this app was to test conde generation from ChatGPT and Grok, using both in its free versions.

📱 Main features
1 Creating and managing shopping lists
◦ List name, market name and store location.
◦ List can be marked as active or not.
2 Adding and editing items
◦ Fields: name, quantity (with decimal support), unit, store aisle/section and whether it has already been added to the cart.
◦ + and - buttons to adjust the quantity intuitively.
◦ Text, voice input and OCR, with speech recognition in Portuguese.
3 Voice input with NLP
◦ The user can dictate phrases such as: "2 quilos de arroz" → Name: Arroz, Quantity: 2, Unit: Quilos.
◦ Speech is transcribed in real time and interpreted automatically.
◦ Audio is not stored, only the text.

🧱 Architecture and technology
🧰 Used Technology
	•	Language: Swift 5+
	•	Main Frameworks:
	◦	SwiftUI (Interface)
	◦	Core Data (Local persistence)
	◦	Speech (voice recognizion)
	◦	OCR (written list interpretation)
	•	Architecture Standard: MVVM (Model-View-ViewModel)
	•	Local Storage: Core Data
	•	State Management: @StateObject, @ObservedObject, @Environment

📁 Estrutura do projeto
	•	BaduShopApp.swift: ponto de entrada com injeção do DataController.
	•	DataController.swift: singleton que gerencia o Core Data stack.
	•	ViewModels: lógica de negócio separada da interface (AddItemViewModel, ShoppingListViewModel, etc.).
	•	Views: telas baseadas em SwiftUI.
	•	SpeechRecognizer.swift: classe que encapsula toda a lógica de transcrição de voz usando a framework Speech.

📦 Core Data — Entities
Manually defined entities (codeGenerationType = manual):
1. User
	•	id: UUID
	•	name: String
	•	createdAt: Date
2. ShoppingList
	•	id: UUID
	•	name: String
	•	marketName: String
	•	storeLocation: String
	•	isActive: Bool
	•	createdAt: Date
	•	🔁 Relacionamentos:
	◦	user (to-one)
	◦	items (to-many)
3. Item
	•	id: UUID
	•	name: String
	•	quantity: Double
	•	unit: String
	•	storeSection: String
	•	isPicked: Bool
	•	createdAt: Date
	•	🔁 Relacionamentos:
	◦	shoppingList (to-one)
