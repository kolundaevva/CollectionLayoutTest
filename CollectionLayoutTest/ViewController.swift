//
//  ViewController.swift
//  CollectionLayoutTest
//
//  Created by Владислав Колундаев on 21.03.2024.
//

import UIKit

protocol LayoutAttributesAnimator {
    func animate(collectionView: UICollectionView, attributes: CubeCollectionViewLayoutAttributes)
}

final class CubeCollectionViewLayout: UICollectionViewFlowLayout {

    var animator: LayoutAttributesAnimator?

    override class var layoutAttributesClass: AnyClass { return CubeCollectionViewLayoutAttributes.self }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }
        return attributes.compactMap { $0.copy() as? CubeCollectionViewLayoutAttributes }.map { self.transformLayoutAttributes($0) }
    }

    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        true
    }

    private func transformLayoutAttributes(_ attributes: CubeCollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {

        guard let collectionView = self.collectionView else { return attributes }

        let cachedAttributes = attributes
        let distance: CGFloat
        let itemOffset: CGFloat

        if scrollDirection == .horizontal {
            distance = collectionView.frame.width
            itemOffset = cachedAttributes.center.x - collectionView.contentOffset.x
            cachedAttributes.startOffset = (cachedAttributes.frame.origin.x - collectionView.contentOffset.x) / cachedAttributes.frame.width
            cachedAttributes.endOffset = (cachedAttributes.frame.origin.x - collectionView.contentOffset.x - collectionView.frame.width) / cachedAttributes.frame.width
        } else {
            distance = collectionView.frame.height
            itemOffset = cachedAttributes.center.y - collectionView.contentOffset.y
            cachedAttributes.startOffset = (cachedAttributes.frame.origin.y - collectionView.contentOffset.y) / cachedAttributes.frame.height
            cachedAttributes.endOffset = (cachedAttributes.frame.origin.y - collectionView.contentOffset.y - collectionView.frame.height) / cachedAttributes.frame.height
        }

        cachedAttributes.scrollDirection = scrollDirection
        cachedAttributes.middleOffset = itemOffset / distance - 0.5

        if cachedAttributes.contentView == nil,
           let contentView = collectionView.cellForItem(at: attributes.indexPath)?.contentView {
            cachedAttributes.contentView = contentView
        }

        animator?.animate(collectionView: collectionView, attributes: cachedAttributes)

        return cachedAttributes
    }
}

final class CubeCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
    var contentView: UIView?
    var scrollDirection: UICollectionView.ScrollDirection = .vertical
    var startOffset: CGFloat = 0
    var middleOffset: CGFloat = 0
    var endOffset: CGFloat = 0

    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! CubeCollectionViewLayoutAttributes
        copy.contentView = contentView
        copy.scrollDirection = scrollDirection
        copy.startOffset = startOffset
        copy.middleOffset = middleOffset
        copy.endOffset = endOffset
        return copy
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let o = object as? CubeCollectionViewLayoutAttributes else { return false }

        return super.isEqual(o)
            && o.contentView == contentView
            && o.scrollDirection == scrollDirection
            && o.startOffset == startOffset
            && o.middleOffset == middleOffset
            && o.endOffset == endOffset
    }
}

struct CubeAttributesAnimator: LayoutAttributesAnimator {
    var perspective: CGFloat
    var totalAngle: CGFloat

    init(perspective: CGFloat = -1 / 500, totalAngle: CGFloat = .pi / 2) {
        self.perspective = perspective
        self.totalAngle = totalAngle
    }

    func animate(collectionView: UICollectionView, attributes: CubeCollectionViewLayoutAttributes) {
        let position = attributes.middleOffset

        guard let contentView = attributes.contentView else { return }

        if abs(position) >= 1 {
            contentView.layer.transform = CATransform3DIdentity
            contentView.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        } else if attributes.scrollDirection == .horizontal {
            let rotateAngle = totalAngle * position
            let anchorPoint = CGPoint(x: position > 0 ? 0 : 1, y: 0.5)

            let anchorPointOffsetValue = contentView.layer.bounds.width / 2
            let anchorPointOffset = position > 0 ? -anchorPointOffsetValue : anchorPointOffsetValue

            var transform = CATransform3DMakeTranslation(anchorPointOffset, 0, 0)
            transform.m34 = perspective
            transform = CATransform3DRotate(transform, rotateAngle, 0, 1, 0)

            contentView.layer.transform = transform
            contentView.layer.anchorPoint = anchorPoint
        } else {
            let rotateAngle = totalAngle * position
            let anchorPoint = CGPoint(x: 0.5, y: position > 0 ? 0 : 1)

            let anchorPointOffsetValue = contentView.layer.bounds.height / 2
            let anchorPointOffset = position > 0 ? -anchorPointOffsetValue : anchorPointOffsetValue

            var transform = CATransform3DMakeTranslation(0, anchorPointOffset, 0)
            transform.m34 = perspective
            transform = CATransform3DRotate(transform, rotateAngle, -1, 0, 0)

            contentView.layer.transform = transform
            contentView.layer.anchorPoint = anchorPoint
        }
    }
}

class SimpleCollectionViewCell: UICollectionViewCell {

//    private let titleLabel = UILabel()

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear

//        addSubview(titleLabel)
//        titleLabel.translatesAutoresizingMaskIntoConstraints = false
//
//        titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
//        titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
//        titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    func bind(color: String, imageName: String) {
        contentView.backgroundColor = color.hexColor
//        titleLabel.text = "123"
    }
}

extension String {
    var hexColor: UIColor {
        let hex = trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return .clear
        }
        return UIColor(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}


class CollectionViewController: UICollectionViewController {

    var animator: (LayoutAttributesAnimator, Bool, Int, Int)?
    var direction: UICollectionView.ScrollDirection = .horizontal

    let cellIdentifier = "SimpleCollectionViewCell"
    let vcs = [("f44336", "nature1"),
               ("9c27b0", "nature2"),
               ("3f51b5", "nature3"),
               ("03a9f4", "animal1"),
               ("009688", "animal2"),
               ("8bc34a", "animal3"),
               ("FFEB3B", "nature1"),
               ("FF9800", "nature2"),
               ("795548", "nature3"),
               ("607D8B", "animal1")]

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView?.isPagingEnabled = true

        if let layout = collectionView?.collectionViewLayout as? CubeCollectionViewLayout {
            layout.scrollDirection = direction
            layout.animator = animator?.0
        }
    }
}

extension CollectionViewController: UICollectionViewDelegateFlowLayout {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int(Int16.max)
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let c = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)

        if let cell = c as? SimpleCollectionViewCell {
            let i = indexPath.row % vcs.count
            let v = vcs[i]
            cell.bind(color: v.0, imageName: v.1)
            cell.clipsToBounds = animator?.1 ?? true
        }

        return c
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let animator = animator else { return view.bounds.size }
        return CGSize(width: view.bounds.width / CGFloat(animator.2), height: view.bounds.height / CGFloat(animator.3))
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
