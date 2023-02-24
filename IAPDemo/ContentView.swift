//
//  ContentView.swift
//  IAPDemo
//
//  Created by Brent Crowley on 9/2/2023.
//

import SwiftUI
import StoreKit

struct ContentView: View {
    
    @ObservedObject private var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.products) { product in
                ProductRow(product: product, viewModel: viewModel)

            }
            .toolbar {
                Button {
                    viewModel.restorePurchases()
                } label: {
                    Text("Restore")
                }
                
            }
            .alert(viewModel.alertMessage ?? "",
                   isPresented: $viewModel.showingAlert) {
                Button("OK", role: .cancel) {
                    viewModel.alertMessage = nil
                }
            }
            
        }
    }
    
    var sections: some View {
        
        List {
            
            Section(Product.ProductType.consumable.localizedDescription) {
                ForEach(viewModel.sectionedProducts[Product.ProductType.consumable] ?? []) { consumable in
                    Text(consumable.displayName)
                }
            }

            Section(Product.ProductType.nonConsumable.localizedDescription) {
                ForEach(viewModel.sectionedProducts[Product.ProductType.nonConsumable] ?? []) { consumable in
                    Text(consumable.displayName)
                }
            }
            
            Section(Product.ProductType.autoRenewable.localizedDescription) {
                ForEach(viewModel.sectionedProducts[Product.ProductType.autoRenewable] ?? []) { consumable in
                    Text(consumable.displayName)
                }
            }
            
            Section(Product.ProductType.nonRenewable.localizedDescription) {
                ForEach(viewModel.sectionedProducts[Product.ProductType.nonRenewable] ?? []) { consumable in
                    Text(consumable.displayName)
                }
            }
        }
        
    }
}

struct ProductRow: View {
    
    var product: Product
    var viewModel: ViewModel
    
    @State var isPurchased: Bool = false
    
    var body: some View {
        HStack {
            Text(product.displayName)
            Spacer()
            Button(isPurchased ? "✅" : product.displayPrice) {
                // purchase
                print("purchase")
                viewModel.purchase(product: product)
            }
            .disabled(isPurchased)
            .onReceive(viewModel.$purchasedProducts) { newValue in
                Task {
                    isPurchased = (try? await viewModel.getIsPurchasedForProduct(product)) ?? false
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
