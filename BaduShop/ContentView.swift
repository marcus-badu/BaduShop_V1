// ContentView.swift
// BaduShop
// Version: 4
// Created by Marcus Silva on 02/06/25.
// Updated on 19/06/25 to add swipe-to-delete for shopping lists.
// Updated on 19/06/25 to restore marketName and storeLocation in list rows.
// Updated on 19/06/25 to remove decorative cart icon.

import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: UserViewModel
    @State private var showingNewListView = false

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ShoppingList.createdAt, ascending: false)],
        predicate: NSPredicate(format: "isActive == true"),
        animation: .default)
    private var shoppingLists: FetchedResults<ShoppingList>

    init(context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: UserViewModel(context: context))
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(shoppingLists, id: \.self) { shoppingList in
                    NavigationLink(destination: ShoppingListDetailView(shoppingList: shoppingList, context: viewContext)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shoppingList.name ?? "Lista sem nome")
                                .font(.headline)
                            if let marketName = shoppingList.marketName, !marketName.isEmpty {
                                Text("Mercado: \(marketName)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            if let storeLocation = shoppingList.storeLocation, !storeLocation.isEmpty {
                                Text("Localização: \(storeLocation)")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .swipeActions {
                        Button(role: .destructive) {
                            viewContext.delete(shoppingList)
                            do {
                                try viewContext.save()
                                print("Lista deletada: \(shoppingList.name ?? "sem nome")")
                            } catch {
                                print("Erro ao deletar lista: \(error.localizedDescription)")
                            }
                        } label: {
                            Label("Excluir", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Listas de Compras")
            .toolbar {
                Button(action: {
                    showingNewListView = true
                }) {
                    Label("Nova Lista", systemImage: "plus")
                }
            }
            .sheet(isPresented: $showingNewListView) {
                NewShoppingListView(viewModel: ShoppingListViewModel(context: viewContext, user: viewModel.user!))
            }
        }
    }
}
