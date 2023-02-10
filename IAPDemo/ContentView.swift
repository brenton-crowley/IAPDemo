//
//  ContentView.swift
//  IAPDemo
//
//  Created by Brent Crowley on 9/2/2023.
//

import SwiftUI

struct ContentView: View {
    
    @ObservedObject private var viewModel = ViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.products) { product in
                HStack {
                    Image(systemName: "globe")
                        .imageScale(.large)
                        .foregroundColor(.accentColor)
                    Text(product.displayName)
                    Spacer()
                    Button(product.displayPrice) {
                     // purchase
                        print("purchase")
                    }
                }
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
