//
//  InAppPurchasable.swift
//  IAPDemo
//
//  Created by Brent Crowley on 10/2/2023.
//

import Foundation
import StoreKit

enum IAPManagerError: Error {
    case noProductIDsFound
    case noProductsFound
    case paymentWasCancelled
    case paymentFailed
    case productRequestFailed
    case failedVerification
}

protocol InAppPurchasable {
    
    static var productPlistName: String { get }

    var productIds: [String] { get }
    var products: [Product] { get set }
    var purchasedProducts: [Product] { get set }
    var updateListenerTask: Task<Void, Error>? { get }
    
    static func loadProductIDs() -> [String]
    
    func listenForTransactions() -> Task<Void, Error>
    func requestProducts() async -> [Product]
    func purchaseProduct(_ product:Product) async throws -> (transaction: Transaction?, purchasedProducts: [Product])?
    func isPurchased(_ product: Product) async throws -> Bool
    @discardableResult func updateCustomerProductStatus() async -> [Product]
}

// default variable implementation
extension InAppPurchasable {
    
    var products: [Product] { [] }
    var purchasedProducts: [Product] { [] }
    var productIds: [String] { [] }
    static var productPlistName: String { "IAPProductIDs" }
    
}

// MARK: - Load Product IDs from Plist
extension InAppPurchasable {
    
    static func loadProductIDs() -> [String] {
        
        guard let url = Bundle.main.url(forResource: productPlistName, withExtension: "plist"),
              let plist = try? Data(contentsOf: url),
              let data = try? PropertyListSerialization.propertyList(from:plist, format: nil) as? [String] else {
            print("Couldn't make plist")
            return []
        }
        
        return data
    }
}

// MARK: - Request Products
extension InAppPurchasable {
    
    func requestProducts() async -> [Product] {
        
        do {
            let storeProducts = try await Product.products(for: productIds)
            
            return sortByPrice(storeProducts)
            
        } catch {
            print("Failed product request from the App Store server: \(error)")
        }
        
        return []
    }
    
    private func sortByPrice(_ products: [Product]) -> [Product] {
        products.sorted(by: { return $0.price < $1.price })
    }
}

// MARK: - Purchase Product
extension InAppPurchasable {
    
    func purchaseProduct(_ product:Product) async throws -> (transaction: Transaction?, purchasedProducts: [Product])? {
        let result = try await product.purchase()
        
        switch result {
            
        case .success(let verification):
            // check whether or not the transaction is verified
            let transaction = try checkVerified(verification)
            
            let purchasedProducts = await updateCustomerProductStatus()
            
            await transaction.finish()
            
            return (transaction, purchasedProducts)
        case .userCancelled, .pending:
            return nil
        default:
            return nil
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        //Check whether the JWS passes StoreKit verification.
        switch result {
        case .unverified:
            //StoreKit parses the JWS, but it fails verification.
            throw IAPManagerError.failedVerification
        case .verified(let safe):
            //The result is verified. Return the unwrapped value.
            return safe
        }
    }
}

// MARK: - Update Products
extension InAppPurchasable {
    
    func updateCustomerProductStatus() async -> [Product] {
        var purchasedProducts: [Product] = []
        
        //iterate through all the user's purchased products - currentEntitlements doesn't return Consumable in-app purchases use all for that
        for await result in Transaction.currentEntitlements {
            do {
                //again check if transaction is verified
                switch result {
                case .verified(let transaction):
                    if let product = products.first(where: { $0.id == transaction.productID}) {
                        purchasedProducts.append(product)
                    }
                case .unverified:
                    throw  IAPManagerError.failedVerification
                }
                
            } catch {
                //storekit has a transaction that fails verification, don't delvier content to the user
                print("Transaction failed verification")
            }
            
            return purchasedProducts
        }
        return []
    }
    
}

// MARK: - Listen for transactions
extension InAppPurchasable {
    
    func listenForTransactions() -> Task<Void, Error> {
        
        return .detached {
            
            // iterate through any transactions that don't come for a direct call to purchase
            // For example, if you make a purchase on another device.
            for await result in Transaction.updates {
                
                do {
                    
                    let transaction = try self.checkVerified(result)
                    
                    // TODO: possible bug here as I'm not assigning the result to the purchased products. Could use a possible delegate call or change the signature of the function?
                    await self.updateCustomerProductStatus()
                    
                    await transaction.finish() // always complete a transaction
                } catch {
                    print("Transaction failed verification")
                }
            }
        }
    }
}

// MARK: - Request Products
extension InAppPurchasable {
    
    func isPurchased(_ product: Product) async throws -> Bool {
        purchasedProducts.contains { $0.id == product.id }
    }
}
