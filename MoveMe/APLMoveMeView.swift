//
//  APLMoveMeView.swift
//  MoveMe
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/9/27.
//
//
/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Contains a (placard) view that can be moved by touch. Illustrates handling touch events and two styles of animation.
*/
import UIKit
import SpriteKit.SKNode

let GROW_FACTOR: CGFloat = 1.2
let SHRINK_FACTOR: CGFloat = 1.1

@objc(APLMoveMeView)
class APLMoveMeView: UIView {
    
    
    
    @IBOutlet private var placardView: UIView!
    private var touchPointValue: NSValue?
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        // We only support single touches, so anyObject retrieves just that touch from touches.
        guard let touch = touches.first
            
            // Only move the placard view if the touch was in the placard view.
            where touch.view == self.placardView else {
                return
        }
        
        // Animate the first touch.
        let touchPoint = touch.locationInView(self)
        self.animateFirstTouchAtPoint(touchPoint)
        
    }
    
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        guard let touch = touches.first
            
            // If the touch was in the placardView, move the placardView to its location.
            where touch.view == self.placardView else {return}
        let location = touch.locationInView(self)
        self.placardView.center = location
    }
    
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        guard let touch = touches.first
            
            // If the touch was in the placardView, bounce it back to the center.
            where touch.view == self.placardView else {return}
        /*
        Disable user interaction so subsequent touches don't interfere with animation until the placard has returned to the center. Interaction is reenabled in animationDidStop:finished:.
        */
        self.userInteractionEnabled = false
        self.animatePlacardViewToCenter()
    }
    
    
    override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
        
        /*
        To impose as little impact on the device as possible, simply set the placard view's center and transformation to the original values.
        */
        self.placardView.center = self.center
        self.placardView.transform = CGAffineTransformIdentity
    }
    
    
    /*
    First of two possible implementations of animateFirstTouchAtPoint: illustrating different behaviors.
    To choose the second, replace 'true' with 'false' below.
    */
    
    #if true
    
    /**
    "Pulse" the placard view by scaling up then down, then move the placard to under the finger.
    */
    private func animateFirstTouchAtPoint(touchPoint: CGPoint) {
    /*
    This illustrates using UIView's built-in animation.  We want, though, to animate the same property (transform) twice -- first to scale up, then to shrink.  You can't animate the same property more than once using the built-in animation -- the last one wins.  So we'll set a delegate action to be invoked after the first animation has finished.  It will complete the sequence.
    
    The touch point is passed in an NSValue object as the context to beginAnimations:. To make sure the object survives until the delegate method, pass the reference as retained.
    */
    
    let GROW_ANIMATION_DURATION_SECONDS = 0.15
    touchPointValue = NSValue(CGPoint: touchPoint)
    UIView.beginAnimations(nil, context: UnsafeMutablePointer(unsafeAddressOf(self.touchPointValue!)))
    UIView.setAnimationDuration(GROW_ANIMATION_DURATION_SECONDS)
    UIView.setAnimationDelegate(self)
    UIView.setAnimationDidStopSelector("growAnimationDidStop:finished:context:")
    let transform = CGAffineTransformMakeScale(GROW_FACTOR, GROW_FACTOR)
    self.placardView.transform = transform
    UIView.commitAnimations()
    }
    
    
    func growAnimationDidStop(animationID: String, finished: NSNumber, context: UnsafePointer<Void>) {
    
    let MOVE_ANIMATION_DURATION_SECONDS = 0.15
    
    UIView.beginAnimations(nil, context: nil)
    UIView.setAnimationDuration(MOVE_ANIMATION_DURATION_SECONDS)
    self.placardView.transform = CGAffineTransformMakeScale(SHRINK_FACTOR, SHRINK_FACTOR)
    /*
    Move the placardView to under the touch.
    We passed the location wrapped in an NSValue as the context. Get the point from the value, and transfer ownership to ARC to balance the bridge retain in touchesBegan:withEvent:.
    */
    let touchPointValue = unsafeBitCast(context, NSValue.self) //###TODO: no memory leak?
    self.placardView.center = touchPointValue.CGPointValue()
    UIView.commitAnimations()
    }
    
    #else
    
    /*
    Alternate behavior.
    The preceding implementation grows the placard in place then moves it to the new location and shrinks it at the same time.  An alternative is to move the placard for the total duration of the grow and shrink operations; this gives a smoother effect.
    
    */
    
    
    /**
    Create two separate animations. The first animation is for the grow and partial shrink. The grow animation is performed in a block. The method uses a completion block that itself includes an animation block to perform the shrink. The second animation lasts for the total duration of the grow and shrink animations and contains a block responsible for performing the move.
    */
    
    private func animateFirstTouchAtPoint(touchPoint: CGPoint) {
        
        let GROW_ANIMATION_DURATION_SECONDS = 0.15
        let SHRINK_ANIMATION_DURATION_SECONDS = 0.15
        
        UIView.animateWithDuration(GROW_ANIMATION_DURATION_SECONDS, animations: {
            let transform = CGAffineTransformMakeScale(GROW_FACTOR, GROW_FACTOR)
            self.placardView.transform = transform
            },
            completion: {finished in
                
                UIView.animateWithDuration(SHRINK_ANIMATION_DURATION_SECONDS) {
                    self.placardView.transform = CGAffineTransformMakeScale(SHRINK_FACTOR, SHRINK_FACTOR)
                }
                
        })
        
        UIView.animateWithDuration(GROW_ANIMATION_DURATION_SECONDS + SHRINK_ANIMATION_DURATION_SECONDS) {
            self.placardView.center = touchPoint
        }
        
    }
    
    
    /*
    
    Equivalent implementation using delegate-based method.
    
    - (void)animateFirstTouchAtPointOld:(CGPoint)touchPoint {
    
    #define GROW_ANIMATION_DURATION_SECONDS 0.15
    #define SHRINK_ANIMATION_DURATION_SECONDS 0.15
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:GROW_ANIMATION_DURATION_SECONDS];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(growAnimationDidStop:finished:context:)];
    CGAffineTransform transform = CGAffineTransformMakeScale(1.2, 1.2);
    self.placardView.transform = transform;
    [UIView commitAnimations];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:GROW_ANIMATION_DURATION_SECONDS + SHRINK_ANIMATION_DURATION_SECONDS];
    self.placardView.center = touchPoint;
    [UIView commitAnimations];
    }
    
    
    - (void)growAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:SHRINK_ANIMATION_DURATION_SECONDS];
    self.placardView.transform = CGAffineTransformMakeScale(1.1, 1.1);
    [UIView commitAnimations];
    }
    */
    
    #endif
    
    
    /**
    Bounce the placard back to the center.
    */
    private func animatePlacardViewToCenter() {
        
        let placardView = self.placardView
        let welcomeLayer = placardView.layer
        
        // Create a keyframe animation to follow a path back to the center.
        let bounceAnimation = CAKeyframeAnimation(keyPath: "position")
        bounceAnimation.removedOnCompletion = false
        
        var animationDuration: CGFloat = 1.5
        
        
        // Create the path for the bounces.
        let bouncePath = UIBezierPath()
        
        let centerPoint = self.center
        let midX = centerPoint.x
        let midY = centerPoint.y
        let originalOffsetX = placardView.center.x - midX
        let originalOffsetY = placardView.center.y - midY
        var offsetDivider: CGFloat = 4.0
        
        var stopBouncing = false
        
        // Start the path at the placard's current location.
        bouncePath.moveToPoint(CGPointMake(placardView.center.x, placardView.center.y))
        bouncePath.addLineToPoint(CGPointMake(midX, midY))
        
        // Add to the bounce path in decreasing excursions from the center.
        while !stopBouncing {
            
            let excursion = CGPointMake(midX + originalOffsetX/offsetDivider, midY + originalOffsetY/offsetDivider)
            bouncePath.addLineToPoint(excursion)
            bouncePath.addLineToPoint(centerPoint)
            
            offsetDivider += 4
            animationDuration += 1/offsetDivider
            if abs(originalOffsetX/offsetDivider) < 6 && abs(originalOffsetY/offsetDivider) < 6 {
                stopBouncing = true
            }
        }
        
        bounceAnimation.path = bouncePath.CGPath
        bounceAnimation.duration = CFTimeInterval(animationDuration)
        
        // Create a basic animation to restore the size of the placard.
        let transformAnimation = CABasicAnimation(keyPath: "transform")
        transformAnimation.removedOnCompletion = true
        transformAnimation.duration = CFTimeInterval(animationDuration)
        transformAnimation.toValue = NSValue(CATransform3D: CATransform3DIdentity)
        
        
        // Create an animation group to combine the keyframe and basic animations.
        let theGroup = CAAnimationGroup()
        
        // Set self as the delegate to allow for a callback to reenable user interaction.
        theGroup.delegate = self
        theGroup.duration = CFTimeInterval(animationDuration)
        theGroup.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
        
        theGroup.animations = [bounceAnimation, transformAnimation]
        
        
        // Add the animation group to the layer.
        welcomeLayer.addAnimation(theGroup, forKey: "animatePlacardViewToCenter")
        
        // Set the placard view's center and transformation to the original values in preparation for the end of the animation.
        placardView.center = centerPoint
        placardView.transform = CGAffineTransformIdentity
    }
    
    
    /**
    Animation delegate method called when the animation's finished: restore the transform and reenable user interaction.
    */
    override func animationDidStop(theAnimation: CAAnimation, finished flag: Bool) {
        
        self.placardView.transform = CGAffineTransformIdentity
        self.userInteractionEnabled = true
    }
    
    
}