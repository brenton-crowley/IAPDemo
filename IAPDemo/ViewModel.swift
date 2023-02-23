//
//  ViewModel.swift
//  IAPDemo
//
//  Created by Brent Crowley on 10/2/2023.
//

import Foundation
import StoreKit

class ViewModel: ObservableObject, InAppPurchasable {
    
    @Published var products: [Product] = []
    @Published var purchasedProducts: [Product] = []
    
    // Alert
    @Published var alertMessage: String?
    @Published var showingAlert: Bool = false
    
    var sectionedProducts: [Product.ProductType :[Product]] {
        var groups: [Product.ProductType :[Product]] = [
            Product.ProductType.consumable:[],
            Product.ProductType.nonRenewable:[],
            Product.ProductType.nonConsumable:[],
            Product.ProductType.autoRenewable:[],
        ]
        self.products.forEach { product in
            groups[product.type]?.append(product)
        }
        return groups
    }
    
    let productIds: [String]
    var updateListenerTask: Task<Void, Error>?
    
    @MainActor
    init() {
        
        productIds = ViewModel.loadProductIDs()
        
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
            await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    @MainActor
    func purchase(product: Product) {
        Task {
            do {
                guard let _ = try await purchaseProduct(product) else { return }
                
            } catch {
                print(error)
            }
        }
    }
    
    @MainActor
    func getIsPurchasedForProduct(_ product: Product) async throws -> Bool {
        return try await isPurchased(product)
    }
    
    // user initiated
    func restorePurchases() {
        Task {
            try? await AppStore.sync()
        }
    }
    
}
