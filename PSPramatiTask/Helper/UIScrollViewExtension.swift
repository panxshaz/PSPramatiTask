//
//  UIScrollViewExtension.swift
//  PSSwiftExtensions
//
//  Created by Pankaj Sharma on 10/Feb/17.
//  Copyright © 2017 Appigizer. All rights reserved.
//

import UIKit

/// Used to get end scrollToEndButton button
private var ScrollToEndTag = -750

//MARK: - Scroll To End
extension UIScrollView {
  
  //This is the only property you need to set to enable scrollToEnd functioanality
  open var scrollsToEnd: Bool {
    get {
      return scrollToEndButton != nil
    } set {
      if newValue {
        if scrollToEndButton == nil {
          let button = addScrollToEndButton()
          button.isHidden = true
          //animate visibility
          button.show()
        }
      } else {
        removeScrollToEndButton()
      }
    }
  }
  
  
  var isScrollDirectionHorizontal: Bool {
    return (self.contentSize.height - self.contentOffset.y) == self.frame.height
  }
  
  var scrollToEndButton: UIButton? {
    return self.superview?.viewWithTag(ScrollToEndTag) as? UIButton
  }
  
  var endContentOffset: CGPoint {
    var offsetPoint = self.contentOffset
    if self.contentSize.height > self.frame.height {
      offsetPoint.y = self.contentSize.height - self.frame.height
    }
    //horizontal scrolling
    if self.contentSize.width > self.frame.width {
      offsetPoint.x = self.contentSize.width - self.frame.width
    }
    return offsetPoint
  }
  
  
  ///Also removes the obsevers
  private func removeScrollToEndButton() {
    guard let scrollButton = scrollToEndButton else { return }
    scrollButton.removeFromSuperview()
    //remove observer
    self.removeObserver(self, forKeyPath: "contentOffset")
    #if DEBUG
      print("Observer Removed")
    #endif
  }
  
  
  func addScrollToEndButton(withTint buttonTintColor: UIColor = UIColor(red: 0.2392, green: 0.447, blue: 0.7059, alpha: 1.0),
                                        addExtraEndMargin: Bool = true) -> UIButton {
    let button = UIButton(type: .custom)
    button.translatesAutoresizingMaskIntoConstraints = false
//    let buttonTintColor = UIColor(red: 0.2392, green: 0.447, blue: 0.7059, alpha: 1.0) //#3D72B4
    button.tintColor = buttonTintColor
    button.backgroundColor = UIColor.white.withAlphaComponent(0.5)
    button.layer.borderColor = buttonTintColor.cgColor
    button.layer.cornerRadius = 4
    button.layer.borderWidth = 1
    button.setTitleColor(buttonTintColor, for: .normal)
    button.setTitle(isScrollDirectionHorizontal ? "▶" : "▼", for: .normal) //down pointing black arrow (Refer: http://www.fileformat.info/info/unicode/char/25bc/index.htm)
    //right pointing black arrow (Refer: http://www.fileformat.info/info/unicode/char/25b6/index.htm)
    //    button.setImage(UIImage(named: "arrow_down"), for: .normal)
    
    //Due to this statement, it doesn't work on UITableViewController / UICollectionViewController
    self.superview?.addSubview(button)
    
    //add constaints
    let xConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.trailing, relatedBy: .equal,toItem: self, attribute: NSLayoutAttribute.trailing, multiplier: 1, constant: 4)
    let yConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.bottom, relatedBy: .equal, toItem: self, attribute: NSLayoutAttribute.bottom, multiplier: 1, constant: -12)
    let widthConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.width, relatedBy: .equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 50)
    let heightConstraint = NSLayoutConstraint(item: button, attribute: NSLayoutAttribute.height, relatedBy: .equal, toItem: nil, attribute: NSLayoutAttribute.notAnAttribute, multiplier: 1, constant: 34)
    xConstraint.isActive = true
    yConstraint.isActive = true
    widthConstraint.isActive = true
    heightConstraint.isActive = true
    
    button.tag = ScrollToEndTag
    
    button.addTarget(self, action: #selector(scrollToEndTappped), for: .touchUpInside)
    
    //add extra bottom space so that the scroll to bottom button doesn't overlap with last row
    self.addObserver(self, forKeyPath: "contentOffset", options: [NSKeyValueObservingOptions.new], context: nil)
    #if DEBUG
      print("Observer Added")
    #endif
    handleBottomButtonVisibility()
    
    return button
  }
  
  
  @objc func scrollToEndTappped() {
    if let tableView = self as? UITableView {
      //scroll till last
      let section = tableView.numberOfSections - 1
      let indexPath = IndexPath(item: tableView.numberOfRows(inSection: section) - 1, section: section)
      tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    } else {
      self.setContentOffset(self.endContentOffset, animated: true)
    }
  }
  
  
  open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
    #if DEBUG
      print("DEBUG observeValue \(String(describing: change))")
    #endif
    if object is UIScrollView && keyPath == "contentOffset" {
      handleBottomButtonVisibility()
    }
  }
  
  
  //  open override func didMoveToWindow() {
  //    print("Window \(self.window)")
  //    if self.window == nil && scrollsToEnd {
  //      self.removeObserver(self, forKeyPath: "contentOffset")
  //    }
  //    super.didMoveToWindow()
  //  }
  
  //Needed to remove the observer
  open override func willMove(toSuperview newSuperview: UIView?) {
    #if DEBUG
      print("Superview \(newSuperview.printDesc)")
    #endif
    if newSuperview == nil && scrollsToEnd {
      removeScrollToEndButton()
    }
    super.willMove(toSuperview: newSuperview)
  }
  
  private func handleBottomButtonVisibility() {
    if (self.hasScrolledTillEnd) {
      //animate the visibility
      scrollToEndButton?.hide()
    } else {
      scrollToEndButton?.show()
    }
  }
  
  
  /// Whether the scrollView has already scrolled till the end.
  var hasScrolledTillEnd: Bool {
    let scrollViewSize = self.frame.size
    let scrollContentSize = self.contentSize
    let scrollOffset = self.contentOffset
    if self.isScrollDirectionHorizontal {
      return scrollOffset.x + scrollViewSize.width >= scrollContentSize.width
    } else {
      return scrollOffset.y + scrollViewSize.height >= scrollContentSize.height
    }
  }
  
  
  //MARK: - Scroll to Top
  func scrollToTop(animated: Bool = true) {
    self.setContentOffset(.zero, animated: animated)
  }
  
}
