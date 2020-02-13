//
//  IAPService.swift
//
//  Created by Bradley GIlmore on 11/1/18.
//  Copyright © 2018 Bradley Gilmore. All rights reserved.
//

import Foundation
import StoreKit

class IAPService: NSObject {
    
    //MARK: - Singleton
    
    static let shared = IAPService()
    
    //MARK: - Properties
    
    var products = [SKProduct]()
    var paymentQueue = SKPaymentQueue.default()
    
    func getProducts() {
        // Set of all things in the IAPProduct Enum
        let products: Set = [IAPProduct.nonConsumable.rawValue]
        
        // Create the SKProductRequest
        let request = SKProductsRequest(productIdentifiers: products)
        
        // Setting delegate to self for the SKProductRequestDelegate
        request.delegate = self
        
        // Start that request
        request.start()
        
        // Observe Queue
        paymentQueue.add(self)
    }
    
    func purchase(product: IAPProduct) {
        
        // Get that product out of the products array
        guard let productToPurchase = products.filter({ $0.productIdentifier == product.rawValue }).first else {
            return
        }
        
        let payment = SKPayment(product: productToPurchase)
        paymentQueue.add(payment)
    }
    
    func restorePurchases() {
        print("Restoring Purchases")
        //paymentQueue.add(self)
        paymentQueue.restoreCompletedTransactions()
    }
    
    //MARK: - Initializers
    
    private override init() {
        super.init()
    }
    
}

extension IAPService: SKProductsRequestDelegate {
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        self.products = response.products
        for product in response.products {
            print(product.localizedTitle)
        }
    }
}

extension IAPService: SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            print(transaction.transactionState.status(), transaction.payment.productIdentifier)
            switch transaction.transactionState {
            case .purchasing: break
            case .purchased:
                NotificationCenter.default.post(.init(name: Notification.Name(rawValue: "purchasedSuccess")))
                queue.finishTransaction(transaction)
            case .restored:
                NotificationCenter.default.post(.init(name: Notification.Name(rawValue: "purchasedSuccess")))
                queue.finishTransaction(transaction)
            default: queue.finishTransaction(transaction)
            }
        }
    }
}

extension SKPaymentTransactionState {
    func status() -> String {
        switch self {
        case .deferred: return "Deferred"
        case .failed: return "Failed"
        case .purchased: return "Purchased"
        case .purchasing: return "Purchasing"
        case .restored: return "Restored"
        }
    }
}
