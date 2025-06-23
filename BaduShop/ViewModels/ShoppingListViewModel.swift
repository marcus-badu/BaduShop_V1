// ShoppingListViewModel.swift
// BaduShop
// Version: 4
// Created by Marcus Silva on 07/06/25.
// Updated on 17/06/25 with support for adding items and Core Data integration.
// Updated on 19/06/25 to fix persistence issues by setting createdAt and shoppingList relationship.
// Updated on 19/06/25 to add duplicate item detection and quantity merging.
// Updated on 19/06/25 to add getter for shoppingList to support duplicate checks.

import Foundation
import CoreData

class ShoppingListViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var marketName: String = ""
    @Published var storeLocation: String = ""
    @Published var items: [Item] = []
    
    private let context: NSManagedObjectContext
    private let user: User
    private var shoppingList: ShoppingList?
    
    init(context: NSManagedObjectContext, user: User, shoppingList: ShoppingList? = nil) {
        self.context = context
        self.user = user
        self.shoppingList = shoppingList
        
        if let shoppingList = shoppingList {
            self.name = shoppingList.name ?? ""
            self.marketName = shoppingList.marketName ?? ""
            self.storeLocation = shoppingList.storeLocation ?? ""
            self.items = (shoppingList.items?.allObjects as? [Item]) ?? []
        }
    }
    
    // Getter for shoppingList
    func getShoppingList() -> ShoppingList? {
        return shoppingList
    }
    
    func saveList() {
        let list = shoppingList ?? ShoppingList(context: context)
        list.id = UUID()
        list.name = name
        list.marketName = marketName
        list.storeLocation = storeLocation
        list.isActive = true
        list.createdAt = Date()
        list.user = user
        
        // Adicionar itens existentes
        for item in items {
            item.shoppingList = list
            list.addToItems(item)
        }
        
        do {
            try context.save()
            self.shoppingList = list
            print("Lista salva com sucesso: \(name)")
        } catch {
            print("Erro ao salvar a lista: \(error.localizedDescription)")
        }
    }
    
    func addItems(_ newItems: [ShoppingItem]) {
        guard let list = shoppingList else {
            print("Erro: shoppingList não definida, itens não adicionados: \(newItems.map { $0.name })")
            return
        }
        
        for shoppingItem in newItems {
            // Check for duplicate
            let fetchRequest: NSFetchRequest<Item> = Item.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "name ==[c] %@ AND shoppingList == %@", shoppingItem.name, list)
            fetchRequest.fetchLimit = 1
            
            do {
                let existingItems = try context.fetch(fetchRequest)
                if let existingItem = existingItems.first {
                    // Duplicate found
                    if existingItem.unit == shoppingItem.unit {
                        // Same unit: merge quantities
                        existingItem.quantity += shoppingItem.quantity
                        existingItem.storeSection = shoppingItem.storeSection.isEmpty ? existingItem.storeSection : shoppingItem.storeSection
                        existingItem.isPicked = shoppingItem.isPicked
                        existingItem.createdAt = Date()
                        print("Item duplicado mesclado: \(shoppingItem.name), Nova quantidade: \(existingItem.quantity)")
                    } else {
                        // Different unit: create new item
                        createNewItem(from: shoppingItem, for: list)
                        print("Item duplicado com unidade diferente, criado novo: \(shoppingItem.name)")
                    }
                } else {
                    // No duplicate: create new item
                    createNewItem(from: shoppingItem, for: list)
                }
            } catch {
                print("Erro ao verificar duplicata: \(error.localizedDescription)")
                createNewItem(from: shoppingItem, for: list) // Fallback: create new item
            }
        }
        
        do {
            try context.save()
            // Refresh items array from Core Data
            self.items = (list.items?.allObjects as? [Item]) ?? []
            print("Itens salvos com sucesso: \(newItems.map { $0.name })")
        } catch {
            print("Erro ao salvar itens: \(error.localizedDescription)")
        }
    }
    
    private func createNewItem(from shoppingItem: ShoppingItem, for list: ShoppingList) {
        let newItem = Item(context: context)
        newItem.id = shoppingItem.id
        newItem.name = shoppingItem.name
        newItem.quantity = shoppingItem.quantity
        newItem.unit = shoppingItem.unit
        newItem.storeSection = shoppingItem.storeSection
        newItem.isPicked = shoppingItem.isPicked
        newItem.createdAt = Date()
        newItem.shoppingList = list
        list.addToItems(newItem)
        items.append(newItem)
    }
    
    func deleteItem(_ item: Item) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items.remove(at: index)
            context.delete(item)
            do {
                try context.save()
                print("Item deletado: \(item.name ?? "desconhecido")")
            } catch {
                print("Erro ao deletar item: \(error.localizedDescription)")
            }
        }
    }
    
    func isValid() -> Bool {
        !name.isEmpty && !marketName.isEmpty && !storeLocation.isEmpty
    }
}
