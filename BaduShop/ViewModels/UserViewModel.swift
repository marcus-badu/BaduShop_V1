//
//  UserViewModel.swift
//  BaduShop
//  Version: 1
//  Created by Marcus Silva on 02/06/25.
//

import Foundation
import CoreData

class UserViewModel: ObservableObject {
    @Published var user: User?
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        fetchOrCreateUser()
    }

    private func fetchOrCreateUser() {
        let request: NSFetchRequest<User> = User.fetchRequest()
        request.fetchLimit = 1

        do {
            if let existing = try context.fetch(request).first {
                self.user = existing
            } else {
                let newUser = User(context: context)
                newUser.id = UUID()
                newUser.createdAt = Date()
                newUser.name = "Usuário"
                try context.save()
                self.user = newUser
            }
        } catch {
            print("Erro ao buscar ou criar usuário: \(error.localizedDescription)")
        }
    }
}

