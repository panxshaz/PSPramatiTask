//
//  PSHelper.swift
//  PSPramatiTask
//
//  Created by Pankaj Sharma on 20/Dec/17.
//  Copyright © 2017 Pankaj Sharma. All rights reserved.
//

import UIKit
//*******************************************************************//
// MARK:- String Error Extensions (So that String can be used in place of Error)
//*******************************************************************//
extension String: Error {
  
}

//Show Alert Extension
extension UIViewController {
  func showSimpleAlert(title: String?, msg: String?, completion: (() -> ())? = nil) {
    let alertController = UIAlertController(title: title, message: msg, preferredStyle: .alert)
    let dismissAction = UIAlertAction(title: AppText.dismiss, style: UIAlertActionStyle.cancel) { action in
      completion?()
    }
    alertController.addAction(dismissAction)
    self.present(alertController, animated: true, completion: nil)
  }
}
