//
//  SheetCollectionViewLayout.swift
//  ImagePickerSheetController
//
//  Created by Laurin Brandner on 26/08/15.
//  Copyright © 2015 Laurin Brandner. All rights reserved.
//

import UIKit

class SheetCollectionViewLayout: UICollectionViewLayout {

    private var layoutAttributes = [[UICollectionViewLayoutAttributes]]()
    private var invalidatedLayoutAttributes: [[UICollectionViewLayoutAttributes]]?
    private var contentSize = CGSizeZero
    
    // MARK: - Layout
    
    override func prepareLayout() {
        super.prepareLayout()
        
        layoutAttributes.removeAll(keepCapacity: false)
        contentSize = CGSizeZero
        
        if let collectionView = collectionView,
            dataSource = collectionView.dataSource,
            delegate = collectionView.delegate as? UICollectionViewDelegateFlowLayout {
                let sections = dataSource.numberOfSectionsInCollectionView?(collectionView) ?? 0
                var origin = CGPoint()
                
                for section in 0 ..< sections {
                    var sectionAttributes = [UICollectionViewLayoutAttributes]()
                    let items = dataSource.collectionView(collectionView, numberOfItemsInSection: section)
                    let indexPaths = (0 ..< items).map { NSIndexPath(forItem: $0, inSection: section) }
                    
                    for indexPath in indexPaths {
                        let size = delegate.collectionView?(collectionView, layout: self, sizeForItemAtIndexPath: indexPath) ?? CGSizeZero
                        
                        let attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
                        attributes.frame = CGRect(origin: origin, size: size)
                        
                        sectionAttributes.append(attributes)
                        origin.y = attributes.frame.maxY
                    }

                    layoutAttributes.append(sectionAttributes)
                }
                
                contentSize = CGSize(width: collectionView.frame.width, height: origin.y)
        }
    }
    
    override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
        return true
    }
    
    override func invalidateLayout() {
        invalidatedLayoutAttributes = layoutAttributes
        super.invalidateLayout()
    }
    
    override func collectionViewContentSize() -> CGSize {
        return contentSize
    }
    
    override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        return layoutAttributes.reduce([], combine: +)
                               .filter { CGRectIntersectsRect(rect, $0.frame) }
    }
    
    private func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath, allAttributes: [[UICollectionViewLayoutAttributes]]) -> UICollectionViewLayoutAttributes? {
        guard allAttributes.count > indexPath.section && allAttributes[indexPath.section].count > indexPath.item else {
            return nil
        }
        
        return allAttributes[indexPath.section][indexPath.item]
    }
    
    private func invalidatedLayoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        guard let invalidatedLayoutAttributes = invalidatedLayoutAttributes else {
            return nil
        }
        
        return layoutAttributesForItemAtIndexPath(indexPath, allAttributes: invalidatedLayoutAttributes)
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributesForItemAtIndexPath(indexPath, allAttributes: layoutAttributes)
    }
    
    override func initialLayoutAttributesForAppearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return invalidatedLayoutAttributesForItemAtIndexPath(itemIndexPath) ?? layoutAttributesForItemAtIndexPath(itemIndexPath)
     }
    
    override func finalLayoutAttributesForDisappearingItemAtIndexPath(itemIndexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
        return layoutAttributesForItemAtIndexPath(itemIndexPath)
    }
    
}
