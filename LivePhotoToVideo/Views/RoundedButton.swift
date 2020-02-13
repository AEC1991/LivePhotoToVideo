//
//  RoundedButton.swift
//  Slader
//
//  Created by Bradley GIlmore on 11/2/18.
//  Copyright © 2018 Bradley Gilmore. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedButton: UIButton {
    
    @IBInspectable var borderWidth: CGFloat = 3.0 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor: CGColor = UIColor.white.cgColor {
        didSet {
            self.layer.borderColor = borderColor
        }
    }
    
    override func awakeFromNib() {
        self.setupView()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        self.setupView()
    }
    
    func setupView() {
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor
    }
    
}

