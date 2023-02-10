//
//  ViewModel.swift
//  IAPDemo
//
//  Created by Brent Crowley on 10/2/2023.
//

import Foundation
import StoreKit
import Combine

class ViewModel: ObservableObject {
    
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProducts: [Product] = []
    
    init() {
        
    }
    
    @MainActor
    func getProducts() async {
        self.products = await IAPManager.shared.requestProducts().values.flatMap { $0 }
        
    }
}
