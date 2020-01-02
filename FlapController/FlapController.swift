//
//  FlapController.swift
//  Flap
//
//  Created by Thomas Guilleminot on 08/08/17.
//  Copyright © 2016 Myself. All rights reserved.
//

import Foundation
import UIKit

@objc
public protocol FlapControllerDelegate: class {
  
  @objc optional func flapControllerShouldDismiss(_ flapController: FlapController) -> Bool
  @objc optional func flapControllerShouldCompress(_ flapController: FlapController) -> Bool
  @objc optional func flapControllerShouldExpand(_ flapController: FlapController) -> Bool
  
  @objc optional func flapControllerDidDismiss(_ flapController: FlapController)
  @objc optional func flapControllerDidCompress(_ flapController: FlapController)
  @objc optional func flapControllerDidExpand(_ flapController: FlapController)
  @objc optional func flapControllerDidPan(_ flapController: FlapController)
  
}

open class FlapController: UIViewController {
  
  public enum FlapControllerState {
    case compressed
    case expanded
    case dismissed
  }
  
  public let contentViewController: UIViewController
  
  open weak var delegate: FlapControllerDelegate?
  
  open var dismissable: Bool = true
  open var expandable: Bool = true
  open var compressable: Bool = true
  open var panEnable: Bool = false
  open var triggerVelocity: CGFloat = 700
  open var animationDuration: TimeInterval = 0.4
  open var shadowView: UIView?
  open var toggleView: UIView?
  open var blurBackgroundView: UIView?

  open var expandsFullscreen: Bool = true {
    didSet {
      if self.state == .expanded {
        self.expand(animated: true, velocity: 0)
      }
    }
  }
  
  open var maximumOffset: CGFloat = 0 {
    didSet {
      if self.state == .expanded {
        self.expand(animated: true, velocity: 0)
      }
    }
  }
  
  open var minimumOffset: CGFloat = 50 {
    didSet {
      if self.state == .compressed {
        self.compress(animated: true, velocity: 0)
      }
    }
  }
  
  open fileprivate(set) var state: FlapControllerState = .compressed {
    didSet {
      (self.view as? FlapControllerView)?.flapState = self.state
    }
  }
  fileprivate var panGestureStartingY: CGFloat = 0
  fileprivate var flapContentViewTopConstraint: NSLayoutConstraint!
  
  public required init(contentViewController: UIViewController) {
    self.contentViewController = contentViewController
    super.init(nibName: nil, bundle: nil)
  }
  
  public required init?(coder aDecoder: NSCoder) {
    fatalError("Not implemented")
  }
  
  override open func loadView() {
    let flapControllerView = FlapControllerView()
    flapControllerView.translatesAutoresizingMaskIntoConstraints = false
    flapControllerView.forwardsTouches = false
    flapControllerView.flapState = self.state
    
    self.view = flapControllerView
    
    self.setupGestures()
    self.setupBlurBackgroundView()
    self.setupContentViewController()
  }
  
}

public extension FlapController {
  
  func presentFromViewController(_ viewController: UIViewController, animated: Bool, expand: Bool = false) {
    self.removeFlapViewControllersFromPresentingViewController(viewController)
    
    self.willMove(toParent: viewController)
    viewController.addChild(self)
    viewController.view.addSubview(self.view)
    self.didMove(toParent: viewController)
    
    viewController.view.addConstraints(
      NSLayoutConstraint
        .constraints(withVisualFormat: "H:|[view]|",
                                     options: [],
                                     metrics: nil,
                                     views: ["view": self.view]))
    
    viewController.view.addConstraints(
      NSLayoutConstraint
        .constraints(withVisualFormat: "V:|[view]|",
                                     options: [],
                                     metrics: nil,
                                     views: ["view": self.view]))
    
    if expand {
      self.expand(animated: animated, velocity: 0)
    } else {
      self.compress(animated: animated, velocity: 0)
    }
  }
  
  func expand(animated: Bool, velocity: CGFloat, completion: (() -> Void)? = nil) {
    self.state = .expanded
    
    let offset: CGFloat
    if self.expandsFullscreen {
      offset = self.view.bounds.height
    } else {
      offset = self.maximumOffset
    }
    
    self.transform(
      animated: animated,
      animation: {
        self.flapContentViewTopConstraint.constant = offset
        self.blurBackgroundView?.alpha = 1
        self.view.layoutIfNeeded()
    },
      completion: {
        self.delegate?.flapControllerDidExpand?(self)
    })
  }
  
