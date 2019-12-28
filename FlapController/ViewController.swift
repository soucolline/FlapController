//
//  ViewController.swift
//  FlapController
//
//  Created by Thomas Guilleminot on 08/08/2017.
//  Copyright © 2017 Thomas Guilleminot. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  @IBAction func initFlap(_ sender: Any) {
    let _ = FlapController.addFlap(delegate: self)
  }

}

extension ViewController: FlapControllerDelegate {
  func flapControllerDidDismiss(_ flapController: FlapController) {
    print("did dismiss")
  }
  
  func flapControllerDidExpand(_ flapController: FlapController) {
    print("did expand")
  }
}

extension FlapController {
  
  static func addFlap(delegate: AnyObject) -> TestFlapViewController {
    let storyboard = UIStoryboard.init(name: "Main", bundle: Bundle.main)
    
    let itemViewController = storyboard
      .instantiateViewController(withIdentifier: "TestFlapViewController")
      as! TestFlapViewController
    //let itemViewController = itemNavigationController.viewControllers.first as! TestFlapViewController
    itemViewController.view.layoutIfNeeded()
    
    let flapController = FlapController(contentViewController: itemViewController)
    flapController.expandsFullscreen = false
    flapController.delegate = delegate as? FlapControllerDelegate
    flapController.presentFromViewController(delegate as! UIViewController, animated: true)
    
    return itemViewController
  }
  
}
