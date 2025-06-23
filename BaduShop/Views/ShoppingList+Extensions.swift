//
//  ShoppingList+Extensions.swift
//  BaduShop
//  Version: 1
//  Created by Marcus Silva on 07/06/25.
//

import Foundation

extension ShoppingList {
    var itemsArray: [Item] {
        (items as? Set<Item>)?.sorted(by: { ($0.createdAt ?? Date()) < ($1.createdAt ?? Date()) }) ?? []
    }
}

