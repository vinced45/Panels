//
//  Created by Antonio Casero Palmero on 10.08.18.
//  Copyright © 2018 Panels. All rights reserved.
//

import UIKit

public class Panels {
    public weak var delegate: PanelNotifications?
    public var isExpanded: Bool {
        return (panelHeightConstraint?.constant ?? 0.0) > configuration.visibleArea()
    }

    private weak var panel: (Panelable & UIViewController)?
    private weak var parentViewController: UIViewController?
    private weak var containerView: UIView?
    private weak var panelHeightConstraint: NSLayoutConstraint?
    private lazy var configuration: PanelConfiguration = PanelConfiguration()
    private var panelHeight: CGFloat = 0.0
    
    var dimView: UIView?

    public init(target: UIViewController) {
        parentViewController = target
    }

    /// Add a viewcontainer to the view target. This subview is the panel definded in
    /// a storyboard and conform the protocol Panelable.
    /// - Parameters:
    ///   - config: Configuration panel, there you can define the panel behaviour
    ///   - target: Viewcontroller where the panel will be added as subview.
    ///   - view: Alternative view to viewController.view
    public func show(panel: Panelable & UIViewController,
                     config: PanelConfiguration = PanelConfiguration(),
                     view: UIView? = nil) {
        assert(self.panel == nil, "You are trying to push a panel without dismiss the previous one.")
        configuration = config
        containerView = view ?? parentViewController?.view
        toggleDimming(show: true)
        self.panel = panel
        parentViewController?.addContainer(container: panel)
        parentViewController?.view.endEditing(true)
        guard let container = containerView else {
            fatalError("No parent view available")
        }

        panelHeightConstraint = addChildToContainer(parent: container,
                                                    child: panel.view,
                                                    visible: config.visibleArea(),
                                                    size: config.size(for: container))

        panel.hideKeyboardAutomatically()
        registerKeyboardNotifications()
        // Prepare the view placement, saving the safeArea.
        //panelHeight = config.heightConstant ?? panel.headerHeight.constant
        //panel.headerHeight.constant = panelHeight + UIApplication.safeAreaBottom()
        setupGestures(superview: container)
    }
    
    /// Shows panel then immediately expands
    public func present(panel: Panelable & UIViewController,
                        config: PanelConfiguration = PanelConfiguration(),
                        view: UIView? = nil) {
        show(panel: panel, config: config, view: view)
        expandPanel()
    }

    /// Opens the panel
    @objc public func expandPanel() {
        guard !isExpanded, let container = containerView else {
            return
        }
        movePanel(value: configuration.size(for: container))
    }

    /// Close the panel
    @objc public func collapsePanel() {
//        guard isExpanded, let container = containerView else {
//            return
//        }
//        movePanel(value: configuration.visibleArea())
//        container.endEditing(true)
        dismiss(completion: nil)
    }

    public func dismiss(completion: (() -> Void)? = nil) {
        guard let panelView = self.panel?.view else {
            completion?()

            return
        }
        toggleDimming(show: false)
        UIView.animate(withDuration: configuration.dismissAnimationDuration, animations: {
            panelView.frame.origin = CGPoint(x: 0, y: self.containerView!.frame.size.height)
        }) { _ in
            self.panel?.removeContainer()
            self.panel = nil
            completion?()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: Private functions

extension Panels {
    private func toggleDimming(show: Bool) {
        guard let view = containerView else {
            return
        }
        
        let viewtag = 9999
        
        if show {
            // Create and add a dim view
            dimView = UIView(frame: view.frame)
            
            guard let dimView = self.dimView else { return }
            dimView.backgroundColor = .black
            dimView.alpha = 0.0
            dimView.tag = viewtag
            view.addSubview(dimView)
            view.bringSubviewToFront(dimView)
            
            // Deal with Auto Layout
            dimView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([dimView.topAnchor.constraint(equalTo: view.topAnchor, constant: -40),
                                         dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
                                         dimView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: 0),
                                         dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor)])
            
            // Animate alpha (the actual "dimming" effect)
            UIView.animate(withDuration: 0.3) { () -> Void in
                dimView.alpha = 0.7
            }
        } else {
            for v in view.subviews where v.tag == viewtag {
                UIView.animate(withDuration: 0.3, animations: { () -> Void in
                    v.alpha = 0
                    }, completion: { (complete) -> Void in
                        v.removeFromSuperview()
                })
            }
        }
    }
    
    private func movePanel(value: CGFloat, keyboard: Bool = false, completion: (() -> Void)? = nil) {
        panelHeightConstraint?.constant = value
//        if !keyboard {
//            panel?.headerHeight.constant += isExpanded ? -UIApplication.safeAreaBottom() : UIApplication.safeAreaBottom()
//        }
        isExpanded ? delegate?.panelDidOpen() : delegate?.panelDidCollapse()
        containerView?.animateLayoutBounce(completion: completion) ?? completion?()
    }

    private func addChildToContainer(parent container: UIView,
                                     child childView: UIView,
                                     visible: CGFloat,
                                     size: CGFloat) -> NSLayoutConstraint {
        childView.translatesAutoresizingMaskIntoConstraints = false
        childView.frame = CGRect(x: 0,
                                 y: container.bounds.maxY + configuration.visibleArea(),
                                 width: container.bounds.width,
                                 height: configuration.visibleArea())
        let views = ["childView": childView]
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[childView]|",
                                                                   options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                                   metrics: nil,
                                                                   views: views)
        container.addConstraints(horizontalConstraints)
        let heightConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[childView(==\(size))]",
                                                               options: NSLayoutConstraint.FormatOptions(rawValue: 0),
                                                               metrics: nil,
                                                               views: views)

        container.addConstraints(heightConstraints)
        let constraint = container.bottomAnchor.constraint(equalTo: childView.topAnchor,
                                                           constant: visible)
        constraint.isActive = true
        if configuration.animateEntry {
            childView.animateLayoutBounce(duration: configuration.entryAnimationDuration)
        } else {
            childView.layoutIfNeeded()
        }
        delegate?.panelDidPresented()
        return constraint
    }
}

// MARK: Keyboard control

extension Panels {
    private func registerKeyboardNotifications() {
        if configuration.keyboardObserver {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(keyboardWillShow(notification:)),
                                                   name: UIResponder.keyboardWillShowNotification,
                                                   object: nil)
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(keyboardWillHide(notification:)),
                                                   name: UIResponder.keyboardWillHideNotification,
                                                   object: nil)
        }
    }

    @objc private func keyboardWillShow(notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = CGFloat(keyboardRectangle.height)
            containerView.then {
                let currentValue = isExpanded ? configuration.size(for: $0) : configuration.visibleArea()
                movePanel(value: currentValue + keyboardHeight, keyboard: true)
            }
        }
    }

    @objc private func keyboardWillHide(notification: Notification) {
//        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
//            let keyboardRectangle = keyboardFrame.cgRectValue
//            let keyboardHeight = CGFloat(keyboardRectangle.height)
            containerView.then {
                let currentValue = isExpanded ? configuration.size(for: $0) : configuration.visibleArea()
                movePanel(value: currentValue)
            }
//        }
//        collapsePanel()
    }
}

// MARK: Gesture control

extension Panels {
    private func setupGestures(superview _: UIView) {
        if configuration.closeOutsideTap {
            let tapGestureOutside = UITapGestureRecognizer(target: self, action: #selector(collapsePanel))
            tapGestureOutside.cancelsTouchesInView = false
            dimView?.addGestureRecognizer(tapGestureOutside)
        }
    }

    @objc private func handleTap() {
        (isExpanded) ? collapsePanel() : expandPanel()
    }
}
