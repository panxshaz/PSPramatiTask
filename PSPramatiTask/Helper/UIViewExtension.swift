//
//  UIViewExtension.swift
//  SkoolSlate
//
//  Created by Pankaj Sharma on 8/Sep/16.
//  Copyright © 2016 marijuanaincstudios. All rights reserved.
//

import UIKit
/**
 *  Used for special views or gestures e.g. the default loading indicator etc
 *  Range from -10000 to zero
 */
private enum SpecialTag: Int {
  /// UIActivityIndicatorView
  case centralActivityIndicator = -699
  /// Tap Gesture
  case tapToDismissKeyboard
  case noDataLabel //e.g. No Projects
}

/// Class for TapToDismissKeyboard gesture
class KeyboardDismissTapGesture: UITapGestureRecognizer {
  
}


extension UIView {
  var height: CGFloat {
    return self.frame.size.height
  }
  
  var width: CGFloat {
    return self.frame.size.width
  }
  
  var x: CGFloat {
    return self.frame.origin.x
  }
  
  var y: CGFloat {
    return self.frame.origin.y
  }
  
  //For making it rounded corner
  func makeItRounded(_ newSize: CGFloat = -1) {
    let size = self.frame.size;
    let newSizeVal = (newSize == -1 ? size.height > size.width ? size.width : size.height : newSize)
    
    let saveCenter = self.center;
    let newFrame = CGRect(x: self.frame.origin.x, y: self.frame.origin.y, width: newSizeVal, height: newSizeVal);
    self.frame = newFrame;
    self.layer.cornerRadius = newSizeVal / 2;
    self.clipsToBounds = true;
    self.center = saveCenter;
  }
  
  
  ///
  ///
  
  /// Whether a view is animating
  ///
  /// - Parameter key: if checking for a perticular key
  func isAnimating(withKey key: String? = nil) -> Bool {
    guard let animKeys = self.layer.animationKeys() else { return false }
    if animKeys.isEmpty { return false }
    
    //check for specific key
    if let validKey = key { return animKeys.contains(validKey) }
    return true
  }
  
  
  /// Makes the view visible (Using alpha property)
  ///
  /// - Parameters:
  ///   - duration: animation duration
  func show(withDuration duration: TimeInterval = 0.3) {
    if !self.isHidden {
      return
    }
    self.isHidden = false
    self.alpha = 0
    UIView.animate(withDuration: duration, animations: {
      self.alpha = 1
    })
  }
  
  func hide(withDuration duration: TimeInterval = 0.3) {
    //check if already hidden
    if !self.isHidden {
      //check if already under animation
      if !self.isAnimating(withKey: "opacity") {
        UIView.animate(withDuration: duration, animations: { self.alpha = 0 }) { completed in
          self.isHidden = true
        }
      }
    }
  }
  
  
  //===================================================================================================
  //MARK: - Layout
  //===================================================================================================
  func layoutWithAnimation(_ duration: TimeInterval = 0.3) {
    UIView.animate(withDuration: duration, animations: {
      self.layoutIfNeeded()
    })
  }
  //===================================================================================================
  //MARK: - Animation
  //===================================================================================================
  enum AnimationKey: String {
    case Rotation
  }
  
  
  /**
   Starts 360' rotation
   
   - parameter duration: Default is 'AnimationDuration.defaultDuration' i.e. 0.3s
   - parameter repeated: Default is `true`
   */
  func startRotating(_ duration: TimeInterval = 0.3, forever: Bool = true) -> AnimationKey {
    let rotationAnim = self.layer.animation(forKey: AnimationKey.Rotation.rawValue) as? CABasicAnimation
    if rotationAnim != nil {
      self.resumeLayer(self.layer)
      return AnimationKey.Rotation;
    }
    
    let basicAnimation = CABasicAnimation(keyPath: "transform.rotation")
    basicAnimation.fromValue = 0
    basicAnimation.toValue = Double.pi * 2 //full rotation
    basicAnimation.duration = duration
    basicAnimation.speed = 1.0
    basicAnimation.repeatCount = forever ? HUGE : 0;
    
    self.layer.add(basicAnimation, forKey: AnimationKey.Rotation.rawValue)
    return AnimationKey.Rotation
  }
  
  
  func stopRotating() {
    self.layer.removeAnimation(forKey: AnimationKey.Rotation.rawValue)
  }
  
  
  func stopAllAnimations() {
    self.layer.removeAllAnimations()
  }
  
  
  func pauseAnimations() {
    self.pauseLayer(self.layer)
  }
  
  func resumeAnimations() {
    self.resumeLayer(self.layer)
  }
  
  
  /**
   Stops an animation.
   
   - parameter key: Pass nil to remove all animations
   */
  func stopAnimation(_ key: AnimationKey?) {
    if let validKey = key {
      self.layer.removeAnimation(forKey: validKey.rawValue)
    } else {
      self.layer.removeAllAnimations()
    }
  }
  
  
  /**
   Pauses the `layer` i.e. animations assciated with it
   :Refer: http://stackoverflow.com/questions/9844925/uiview-infinite-360-degree-rotation-animation
   */
  func pauseLayer(_ layer: CALayer) {
    let pausedTime = layer.convertTime(CACurrentMediaTime(), from: nil)
    layer.speed = 0
    layer.timeOffset = pausedTime
  }
  
