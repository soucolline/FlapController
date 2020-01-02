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
    FlapControllerFactory.createFlapController(
      from: TestFlapViewController.self,
      delegate: self
    )
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
