//
//  IAPManager.swift
//  IAPDemo
//
//  Created by Brent Crowley on 10/2/2023.
//

import Foundation
import StoreKit

class IAPManager: ObservableObject {
    
    enum IAPManagerError: Error {
        case noProductIDsFound
        case noProductsFound
        case paymentWasCancelled
        case paymentFailed
        case productRequestFailed
        case failedVerification
    }
    
    static let shared = IAPManager()
    
    var updateListenerTask: Task<Void, Error>? = nil
    
    @Published private(set) var products: [Product.ProductType: [Product]] = [:]
    
    private let productIds: [String]
    
    private init() {
        
        productIds = IAPManager.loadProductIDs()
        updateListenerTask = listenForTransactions()
        
        Task {
            await requestProducts()
        }
        
    }
    
    // load the product ids from the bundle resource
    static private func loadProductIDs() -> [String] {
        
        guard let url = Bundle.main.url(forResource: "IAPProductIDs", withExtension: "plist"),
              let plist = try? Data(contentsOf: url),
              let data = try? PropertyListSerialization.propertyList(from:plist, format: nil) as? [String] else {
            print("Couldn't make plist")
            return []
        }
        
        return data
    }
    
    // get the list of products
    @MainActor
    func requestProducts() async -> [Product.ProductType: [Product]] {
        
        do {
            let storeProducts = try await Product.products(for: productIds)
            var consumables: [Product] = []
            var nonconsumables: [Product] = []
            var renewableSubscriptions: [Product] = []
            var nonRenewableSubscriptions: [Product] = []
            
            for product in storeProducts {
                switch product.type {
                    
                case .consumable:
                    consumables.append(product)
                case .nonConsumable:
                    nonconsumables.append(product)
                case .autoRenewable:
                    renewableSubscriptions.append(product)
                case .nonRenewable:
                    nonRenewableSubscriptions.append(product)
                default:
                    print("unknown product")
                }
            }
            
            // store each of the different products in a dictionary full of products.
            // we can easily create a computed property of all the products or convenience
            products[Product.ProductType.consumable] = sortByPrice(consumables)
            products[Product.ProductType.nonConsumable] = sortByPrice(nonconsumables)
            products[Product.ProductType.autoRenewable] = sortByPrice(renewableSubscriptions)
            products[Product.ProductType.nonRenewable] = sortByPrice(nonRenewableSubscriptions)
            
        } catch {
            print("Failed product request from the App Store server: \(error)")
        }
        
        return products
    }
    
    // purchase method for products
    
    
    // method to listen for transactions across devices or when approval is needed for a transaction.
    private func listenForTransactions() -> Task<Void, Error> {
        
        return .detached {
            
            // iterate through any transactions that don't come for a direct call to purchase
            // For example, if you make a purchase on another device.
            for await result in Transaction.updates {
                
                do {
                    switch result {
                    case .verified(let transaction):
                        // update customer product status
                        await transaction.finish() // always complete a transaction
                    case .unverified:
                        throw IAPManagerError.failedVerification
                    }
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
    
    private func sortByPrice(_ products: [Product]) -> [Product] {
        products.sorted(by: { return $0.price < $1.price })
    }
}
