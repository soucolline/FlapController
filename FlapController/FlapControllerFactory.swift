//
//  FlapControllerFactory.swift
//  FlapController
//
//  Created by Thomas Guilleminot on 1/2/20.
//  Copyright © 2020 Thomas Guilleminot. All rights reserved.
//

import Foundation
import UIKit

class FlapControllerFactory {
  static func createFlapController<T: UIViewController>(from viewController: T.Type, delegate: AnyObject, storyboardName: String = "Main") {
    let storyboard = UIStoryboard(name: storyboardName, bundle: Bundle(for: T.self))
    let itemViewController = storyboard.instantiateViewController(withIdentifier: String(describing: T.self)) as! T

    itemViewController.view.layoutIfNeeded()

    let flapController = FlapController(contentViewController: itemViewController)
    flapController.expandsFullscreen = false
    flapController.delegate = delegate as? FlapControllerDelegate
    flapController.presentFromViewController(delegate as! UIViewController, animated: true)
  }
}
