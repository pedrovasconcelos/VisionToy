//
//  ClassificationTableViewCell.swift
//  VisionToy
//
//  Created by Pedro Vasconcelos on 02/03/2018.
//  Copyright © 2018 Pedro Vasconcelos. All rights reserved.
//

import UIKit

class ClassificationTableViewCell: UITableViewCell {

    // MARK: - IBOutlets
    
    @IBOutlet weak var classificationLabel: UILabel!
    @IBOutlet weak var confidenceProgressView: ProgressViewFromCenter!
}

// MARK: - Public

extension ClassificationTableViewCell {
    func configureFor(classification: String? = nil, confidence: CGFloat) {
        if let classification = classification {
            classificationLabel.text = classification
        }
        
        confidenceProgressView.progress = confidence
    }
}
