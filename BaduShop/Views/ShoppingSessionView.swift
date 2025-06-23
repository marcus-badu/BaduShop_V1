//
//  ShoppingSessionView.swift
//  BaduShop
//  Version: 1
//  Created by Marcus Silva on 07/06/25.
//

import SwiftUI

struct ShoppingSessionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject var viewModel: ShoppingSessionViewModel

    var body: some View {
        List {
            ForEach(viewModel.groupedItems.keys.sorted(), id: \.self) { section in
                Section(header: Text(section)) {
                    ForEach(viewModel.groupedItems[section] ?? [], id: \.self) { item in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(item.name ?? "")
                                    .strikethrough(item.isPicked, color: .gray)
                                    .foregroundColor(item.isPicked ? .gray : .primary)
                                    .font(.headline)

                                Text("\(item.quantity, specifier: "%.1f") \(item.unit ?? "")")
                                    .strikethrough(item.isPicked, color: .gray)
                                    .foregroundColor(item.isPicked ? .gray : .secondary)
                                    .font(.subheadline)
                            }

                            Spacer()

                            Button(action: {
                                viewModel.toggleItemPicked(item, context: viewContext)
                            }) {
                                Image(systemName: item.isPicked ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(item.isPicked ? .green : .gray)
                                    .imageScale(.large)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(viewModel.shoppingList.name ?? "Fazendo Compra")
    }
}
