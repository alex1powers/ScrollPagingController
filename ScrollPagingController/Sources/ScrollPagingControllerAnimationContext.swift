//
//  ScrollPagingControllerAnimationContext.swift
//  ScrollPagingController
//
//  Created by Alexander Goremykin on 09.04.2018.
//  Copyright © 2018 Alexander Goremykin. All rights reserved.
//

import Foundation
import UIKit

internal extension ScrollPagingController {

    class AnimationContext {

        // MARK: - Public Properties

        var isAnimating: Bool { return runningAnimation?.isRunning ?? false }

        // MARK: - Constructors

        private init(currentOffset: CGFloat, targetOffset: CGFloat, savingVelocity velocity: CGFloat?, bounce: Bool) {
            var mainStepDuration = Static.maximumAnimationDuration
            if let velocity = velocity, fabs(velocity) > 0.0 {
                let animationPathLength = fabs(targetOffset - currentOffset)
                let possibleDuration = TimeInterval(animationPathLength / fabs(velocity * 700.0))

                if possibleDuration < Static.maximumAnimationDuration {
                    mainStepDuration = possibleDuration
                }
            }

            if let bouncedOffset = velocity.flatMap({ bounce ? (targetOffset + $0 * Static.bouncingRadius) : nil }) {
                self.steps = [
                    AnimationStep(
                        offset: bouncedOffset,
                        duration: mainStepDuration,
                        timingFunction: DLSynchronizedAnimation.TimingFunctionPreset.easeOut
                    ),
                    AnimationStep(
                        offset: targetOffset,
                        duration: Static.bouncingDuration,
                        timingFunction: DLSynchronizedAnimation.TimingFunctionPreset.easeOut
                    )
                ]
            } else {
                self.steps = [
                    AnimationStep(
                        offset: targetOffset,
                        duration: mainStepDuration,
                        timingFunction: DLSynchronizedAnimation.TimingFunctionPreset.easeOut
                    )
                ]
            }
        }

        // MARK: - Public Methods

        static func run(
            on scrollView: UIScrollView,
            toContentOffset targetOffset: CGFloat,
            savingVelocity velocity: CGFloat?,
            bounce: Bool,
            completion: ((_ success: Bool) -> Void)? = nil) -> AnimationContext
        {
            let context = AnimationContext(
                currentOffset: scrollView.contentOffset.y,
                targetOffset: targetOffset,
                savingVelocity: velocity,
                bounce: bounce
            )

            context.animate(on: scrollView, completion: completion)

            return context
        }

        // MARK: - Private Properties

        fileprivate let steps: [AnimationStep]
        fileprivate var runningAnimation: DLSynchronizedAnimation?

    }

}

fileprivate extension ScrollPagingController.AnimationContext {

    // MARK: - Private Nested

    fileprivate typealias AnimationStep = (offset: CGFloat, duration: TimeInterval, timingFunction: DLSynchronizedAnimationTimingFunction)

    fileprivate struct Static {
        static let maximumAnimationDuration: TimeInterval = 0.3

        static let bouncingRadius: CGFloat = 14.0
        static let bouncingDuration: TimeInterval = 0.3
    }

    // MARK: - Private Methods

    fileprivate func animate(
        on scrollView: UIScrollView,
        activeStepIndex: Int = 0,
        completion: ((_ success: Bool) -> Void)? = nil)
    {
        assert(!(runningAnimation?.isRunning ?? false))
        guard activeStepIndex < steps.count else { completion?(true); return }

        let step = steps[activeStepIndex]
        let interpolate: (CGFloat, CGFloat, CGFloat) -> CGFloat = { a, b, fraction in return a + (b - a) * fraction }
        let initialOffset = scrollView.contentOffset.y

        runningAnimation = DLSynchronizedAnimation.animate(
            withDuration: step.duration,
            timingFunction: step.timingFunction,
            onFrame: { [weak scrollView] progress in
                scrollView?.contentOffset.y = interpolate(initialOffset, step.offset, progress)
            },
            completion: { [weak self, weak scrollView] success in
                guard let slf = self else { return }
                guard let scrollView = scrollView else { completion?(false); return }
                guard success else { completion?(false); return }

                slf.animate(on: scrollView, activeStepIndex: activeStepIndex + 1, completion: completion)
            }
        )
    }

}
