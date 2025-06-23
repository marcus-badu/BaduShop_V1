// ShoppingItem.swift
// BaduShop
// Version: 2
// Created by Marcus Silva on 07/06/25.
// Updated on 17/06/25 with renamed Item to ShoppingItem to avoid Core Data conflict.

import Foundation

struct ShoppingItem: Identifiable {
    let id = UUID()
    var name: String
    var quantity: Double
    var unit: String
    var storeSection: String
    var isPicked: Bool
}
