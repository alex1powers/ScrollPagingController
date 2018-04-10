//
//  DLSynchronizedAnimation.swift
//  ScrollPagingController
//
//  Created by Alexander Goremykin on 08.04.2018.
//  Copyright © 2018 Alexander Goremykin. All rights reserved.
//

import Foundation
import UIKit

protocol DLSynchronizedAnimationTimingFunction {
    func translateProgress(_ progress: TimeInterval) -> TimeInterval
}

class DLSynchronizedAnimation {

    // MARK: - Public Properties

    public fileprivate(set) var isRunning = false

    // MARK: - Constructors

    private init(
        duration: TimeInterval,
        timingFunction: DLSynchronizedAnimationTimingFunction,
        preferredFramerate: Int,
        onFrame: @escaping (_ progress: CGFloat) -> Void,
        completion: ((_ completed: Bool) -> Void)? = nil)
    {
        assert(preferredFramerate > 0 && preferredFramerate <= 60)

        self.duration = duration
        self.timingFunction = timingFunction
        self.onFrame = onFrame
        self.completion = completion

        let displayLink = CADisplayLink(target: self, selector: #selector(tick(_:)))
        if #available(iOS 10.0, *) {
            displayLink.preferredFramesPerSecond = Int(preferredFramerate)
        } else {
            displayLink.frameInterval = max(1, min(60, 1 + (60 - preferredFramerate) / preferredFramerate))
        }

        isRunning = true
        displayLink.add(to: RunLoop.main, forMode: .commonModes)

        self.displayLink = displayLink
    }

    deinit {
        cancel()
    }

    // MARK: - Public Methods

    class func animate(
        withDuration duration: TimeInterval,
        timingFunction: DLSynchronizedAnimationTimingFunction = TimingFunctionPreset.linear,
        preferredFramerate: Int = 45,
        onFrame: @escaping (_ progress: CGFloat) -> Void,
        completion: ((_ completed: Bool) -> Void)? = nil
        ) -> DLSynchronizedAnimation
    {
        return DLSynchronizedAnimation(
            duration: duration,
            timingFunction: timingFunction,
            preferredFramerate: preferredFramerate,
            onFrame: onFrame,
            completion: completion
        )
    }
    
    func cancel() {
        guard isRunning else { return }

        displayLink?.invalidate()
        completion?(false)
    }

    // MARK: - Private Properties

    fileprivate let duration: TimeInterval
    fileprivate let timingFunction: DLSynchronizedAnimationTimingFunction
    fileprivate let onFrame: (_ progress: CGFloat) -> Void
    fileprivate let completion: ((_ completed: Bool) -> Void)?

    fileprivate weak var displayLink: CADisplayLink?
    fileprivate var firstFrameTimeStamp: TimeInterval?

}

fileprivate extension DLSynchronizedAnimation {

    // MARK: - Private Methods

    @objc fileprivate func tick(_ displayLink: CADisplayLink) {
        if firstFrameTimeStamp == nil {
            firstFrameTimeStamp = displayLink.timestamp
        }

        let time = displayLink.timestamp - firstFrameTimeStamp!
        let progress = time / duration

        updateFrame(progress: progress)

        if progress >= 1.0 {
            isRunning = false
            displayLink.invalidate()
            completion?(true)
        }
    }

    fileprivate func updateFrame(progress: TimeInterval) {
        let translatedProgress = timingFunction.translateProgress(progress)
        onFrame(CGFloat(translatedProgress))
    }

}
