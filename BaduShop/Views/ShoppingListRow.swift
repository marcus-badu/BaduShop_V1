//
//  ShoppingListRow.swift
//  BaduShop
//  Version: 1
//  Created by Marcus Silva on 07/06/25.
//

import SwiftUI

struct ShoppingListRow: View {
    var shoppingList: ShoppingList
    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(shoppingList.name ?? "Lista sem nome")
                    .font(.headline)
                Text("\(shoppingList.marketName ?? "") – \(shoppingList.storeLocation ?? "")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            NavigationLink(
                destination: ShoppingSessionView(
                    viewModel: ShoppingSessionViewModel(shoppingList: shoppingList)
                )
            ) {
                Image(systemName: "cart")
                    .imageScale(.large)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
                    .accessibilityLabel("Iniciar compra")
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 4)
    }
}
