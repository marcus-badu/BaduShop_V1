//
//  DataController.swift
//  BaduShop
//  Version: 1
//  Created by Marcus Silva on 02/06/25.
//

import CoreData

class DataController: ObservableObject {
    let container: NSPersistentContainer

    init() {
        container = NSPersistentContainer(name: "BaduShop")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Erro ao carregar Core Data: \(error.localizedDescription)")
            }
        }
    }
}
