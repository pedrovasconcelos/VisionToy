//
//  BlurredBackgroundButton.swift
//  VisionToy
//
//  Created by Pedro Vasconcelos on 02/03/2018.
//  Copyright © 2018 Pedro Vasconcelos. All rights reserved.
//

import UIKit

@IBDesignable class BlurredBackgroundButton: UIButton {

    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = .clear
        clipsToBounds = true
        layer.cornerRadius = 5
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        // Add blurred background and make it resize when button changes size
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        insertSubview(blurView, at: 0)
        blurView.isUserInteractionEnabled = false
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        blurView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        blurView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        blurView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}
