//
//  ProgressViewFromCenter.swift
//  VisionToy
//
//  Created by Pedro Vasconcelos on 02/03/2018.
//  Copyright © 2018 Pedro Vasconcelos. All rights reserved.
//

import UIKit

/**
 A progress bar in which the progress is measured from its center.
 As progress increases, the progress bar grows from the center towards the edges.
 */
@IBDesignable class ProgressViewFromCenter: UIView {

    // MARK: - Properties
    
    private var progressView = UIView()
    private var progressViewWidthConstraint: NSLayoutConstraint?
    
    /// Progress must be a value between 0 and 1.
    @IBInspectable var progress: CGFloat = 0 {
        didSet {
            let newWidth = CGFloat(progress) * bounds.width
            progressViewWidthConstraint?.constant = newWidth
        }
    }
    
    @IBInspectable var progressBarColor: UIColor = UIColor(red: 1, green: 0, blue: 0.2925590804, alpha: 1) {
        didSet {
            progressView.backgroundColor = progressBarColor
        }
    }
    
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
        // Create the progress view
        addSubview(progressView)
        progressView.backgroundColor = progressBarColor
        
        // Setup constraints
        progressView.translatesAutoresizingMaskIntoConstraints = false
        progressView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        progressView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        progressView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        progressViewWidthConstraint = progressView.widthAnchor.constraint(equalToConstant: 0)
        progressViewWidthConstraint?.isActive = true
    }
}
