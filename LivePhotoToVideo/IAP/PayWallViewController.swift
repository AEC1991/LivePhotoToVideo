//
//  PayWallViewController.swift
//
//  Copyright © 2018 Bradley Gilmore. All rights reserved.
//

import UIKit
import Mixpanel
import StoreKit

class PayWallViewController: UIViewController {
    
    //MARK: - IBOutlets
    
    @IBOutlet weak var orderNowButton: UIButton!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var backgroundImage: UIImageView!
    @IBOutlet weak var mainTitle: UILabel!
    @IBOutlet weak var subTitle: UILabel!
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var alreadyAMember: UIButton!
    
    //MARK: - Properties
    
    var isPurchased: Bool {
        return UserDefaults.standard.bool(forKey: "isPurchased")
    }
    
    //MARK: - Status Bar
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(purchaseWasSuccessful), name: .purchasedSuccess, object: nil)
        
        if isPurchased {
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "toMainView", sender: self)
            }
        } else {
            print("Not yet purchased")
        }
        
        // IAP
        IAPService.shared.getProducts()
        
        // MixPanel Related Tweaks
        
        //self.priceLabel.text = MixpanelTweaks.assign(MixpanelTweaks.priceTweak)
        self.orderNowButton.setTitle(MixpanelTweaks.assign(MixpanelTweaks.orderButtonText), for: .normal)
        self.mainTitle.text = MixpanelTweaks.assign(MixpanelTweaks.mainTitleText)
        self.subTitle.text = MixpanelTweaks.assign(MixpanelTweaks.subTitleText)
        self.alreadyAMember.setTitle(MixpanelTweaks.assign(MixpanelTweaks.alreadyAMemberText), for: .normal)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Set Rounded Button
        orderNowButton.layer.cornerRadius = orderNowButton.frame.size.height/2//TODO: - Confirm this is good cornerRadius wise
        orderNowButton.clipsToBounds = true
        
        // Auto Resize Labels if needed
        priceLabel.adjustsFontSizeToFitWidth = true
        priceLabel.minimumScaleFactor = 0.5
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }

    
    //MARK: - IBActions
    func canMakePurchases() -> Bool { return SKPaymentQueue.canMakePayments() }
    
    @IBAction func orderNowButtonTapped(_ sender: Any) {
        
        self.performSegue(withIdentifier: "toMainView", sender: self)
        
//        // Order through IAP
//        if self.canMakePurchases() {
//            IAPService.shared.purchase(product: .nonConsumable)
//           /* SKPayment *payment = [SKPayment paymentWithProductIdentifier:identifier];
//            [[SKPaymentQueue defaultQueue] addPayment:payment];*/
//        } else {
//            NSLog("In-App Purchases are not allowed");
//        }
        
    }
    
    @IBAction func restorePurchasesButtonTapped(_ sender: Any) {
        // Restore Purchases
        IAPService.shared.restorePurchases()
    }
    
    @IBAction func xButtonTapped(_ sender: Any) {
        Mixpanel.mainInstance().track(event: "XButtonTapped", properties: nil)
        self.performSegue(withIdentifier: "toMainView", sender: self)
        
    }
    
    @IBAction func termsAndServiceButtonTapped(_ sender: Any) {
        guard let url = URL(string: "https://audreycam.tumblr.com/post/179397033417/our-ios-mobile-app-operates-on-user-data-according") else {
          return //be safe
        }

        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
    // IAP Success
    
    @objc func purchaseWasSuccessful() {
        UserDefaults.standard.set(true, forKey: "isPurchased")
        DispatchQueue.main.async {
            print("Should be going to main view")
            self.performSegue(withIdentifier: "toMainView", sender: self)
        }
    }
    
}

extension Notification.Name {
    static let purchasedSuccess = Notification.Name("purchasedSuccess")
}

//Mixpanel related

extension MixpanelTweaks {
    public static let priceTweak = Tweak(tweakName: "Price Label", defaultValue: "$19.99 one time purchase")
    public static let orderButtonText = Tweak(tweakName: "Order Now", defaultValue: "ORDER NOW")
    public static let mainTitleText = Tweak(tweakName: "Main Title", defaultValue: "Flipagram Pro")
    public static let subTitleText = Tweak(tweakName: "Sub Title", defaultValue: "Unlimited Slideshows & No Ads")
    public static let alreadyAMemberText = Tweak(tweakName: "Restore Purchases", defaultValue: "Restore Purchase")
}

