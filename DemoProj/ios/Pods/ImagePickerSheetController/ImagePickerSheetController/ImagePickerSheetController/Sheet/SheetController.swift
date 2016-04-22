//
//  SheetController.swift
//  ImagePickerSheetController
//
//  Created by Laurin Brandner on 27/08/15.
//  Copyright © 2015 Laurin Brandner. All rights reserved.
//

import UIKit

private let defaultInset: CGFloat = 10

class SheetController: NSObject {
    
    private(set) lazy var sheetCollectionView: UICollectionView = {
        let layout = SheetCollectionViewLayout()
        let collectionView = UICollectionView(frame: CGRect(), collectionViewLayout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.accessibilityIdentifier = "ImagePickerSheet"
        collectionView.backgroundColor = .clearColor()
        collectionView.alwaysBounceVertical = false
        collectionView.registerClass(SheetPreviewCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(SheetPreviewCollectionViewCell.self))
        collectionView.registerClass(SheetActionCollectionViewCell.self, forCellWithReuseIdentifier: NSStringFromClass(SheetActionCollectionViewCell.self))
        
        return collectionView
    }()
    
    var previewCollectionView: PreviewCollectionView
    
    private(set) var actions = [ImagePickerAction]()
    
    var actionHandlingCallback: (() -> ())?
    
    private(set) var previewHeight: CGFloat = 0
    var numberOfSelectedImages = 0
    
    var preferredSheetHeight: CGFloat {
        return allIndexPaths().map { self.sizeForSheetItemAtIndexPath($0).height }
            .reduce(0, combine: +)
    }
    
    var preferredSheetWidth: CGFloat {
        guard #available(iOS 9, *) else {
            return sheetCollectionView.bounds.width
        }
        return sheetCollectionView.bounds.width - 2 * defaultInset
    }
    
    // MARK: - Initialization
    
    init(previewCollectionView: PreviewCollectionView) {
        self.previewCollectionView = previewCollectionView
        
        super.init()
    }
    
    // MARK: - Data Source
    // These methods are necessary so that no call cycles happen when calculating some design attributes
    
    private func numberOfSections() -> Int {
        return 2
    }
    
    private func numberOfItemsInSection(section: Int) -> Int {
        if section == 0 {
            return 1
        }
        
        return actions.count
    }
    
    private func allIndexPaths() -> [NSIndexPath] {
        let s = numberOfSections()
        return (0 ..< s).map { (self.numberOfItemsInSection($0), $0) }
                        .flatMap { numberOfItems, section in
                            (0 ..< numberOfItems).map { NSIndexPath(forItem: $0, inSection: section) }
                        }
    }
    
    private func sizeForSheetItemAtIndexPath(indexPath: NSIndexPath) -> CGSize {
        let height: CGFloat = {
            if indexPath.section == 0 {
                return previewHeight
            }
            
            let actionItemHeight: CGFloat
            
            if #available(iOS 9, *) {
                actionItemHeight = 57
            }
            else {
                actionItemHeight = 50
            }
            
            let insets = attributesForItemAtIndexPath(indexPath).backgroundInsets
            return actionItemHeight + insets.top + insets.bottom
        }()
        
