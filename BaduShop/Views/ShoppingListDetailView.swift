// ShoppingListDetailView.swift
// BaduShop
// Version: 2.3
// Created by Marcus Silva on 07/06/25.
// Updated by Marcus Silva on 17/06/25 to fix checkmark tap opening ManageItemView.
// Updated on 19/06/25 to pass context to ManageItemViewModel.
// Updated on 19/06/25 to refresh groupedItems after item deletion.
// Updated on 19/06/25 to add edit list functionality.
// Updated on 20/06/25 to display all picked items in a single "Itens Comprados" section at the end, sorted by name, while preserving grouping by storeSection and sorting by name for unpicked items.

import SwiftUI
import CoreData

class ShoppingListDetailViewModel: ObservableObject {
    let shoppingList: ShoppingList
    @Published var groupedItems: [String: [Item]]
    let shoppingListViewModel: ShoppingListViewModel

    init(shoppingList: ShoppingList, context: NSManagedObjectContext) {
        self.shoppingList = shoppingList
        self.groupedItems = [:]
        self.shoppingListViewModel = ShoppingListViewModel(context: context, user: shoppingList.user ?? User(context: context), shoppingList: shoppingList)
        refreshGroupedItems()
    }
    
    func refreshGroupedItems() {
        // Partition items by isPicked
        let unpickedItems = shoppingList.itemsArray.filter { !$0.isPicked }
        let pickedItems = shoppingList.itemsArray.filter { $0.isPicked }
        
        // Group unpicked items by storeSection
        var newGroupedItems = Dictionary(grouping: unpickedItems) { item in
            item.storeSection ?? "Outros"
        }
        .mapValues { items in
            items.sorted { ($0.name ?? "") < ($1.name ?? "") }
        }
        
        // Add picked items to "Itens Comprados" section if any exist
        if !pickedItems.isEmpty {
            newGroupedItems["Itens Comprados"] = pickedItems.sorted { ($0.name ?? "") < ($1.name ?? "") }
        }
        
        groupedItems = newGroupedItems
        print("groupedItems atualizado: \(groupedItems.keys)")
    }
}

struct ItemRowView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var item: Item
    let viewModel: ShoppingListDetailViewModel
    let onTap: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    item.isPicked.toggle()
                    do {
                        try viewContext.save()
                        print("isPicked alterado para \(item.isPicked) no item \(item.name ?? "Sem nome")")
                        viewModel.refreshGroupedItems()
                    } catch {
                        print("Erro ao salvar isPicked: \(error)")
                    }
                    item.objectWillChange.send()
                }
            }) {
                Image(systemName: item.isPicked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isPicked ? .green : .gray)
                    .frame(width: 30, height: 30)
                    .accessibilityLabel(item.isPicked ? "Desmarcar item" : "Marcar item")
            }
            .buttonStyle(PlainButtonStyle())
            .contentShape(Circle())

            VStack(alignment: .leading) {
                Text(item.name ?? "")
                    .font(.headline)
                    .strikethrough(item.isPicked, color: .gray)
                    .foregroundColor(item.isPicked ? .gray : .primary)

                Text("\(item.quantity, specifier: "%.1f") \(item.unit ?? "") - \(item.storeSection ?? "")")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                print("Toque registrado na área de texto de ItemRowView")
                onTap()
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .swipeActions {
            Button(role: .destructive) {
                viewContext.delete(item)
                do {
                    try viewContext.save()
                    print("Item deletado via swipe: \(item.name ?? "desconhecido")")
                    onDelete()
                } catch {
                    print("Erro ao deletar item: \(error.localizedDescription)")
                }
            } label: {
                Label("Excluir", systemImage: "trash")
            }
        }
    }
}

struct SectionView: View {
    let section: String
    let items: [Item]
    let viewModel: ShoppingListDetailViewModel
    let onItemTap: (Item) -> Void
    let onItemDelete: () -> Void

    var body: some View {
        Section(header: Text(section)) {
            ForEach(items, id: \.self) { item in
                ItemRowView(
                    item: item,
                    viewModel: viewModel,
                    onTap: {
                        onItemTap(item)
                    },
                    onDelete: {
                        onItemDelete()
                    }
                )
            }
        }
    }
}

struct ShoppingListDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: ShoppingListDetailViewModel
    @State private var manageItemConfig: ManageItemConfig?
    @State private var showingEditListView = false

    init(shoppingList: ShoppingList, context: NSManagedObjectContext) {
        _viewModel = StateObject(wrappedValue: ShoppingListDetailViewModel(shoppingList: shoppingList, context: context))
    }

    private struct ManageItemConfig: Identifiable {
        let id: UUID
        let viewModel: ManageItemViewModel
        let isPresented: Bool

        init(viewModel: ManageItemViewModel, item: Item?) {
            self.id = item?.id ?? UUID()
            self.viewModel = viewModel
            self.isPresented = true
        }
    }

    var body: some View {
        List {
            // Render unpicked sections first, sorted by storeSection
            ForEach(viewModel.groupedItems.keys.sorted().filter { $0 != "Itens Comprados" }, id: \.self) { section in
                SectionView(
                    section: section,
                    items: viewModel.groupedItems[section]!,
                    viewModel: viewModel,
                    onItemTap: { item in
                        print("Editando item: \(item.name ?? "Sem nome")")
                        openManageItemView(for: item)
                    },
                    onItemDelete: {
                        viewModel.refreshGroupedItems()
                    }
                )
            }
            // Render "Itens Comprados" section last, if it exists
            if let pickedItems = viewModel.groupedItems["Itens Comprados"], !pickedItems.isEmpty {
                SectionView(
                    section: "Itens Comprados",
                    items: pickedItems,
                    viewModel: viewModel,
                    onItemTap: { item in
                        print("Editando item: \(item.name ?? "Sem nome")")
                        openManageItemView(for: item)
                    },
                    onItemDelete: {
                        viewModel.refreshGroupedItems()
                    }
                )
            }
        }
        .navigationTitle(viewModel.shoppingList.name ?? "Lista")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button(action: {
                    print("Editando lista: \(viewModel.shoppingList.name ?? "sem nome")")
                    showingEditListView = true
                }) {
                    Label("Editar Lista", systemImage: "pencil")
                }
                Button(action: {
                    print("Adicionando novo item")
                    openManageItemView(for: nil)
                }) {
                    Label("Adicionar Item", systemImage: "plus")
                }
            }
        }
        .sheet(item: $manageItemConfig) { config in
            ManageItemView(viewModel: config.viewModel)
                .onAppear {
                    print("ManageItemView apresentada com nome: \(config.viewModel.name)")
                }
                .onDisappear {
                    print("ManageItemView dispensada")
                    viewModel.refreshGroupedItems()
                }
        }
        .sheet(isPresented: $showingEditListView) {
            NewShoppingListView(
                viewModel: ShoppingListViewModel(
                    context: viewContext,
                    user: viewModel.shoppingList.user!,
                    shoppingList: viewModel.shoppingList
                ),
                isEditMode: true
            )
        }
    }

    private func openManageItemView(for item: Item?) {
        print("Abrindo ManageItemView para item: \(item?.name ?? "novo")")
        let manageItemViewModel = ManageItemViewModel(
            shoppingListViewModel: viewModel.shoppingListViewModel,
            item: item,
            context: viewContext
        )
        print("ManageItemViewModel inicializado: name = \(manageItemViewModel.name), isEditMode = \(manageItemViewModel.isEditMode)")
        manageItemConfig = ManageItemConfig(viewModel: manageItemViewModel, item: item)
    }
}
