//
//  UIView+Utils.swift
//  Panels-iOS
//
//  Created by Antonio Casero on 10.08.18.
//  Copyright © 2018 Panels. All rights reserved.
//

import UIKit

internal extension UIView {
    func pinSuperview() {
        guard let superview = self.superview else {
            return
        }
        translatesAutoresizingMaskIntoConstraints = false
        addSuperviewConstraint(constraint: topAnchor.constraint(equalTo: superview.topAnchor))
        addSuperviewConstraint(constraint: leftAnchor.constraint(equalTo: superview.leftAnchor))
        addSuperviewConstraint(constraint: bottomAnchor.constraint(equalTo: superview.bottomAnchor))
        addSuperviewConstraint(constraint: rightAnchor.constraint(equalTo: superview.rightAnchor))
    }

    func addSuperviewConstraint(constraint: NSLayoutConstraint) {
        superview?.addConstraint(constraint)
    }

    func animateLayoutBounce(duration: Double = 0.6, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0,
                       options: .curveEaseOut,
                       animations: {
                           self.layoutIfNeeded()
                       }, completion: { _ in
                           completion?()
        })
    }

    // retrieves all constraints that mention the view
    func getAllConstraints() -> [NSLayoutConstraint] {
        // array will contain self and all superviews
        var views = [self]

        // get all superviews
        var view = self
        while let superview = view.superview {
            views.append(superview)
            view = superview
        }

        // transform views to constraints and filter only those
        // constraints that include the view itself
        return views.flatMap { $0.constraints }.filter { constraint in
            constraint.firstItem as? UIView == self ||
                constraint.secondItem as? UIView == self
        }
    }

    func getHeightConstraint() -> NSLayoutConstraint? {
        return getAllConstraints().filter {
            ($0.firstAttribute == .height && $0.firstItem as? UIView == self) ||
                ($0.secondAttribute == .height && $0.secondItem as? UIView == self)
        }.first
    }
}

internal extension UIApplication {
    class func safeAreaBottom() -> CGFloat {
        let window = UIApplication.shared.keyWindow ?? UIApplication.shared.windows.first
        let bottomPadding: CGFloat
        if #available(iOS 11.0, *) {
            bottomPadding = window?.safeAreaInsets.bottom ?? 0.0
        } else {
            bottomPadding = 0.0
        }
        return bottomPadding
    }

    class func safeAreaTop() -> CGFloat {
        let window = UIApplication.shared.keyWindow ?? UIApplication.shared.windows.first
        let bottomPadding: CGFloat
        if #available(iOS 11.0, *) {
            bottomPadding = window?.safeAreaInsets.top ?? 0.0
        } else {
            bottomPadding = 0.0
        }
        return bottomPadding
    }
}

extension Optional {
    func then<T>(_ action: (Wrapped) throws -> T?) rethrows -> T? {
        guard let unwrapped = self else { return nil }
        return try action(unwrapped)
    }

    func `do`(_ some: () throws -> Void) rethrows {
        if self != nil { try some() }
    }
}
