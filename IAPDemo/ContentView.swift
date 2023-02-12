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
            .padding()
        }
        .onAppear {
            Task {
                await viewModel.getProducts()
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
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text(product.displayName)
            Spacer()
            Button(product.displayPrice) {
             // purchase
                print("purchase")
                viewModel.purchase(product: product)
            }
            .buttonStyle(BuyButtonStyle(isPurchased: isPurchased))
            .disabled(isPurchased)
            .onReceive(viewModel.$purchasedProducts) { newValue in
                Task {
                    isPurchased = (try? await viewModel.getIsPurchasedForProduct(product)) ?? false
                }
            }
        }
    }
}
                                 
struct BuyButtonStyle: ButtonStyle {
    let isPurchased: Bool

    init(isPurchased: Bool = false) {
        self.isPurchased = isPurchased
    }

    func makeBody(configuration: Self.Configuration) -> some View {
        var bgColor: Color = isPurchased ? Color.green : Color.blue
        bgColor = configuration.isPressed ? bgColor.opacity(0.7) : bgColor.opacity(1)

        return configuration.label
            .frame(width: 50)
            .padding(10)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct BuyButtonStyle_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            Button(action: {}) {
                Text("Buy")
                    .foregroundColor(.white)
                    .bold()
            }
            .buttonStyle(BuyButtonStyle())
            .previewDisplayName("Normal")
            
            Button(action: {}) {
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
            }
            .buttonStyle(BuyButtonStyle(isPurchased: true))
            .previewDisplayName("Purchased")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
