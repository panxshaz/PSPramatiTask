//
//  Constants.swift
//  PSPramatiTask
//
//  Created by Pankaj Sharma on 20/Dec/17.
//  Copyright © 2017 Pankaj Sharma. All rights reserved.
//

import UIKit

///Text to display
struct AppText {
  static let sortAsc = "Smallest to Largest"
  static let sortDesc = "Largest to Smallest"
  static let dismiss = "Dismiss"
  static let warning = "⚠️"
  static let noMatchesFound = "No Match Found"
  struct ShowingCities {
    init(_ value: Int) {
      num = value
    }
    let num: Int
    var displayText: String {
      return "Showing \(num) cities"
    }
  }
}


///Constants to be used in app
struct Constants {
  static let cityFilename = "worldcitiespop"
  static let myWebsite = "http://www.pankajsharma.me"
  
  static var isPersistingData: Bool {
    get {
      return UserDefaults.standard.bool(forKey: "PersistData")
    } set {
      UserDefaults.standard.set(newValue, forKey: "PersistData")
      UserDefaults.standard.synchronize()
    }
  }
}
