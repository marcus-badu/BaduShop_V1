// ManageItemViewModel.swift
// BaduShop
// Version: 4
// Created by Marcus Silva on 07/06/25.
// Updated on 17/06/25 with support for ShoppingItem and Core Data integration.
// Updated on 19/06/25 to add duplicate item detection with user alert.
// Updated on 19/06/25 to fix compilation errors and use getShoppingList().

import Foundation
import CoreData

class ManageItemViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var quantity: Double = 1.0
    @Published var unit: String = ""
    @Published var storeSection: String = ""
    @Published var isPicked: Bool = false
    
    @Published var showDuplicateAlert = false
    @Published var duplicateItemName: String = "" // For single item save
    @Published var duplicateItems: [ShoppingItem] = [] // For multiple items save
    @Published var pendingItems: [ShoppingItem] = [] // Items to save after alert confirmation
    
    private let shoppingListViewModel: ShoppingListViewModel
    private let item: Item?
    private let context: NSManagedObjectContext
    let isEditMode: Bool
    
    init(shoppingListViewModel: ShoppingListViewModel, item: Item? = nil, context: NSManagedObjectContext) {
        self.shoppingListViewModel = shoppingListViewModel
        self.item = item
        self.context = context
        self.isEditMode = item != nil
        
        if let item = item {
            self.name = item.name ?? ""
            self.quantity = item.quantity
            self.unit = item.unit ?? ""
            self.storeSection = item.storeSection ?? ""
            self.isPicked = item.isPicked
        }
    }
    
    func isValid() -> Bool {
        return !name.isEmpty
    }
    
    func save() {
        let shoppingItem = ShoppingItem(
            name: name,
            quantity: quantity,
            unit: unit.isEmpty ? "unidade" : unit,
            storeSection: storeSection,
            isPicked: isPicked
        )
        
        // Check for duplicate
        guard let shoppingList = shoppingListViewModel.getShoppingList() else {
            print("Erro: shoppingList não definida, não verificando duplicatas")
            saveItem([shoppingItem])
            return
        }
        
        let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "name ==[c] %@ AND shoppingList == %@", shoppingItem.name, shoppingList)
        fetchRequest.fetchLimit = 1
        
        do {
            let existingItems = try context.fetch(fetchRequest)
            if let existingItem = existingItems.first, (!isEditMode || existingItem.id != item?.id) {
                // Duplicate found, and it's not the item being edited
                duplicateItemName = shoppingItem.name
                pendingItems = [shoppingItem]
                showDuplicateAlert = true
                print("Duplicata detectada: \(shoppingItem.name)")
            } else {
                // No duplicate or editing the same item
                saveItem([shoppingItem])
            }
        } catch {
            print("Erro ao verificar duplicata: \(error.localizedDescription)")
            saveItem([shoppingItem]) // Fallback: save item
        }
    }
    
    func saveMultipleItems(_ items: [ShoppingItem]) {
        guard let shoppingList = shoppingListViewModel.getShoppingList() else {
            print("Erro: shoppingList não definida, não verificando duplicatas")
            saveItem(items)
            return
        }
        
        var duplicates: [ShoppingItem] = []
        var nonDuplicates: [ShoppingItem] = []
        
        for item in items {
            let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name ==[c] %@ AND shoppingList == %@", item.name, shoppingList)
            fetchRequest.fetchLimit = 1
            
            do {
                let existingItems = try context.fetch(fetchRequest)
                if existingItems.isEmpty {
                    nonDuplicates.append(item)
                } else {
                    duplicates.append(item)
                }
            } catch {
                print("Erro ao verificar duplicata: \(error.localizedDescription)")
                nonDuplicates.append(item) // Fallback: treat as non-duplicate
            }
        }
        
        if duplicates.isEmpty {
            saveItem(nonDuplicates)
        } else {
            duplicateItems = duplicates
            pendingItems = items
            showDuplicateAlert = true
            print("Duplicatas detectadas: \(duplicates.map { $0.name })")
        }
    }
    
    func saveItem(_ items: [ShoppingItem]) {
        if isEditMode, let existingItem = item {
            shoppingListViewModel.deleteItem(existingItem)
        }
        shoppingListViewModel.addItems(items)
        pendingItems = [] // Clear pending items
    }
    
    func delete() {
        if let item = item {
            shoppingListViewModel.deleteItem(item)
        }
    }
}
