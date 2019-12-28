//
//  TestFlapViewController.swift
//  FlapController
//
//  Created by Thomas Guilleminot on 08/08/2017.
//  Copyright © 2017 Thomas Guilleminot. All rights reserved.
//

import UIKit

class TestFlapViewController: UIViewController {
  
  @IBOutlet weak var expandBtn: UIButton!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    self.expandBtn.clipsToBounds = true
    self.expandBtn.layer.cornerRadius = 6.0
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    guard let flapController = self.parent as? FlapController else { return }

    flapController.expandsFullscreen = false
    flapController.maximumOffset = self.view.bounds.minY + 330
    flapController.minimumOffset = self.view.bounds.minY + 150
    flapController.compressable = true
    flapController.dismissable = true
  }
  
  @IBAction func expandFlap(_ sender: Any) {
    guard let flapController = self.parent as? FlapController else { return }
    
    flapController.expand(animated: true, velocity: 10)
  }
  
}
