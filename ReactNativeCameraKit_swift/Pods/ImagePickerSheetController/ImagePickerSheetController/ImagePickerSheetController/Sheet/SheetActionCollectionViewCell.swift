//
//  SheetActionCollectionViewCell.swift
//  ImagePickerSheetController
//
//  Created by Laurin Brandner on 26/08/15.
//  Copyright © 2015 Laurin Brandner. All rights reserved.
//

import UIKit

let KVOContext = UnsafeMutablePointer<()>()

class SheetActionCollectionViewCell: SheetCollectionViewCell {
    
    lazy private(set) var textLabel: UILabel = {
        let label = UILabel()
        label.textColor = self.tintColor
        label.textAlignment = .Center
        
        self.addSubview(label)
        
        return label
    }()
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    private func initialize() {
        textLabel.addObserver(self, forKeyPath: "text", options: NSKeyValueObservingOptions(rawValue: 0), context: KVOContext)
    }
    
    deinit {
        textLabel.removeObserver(self, forKeyPath: "text")
    }
    
    // MARK: - Accessibility
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == KVOContext else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        
        accessibilityLabel = textLabel.text
    }
    
    // MARK: -
    
    override func tintColorDidChange() {
        super.tintColorDidChange()
        
        textLabel.textColor = tintColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textLabel.frame = UIEdgeInsetsInsetRect(bounds, backgroundInsets)
    }
    
}