  func compress(animated: Bool, velocity: CGFloat, completion: (() -> Void)? = nil) {
    self.state = .compressed
    
    self.transform(
      animated: animated,
      animation: {
        self.flapContentViewTopConstraint.constant = self.minimumOffset
        self.blurBackgroundView?.alpha = 1
        self.view.layoutIfNeeded()
    },
      completion: {
        self.delegate?.flapControllerDidCompress?(self)
    })
  }
  
  func dismiss(animated: Bool, velocity: CGFloat, completion: (() -> Void)? = nil) {
    self.state = .dismissed
    
    self.transform(
      animated: animated,
      animation: {
        self.flapContentViewTopConstraint.constant = -self.view.bounds.size.height
        self.blurBackgroundView?.alpha = 0
        self.view.layoutIfNeeded()
    },
      completion: {
        self.delegate?.flapControllerDidDismiss?(self)
        
        self.willMove(toParent: nil)
        self.view.removeFromSuperview()
        self.removeFromParent()
        self.didMove(toParent: self)
    })
  }
  
  func transform(animated: Bool, animation: @escaping () -> Void, completion: (() -> Void)?) {
    self.view.layoutIfNeeded()
    
    UIView.animate(
      withDuration: animated ? self.animationDuration : 0,
      delay: 0,
      usingSpringWithDamping: 0.5,
      initialSpringVelocity: 0,
      options: [],
      animations: {
        animation()
        self.view.layoutIfNeeded()
    },
      completion: { _ in
        completion?()
    })
  }
  
}

private extension FlapController {
  
  func setupContentViewController() {
    self.contentViewController.willMove(toParent: self)
    self.addChild(self.contentViewController)
    self.contentViewController.view.tag = FlapControllerView.FlapControllerContentViewTag
    self.view.addSubview(self.contentViewController.view)
    self.view.bringSubviewToFront(self.contentViewController.view)
    self.contentViewController.didMove(toParent: self)
    
    self.contentViewController.view.translatesAutoresizingMaskIntoConstraints = false
    self.contentViewController.view.layer.cornerRadius = 8
    self.contentViewController.view.layer.masksToBounds = true
    
    self.flapContentViewTopConstraint = NSLayoutConstraint(
      item: self.bottomLayoutGuide,
      attribute: .top,
      relatedBy: .equal,
      toItem: self.contentViewController.view,
      attribute: .top,
      multiplier: 1,
      constant: 0)
    
    self.view.addConstraint(self.flapContentViewTopConstraint)
    
    self.view.addConstraint(
      NSLayoutConstraint(
        item: self.contentViewController.view,
        attribute: .centerX,
        relatedBy: .equal,
        toItem: self.view,
        attribute: .centerX,
        multiplier: 1,
        constant: 0))
    
    self.view.addConstraint(
      NSLayoutConstraint(
        item: self.contentViewController.view,
        attribute: .width,
        relatedBy: .equal,
        toItem: self.view,
        attribute: .width,
        multiplier: 1,
        constant: 0))
    
    self.view.addConstraint(
      NSLayoutConstraint(
        item: self.contentViewController.view,
        attribute: .height,
        relatedBy: .equal,
        toItem: self.view,
        attribute: .height,
        multiplier: 1,
        constant: 0))
    
    self.setupToggleView()
  }
  
  func setupToggleView() {
    let toggleView = UIView()
    toggleView.backgroundColor = UIColor(red: 204/255.0, green: 204/255.0, blue: 204/255.0, alpha: 1)
    toggleView.translatesAutoresizingMaskIntoConstraints = false
    toggleView.layer.cornerRadius = 2
    
    self.toggleView = toggleView
    
    self.view.insertSubview(
      toggleView,
      aboveSubview: self.contentViewController.view)
    self.view.addConstraint(
      NSLayoutConstraint(
        item: toggleView,
        attribute: .width,
        relatedBy: .equal,
        toItem: nil,
        attribute: .notAnAttribute,
        multiplier: 1,
        constant: 42))

    self.view.addConstraint(
      NSLayoutConstraint(
        item: toggleView,
        attribute: .height,
        relatedBy: .equal,
        toItem: nil,
        attribute: .notAnAttribute,
        multiplier: 1,
        constant: 4))

    self.view.addConstraint(
      NSLayoutConstraint(
        item: toggleView,
        attribute: .top,
        relatedBy: .equal,
        toItem: self.contentViewController.view,
        attribute: .top,
        multiplier: 1,
        constant: 10))

    self.view.addConstraint(
      NSLayoutConstraint(
        item: toggleView,
        attribute: .centerX,
        relatedBy: .equal,
        toItem: self.contentViewController.view,
        attribute: .centerX,
        multiplier: 1,
        constant: 0))
  }
  