        return CGSize(width: sheetCollectionView.bounds.width, height: height)
    }
    
    // MARK: - Design
    
    private func attributesForItemAtIndexPath(indexPath: NSIndexPath) -> (corners: RoundedCorner, backgroundInsets: UIEdgeInsets) {
        guard #available(iOS 9, *) else {
            return (.None, UIEdgeInsets())
        }
        
        let cornerRadius: CGFloat = 13
        let innerInset: CGFloat = 4
        var indexPaths = allIndexPaths()
        
        guard indexPaths.first != indexPath else {
            return (.Top(cornerRadius), UIEdgeInsets(top: 0, left: defaultInset, bottom: 0, right: defaultInset))
        }
        
        let cancelIndexPath = actions.indexOf { $0.style == ImagePickerActionStyle.Cancel }
                                     .map { NSIndexPath(forItem: $0, inSection: 1) }
        
        
        if let cancelIndexPath = cancelIndexPath {
            if cancelIndexPath == indexPath {
                return (.All(cornerRadius), UIEdgeInsets(top: innerInset, left: defaultInset, bottom: defaultInset, right: defaultInset))
            }
            
            indexPaths.removeLast()
            
            if indexPath == indexPaths.last {
                return (.Bottom(cornerRadius), UIEdgeInsets(top: 0, left: defaultInset, bottom: innerInset, right: defaultInset))
            }
        }
        else if indexPath == indexPaths.last {
            return (.Bottom(cornerRadius), UIEdgeInsets(top: 0, left: defaultInset, bottom: defaultInset, right: defaultInset))
        }
        
        return (.None, UIEdgeInsets(top: 0, left: defaultInset, bottom: 0, right: defaultInset))
    }
    
    private func fontForAction(action: ImagePickerAction) -> UIFont {
        guard #available(iOS 9, *), action.style == .Cancel else {
            return UIFont.systemFontOfSize(21)
        }
        
        return UIFont.boldSystemFontOfSize(21)
    }
    
    // MARK: - Actions
    
    func reloadActionItems() {
        sheetCollectionView.reloadSections(NSIndexSet(index: 1))
    }
    
    func addAction(action: ImagePickerAction) {
        if action.style == .Cancel {
            actions = actions.filter { $0.style != .Cancel }
        }
        
        actions.append(action)
        
        if let index = actions.indexOf({ $0.style == .Cancel }) {
            let cancelAction = actions.removeAtIndex(index)
            actions.append(cancelAction)
        }
        
        reloadActionItems()
    }
    
    private func handleAction(action: ImagePickerAction) {
        actionHandlingCallback?()
        action.handle(numberOfSelectedImages)
    }
    
    func handleCancelAction() {
        let cancelAction = actions.filter { $0.style == ImagePickerActionStyle.Cancel }
                                  .first
        
        if let cancelAction = cancelAction {
            handleAction(cancelAction)
        }
        else {
            actionHandlingCallback?()
        }
    }
    
    // MARK: - 
    
    func setPreviewHeight(height: CGFloat, invalidateLayout: Bool) {
        previewHeight = height
        if invalidateLayout {
            sheetCollectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
}

extension SheetController: UICollectionViewDataSource {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return numberOfSections()
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return numberOfItemsInSection(section)
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: SheetCollectionViewCell
        
        if indexPath.section == 0 {
            let previewCell = collectionView.dequeueReusableCellWithReuseIdentifier(NSStringFromClass(SheetPreviewCollectionViewCell.self), forIndexPath: indexPath) as! SheetPreviewCollectionViewCell
            previewCell.collectionView = previewCollectionView
            
            cell = previewCell
        }
        else {
            let action = actions[indexPath.item]
            let actionCell = collectionView.dequeueReusableCellWithReuseIdentifier(NSStringFromClass(SheetActionCollectionViewCell.self), forIndexPath: indexPath) as! SheetActionCollectionViewCell
            actionCell.textLabel.font = fontForAction(action)
            actionCell.textLabel.text = numberOfSelectedImages > 0 ? action.secondaryTitle(numberOfSelectedImages) : action.title
            
            cell = actionCell
        }
        
        cell.separatorVisible = (indexPath.section == 1)
        
        // iOS specific design
        (cell.roundedCorners, cell.backgroundInsets) = attributesForItemAtIndexPath(indexPath)
        if #available(iOS 9, *) {
            cell.normalBackgroundColor = UIColor(white: 0.97, alpha: 1)
            cell.highlightedBackgroundColor = UIColor(white: 0.92, alpha: 1)
            cell.separatorColor = UIColor(white: 0.84, alpha: 1)
        }
        else {
            cell.normalBackgroundColor = .whiteColor()
            cell.highlightedBackgroundColor = UIColor(white: 0.85, alpha: 1)
            cell.separatorColor = UIColor(white: 0.784, alpha: 1)
        }
        
        return cell
    }
    
}

extension SheetController: UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return indexPath.section != 0
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        collectionView.deselectItemAtIndexPath(indexPath, animated: true)
        
        handleAction(actions[indexPath.item])
    }
    
}

extension SheetController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(collectionView: UICollectionView, layout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return sizeForSheetItemAtIndexPath(indexPath)
    }
    
}
