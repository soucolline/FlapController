//
//  FlapControllerView.swift
//  Flap
//
//  Created by Thomas GUILLEMINOT on 08/08/17.
//  Copyright © 2016 Myself. All rights reserved.
//

import UIKit

class FlapControllerView: UIView {
  
  static let FlapControllerContentViewTag = 1
  
  var forwardsTouches: Bool = true
  var flapState: FlapController.FlapControllerState?
  
  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    // Forwards touches unless inside the flap content view
    guard
      let flapContentView = self.viewWithTag(type(of: self).FlapControllerContentViewTag), self.forwardsTouches
      else { return true }
    
    if self.flapState == .expanded {
      return self.frame.contains(point)
    }
    
    return flapContentView.frame.contains(point)
  }
  
}