  /**
   Resumes paused animations of `layer`
   */
  func resumeLayer(_ layer: CALayer) {
    let pausedTime = layer.timeOffset
    layer.speed = 1;
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    let timeSincePause = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime;
    layer.beginTime = timeSincePause;
  }
  
  
  //===================================================================================================
  //MARK: - Network Activity
  //===================================================================================================
  func showNetworkActivityIndicator() {
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
  }
  
  func hideNetworkActivityIndicator() {
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
  }
  
  
  //===================================================================================================
  //MARK: - Tap to Dismiss Keyboard gesture
  //===================================================================================================
  
  /// Default false
  var tapToDismissKeyboardEnabled: Bool {
    get {
      return (self.tapToDismissKeyboardGesture() != nil)
    }
    set {
      if newValue {
        self.addTapToDismissKeyboardGesture()
      } else {
        self.removeTapToDismissKeyboardGesture()
      }
    }
  }
  
  /**
   Add a tap gesture recogizer to view that would simply dismiss the keyboard when tapped
   */
  fileprivate func addTapToDismissKeyboardGesture() {
    //check if already exists
    if let _ = self.tapToDismissKeyboardGesture() {
      //already added
      return
    }
    
    //create one
    let tapGesture = KeyboardDismissTapGesture(target: self, action: #selector(UIView.endEditing(_:)))
    tapGesture.cancelsTouchesInView = false
    self.addGestureRecognizer(tapGesture)
  }
  
  /**
   Removes the tap to dismiss gesture recognizer
   */
  fileprivate func removeTapToDismissKeyboardGesture() {
    if let tapGesture = self.tapToDismissKeyboardGesture() {
      //remove it
      self.removeGestureRecognizer(tapGesture)
    }
  }
  
  /**
   Existing tap t dismiss keyboard gesture recognizer
   */
  func tapToDismissKeyboardGesture() -> KeyboardDismissTapGesture? {
    if let gestures = self.gestureRecognizers {
      //loop through it
      for gesture in gestures {
        if gesture.isKind(of: KeyboardDismissTapGesture.self) {
          return gesture as? KeyboardDismissTapGesture
        }
      }
    }
    
    return nil
  }
  
  //===================================================================================================
  //MARK: - Shadow
  //===================================================================================================
  /**
   Adds a 2px bottom-offset shadow of `radius` 1
   */
  func addBottomShadow() {
    //iv.layer.shadowPath = [UIBezierPath bezierPathWithRect:iv.bounds].CGPath;
    self.addShadow(1, opacity: 0.1, offset: CGSize(width: 0, height: 2))
  }
  
  
  /**
   Adds shadow to the view with `shadowColor` defined in `ThemeManager`
   */
  func addShadow(_ width: CGFloat, opacity: Float, offset: CGSize) {
    self.layer.shadowColor = UIColor.darkGray.cgColor
    self.layer.shadowRadius = width
    self.layer.shadowOffset = offset
    self.layer.shadowOpacity = opacity
    self.layer.shouldRasterize = true
    self.layer.rasterizationScale = UIScreen.main.scale
  }
  
  /**
   Removes the shadow from view
   */
  func removeShadow() {
    self.addShadow(0, opacity: 0, offset: CGSize.zero)
  }
  
  
  //===================================================================================================
  //MARK: - Dim and Disable
  //===================================================================================================
  var dimAndDisable: Bool {
    get {
      return self.isUserInteractionEnabled
    } set {
      self.isUserInteractionEnabled = !newValue
      self.alpha = newValue ? 0.7 : 1
    }
  }
  
  
  //===================================================================================================
  //MARK: - Loading Indicator
  //===================================================================================================
  
  
}


//MARK: - Dashed Border
extension UIView {
  func addDashedBorder(_ color: UIColor = UIColor.red) -> CAShapeLayer {
    let shapeLayer:CAShapeLayer = CAShapeLayer()
    let frameSize = self.frame.size
    let shapeRect = CGRect(x: 0, y: 0, width: frameSize.width, height: frameSize.height)
    
    shapeLayer.bounds = shapeRect
    shapeLayer.position = CGPoint(x: frameSize.width/2, y: frameSize.height/2)
    shapeLayer.fillColor = UIColor.clear.cgColor
    shapeLayer.strokeColor = color.cgColor
    shapeLayer.lineWidth = 1
    shapeLayer.lineJoin = kCALineJoinRound
    shapeLayer.lineDashPattern = [6,3]
    shapeLayer.path = UIBezierPath(roundedRect: shapeRect, cornerRadius: 5).cgPath
    self.layer.addSublayer(shapeLayer)
    
    return shapeLayer
  }
}
