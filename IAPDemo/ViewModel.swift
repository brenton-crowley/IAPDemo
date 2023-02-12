//
//  ViewModel.swift
//  IAPDemo
//
//  Created by Brent Crowley on 10/2/2023.
//

import Foundation
import StoreKit
import Combine

class ViewModel: ObservableObject, InAppPurchasable {
    
    @Published var products: [Product] = []
    @Published var purchasedProducts: [Product] = []
    
    let productIds: [String]
    var updateListenerTask: Task<Void, Error>?
    
    @MainActor
    init() {
        
        productIds = ViewModel.loadProductIDs()
        
        updateListenerTask = listenForTransactions()
        
        Task {
            self.products = await requestProducts()
            self.purchasedProducts = await updateCustomerProductStatus()
        }
    }
    
    deinit {
        updateListenerTask?.cancel()
    }
    
    @MainActor
    func getProducts() async {
        self.products = await requestProducts()
    }
    
    @MainActor
    func purchase(product: Product) {
        Task{
            do {
                guard let result = try await purchaseProduct(product) else { return }
                    
                self.purchasedProducts = result.purchasedProducts
                
            } catch {
                print(error)
            }
        }
    }
    
    @MainActor
    func getIsPurchasedForProduct(_ product: Product) async throws -> Bool {
        return try await isPurchased(product)
    }
}