  func setupBlurBackgroundView() {
    guard let parentView = self.parent?.view else { return }

    let backgroundView = UIView(frame: parentView.frame)
    backgroundView.backgroundColor = UIColor.gray


    self.blurBackgroundView = backgroundView
    self.blurBackgroundView?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(dismissFlapController)))

    self.view.addSubview(backgroundView)
  }

  @objc func dismissFlapController() {
    self.dismiss(animated: true, velocity: 0.5)
  }
  
  func setupGestures() {
    let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(FlapController.pan))
    panGestureRecognizer.cancelsTouchesInView = false
    panGestureRecognizer.delaysTouchesBegan = true
    panGestureRecognizer.delegate = self
    self.view.addGestureRecognizer(panGestureRecognizer)
  }
  
  func removeFlapViewControllersFromPresentingViewController(_ viewController: UIViewController) {
    for viewController in viewController.children {
      if let viewController = viewController as? FlapController {
        viewController.dismiss(animated: true, velocity: 0)
      }
    }
  }
  
  func transitionToStatesByPriority(_ states: [FlapControllerState], withVelocity velocity: CGFloat) {
    guard let state = states.first else { return }
    switch state {
    case .compressed:
      if self.delegate?.flapControllerShouldCompress?(self) ?? self.compressable {
        return self.compress(animated: true, velocity: velocity)
      }
    case .expanded:
      if self.delegate?.flapControllerShouldExpand?(self) ?? self.expandable {
        return self.expand(animated: true, velocity: velocity)
      }
    case .dismissed:
      if self.delegate?.flapControllerShouldDismiss?(self) ?? self.dismissable {
        return self.dismiss(animated: true, velocity: velocity)
      }
    }
    
    // Dequeue state and try next one recursively
    return self.transitionToStatesByPriority(
      Array(states.dropFirst()),
      withVelocity: velocity)
  }
  
}

public extension FlapController {
  
  @objc
  fileprivate func pan(_ recognizer: UIPanGestureRecognizer) {
    let translation = recognizer.translation(in: self.view)
    let velocity = recognizer.velocity(in: self.view).y
    let velocityAbs = abs(velocity)
    
    switch recognizer.state {
    case .possible:
      ()
    case .failed:
      ()
    case .cancelled:
      ()
    case .began:
      self.panGestureStartingY = self.flapContentViewTopConstraint.constant
    case .changed:
      guard !self.panEnable else { return }
      self.flapContentViewTopConstraint.constant = self.panGestureStartingY - translation.y
      //self.blurBackgroundView?.alpha = self.flapContentViewTopConstraint.constant / self.maximumOffset
      self.delegate?.flapControllerDidPan?(self)
    case .ended:
      // If constant reaches bottom limit, dismiss
      if self.flapContentViewTopConstraint.constant < 70 {
        return self.transitionToStatesByPriority(
          [.dismissed, .compressed, .expanded],
          withVelocity: velocityAbs)
      }
      
      // If velocity reaches trigger
      if velocityAbs >= self.triggerVelocity {
        if velocity < 0 {
          // Bottom -> Up
          return self.transitionToStatesByPriority(
            [.expanded, .compressed],
            withVelocity: velocityAbs)
        } else {
          // Up -> Bottom
          switch self.state {
          case .compressed:
            return self.transitionToStatesByPriority(
              [.dismissed, .compressed],
              withVelocity: velocityAbs)
          case .expanded:
            return self.transitionToStatesByPriority(
              [.compressed, .dismissed, .expanded],
              withVelocity: velocityAbs)
          case .dismissed:
            ()
          }
        }
      } else if self.flapContentViewTopConstraint.constant > self.contentViewController.view.bounds.height / 2 {
        // More than half of the view is visible
        return self.transitionToStatesByPriority(
          [.expanded, .compressed],
          withVelocity: velocityAbs)
      } else {
        // Less than half of the view is visible
        return self.transitionToStatesByPriority(
          [.compressed, .expanded],
          withVelocity: velocityAbs)
      }
    @unknown default:
        fatalError()
    }
  }
  
}

extension FlapController: UIGestureRecognizerDelegate {
  
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    return true
  }
  
  public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
    return true
  }
  
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return false
  }
  
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return false
  }
  
  public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  
}
