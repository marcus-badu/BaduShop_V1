//
//  ShoppingSessionViewModel.swift
//  BaduShop
//  Version: 1
//  Created by Marcus Silva on 07/06/25.
//

import Foundation
import CoreData

class ShoppingSessionViewModel: ObservableObject {
    @Published var shoppingList: ShoppingList

    init(shoppingList: ShoppingList) {
        self.shoppingList = shoppingList
    }

    var groupedItems: [String: [Item]] {
        let items = (shoppingList.items as? Set<Item>) ?? []
        let sorted = items.sorted {
            if $0.storeSection == $1.storeSection {
                return ($0.name ?? "") < ($1.name ?? "")
            }
            return ($0.storeSection ?? "") < ($1.storeSection ?? "")
        }

        return Dictionary(grouping: sorted) { $0.storeSection ?? "Outros" }
    }

    func toggleItemPicked(_ item: Item, context: NSManagedObjectContext) {
        item.isPicked.toggle()
        try? context.save()
        objectWillChange.send()
    }
}
