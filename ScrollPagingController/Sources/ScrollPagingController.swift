//
//  ScrollPagingController.swift
//  ScrollPagingController
//
//  Created by Alexander Goremykin on 08.04.2018.
//  Copyright © 2018 Alexander Goremykin. All rights reserved.
//

import Foundation
import UIKit

public class ScrollPagingController: NSObject {
    
    // MARK: - Public Nested

    public typealias RelativeControlPoint = ScrollPagingControllerControlPoint
    public typealias AbsoluteControlPoint = (originalIndex: Int, value: CGFloat)

    // MARK: - Public Properties

    public fileprivate(set) var relativeControlPoints: [RelativeControlPoint] = [] { didSet { updateAbsoluteControlPoints() } }
    public fileprivate(set) var absoluteControlPoints: [AbsoluteControlPoint] = []

    public fileprivate(set) var relativeAnchorControlPointIndex: Int?
    public var absoluteAnchorControlPointIndex: Int?  {
        return relativeAnchorControlPointIndex.flatMap { relativeAnchorPointIndex in
            return absoluteControlPoints.index { $0.originalIndex == relativeAnchorPointIndex }
        }
    }

    public var canAnchorMostBottomControlPointViaGesture = true

    // MARK: - Constructors

    public init(scrollView drivenScrollView: UIScrollView) {
        self.drivenScrollView = drivenScrollView
        super.init()

        observations.append(drivenScrollView.observe(\.bounds, options: [.initial, .old, .new]) { [weak self] _, change in
            guard let bounds = change.newValue else { return }

            if change.oldValue?.height != bounds.height {
                self?.updateAbsoluteControlPoints()

                if change.oldValue != nil {
                    self?.absoluteAnchorControlPointIndex.flatMap { index in
                        (self?.absoluteControlPoints[index].value).flatMap {
                            self?.drivenScrollView.contentOffset.y = $0
                        }
                    }
                }
            }
        })
    }

    // MARK: - Public Methods

    public func setControlPoints(
        _ controlPoints: [RelativeControlPoint],
        anchoringToPointWithIndex anchorPointIndex: Int,
        animated: Bool,
        completion: ((_ success: Bool) -> Void)? = nil)
    {
        assert(controlPoints.count >= 2)
        relativeControlPoints = controlPoints
        anchor(toPointWithIndex: anchorPointIndex, animated: animated, completion: completion)
    }

    public func anchor(toPointWithIndex targetPointIndex: Int, animated: Bool, completion: ((_ success: Bool) -> Void)? = nil) {
        currentAnimationContext = nil

        guard let targetContentOffset = absoluteControlPoints.first(where: { $0.originalIndex == targetPointIndex })?.value else {
            assert(false)
            completion?(false)
            return
        }

        if animated {
            drivenScrollView.flashScrollIndicators()

            animate(
                toContentOffset: targetContentOffset,
                velocity: nil,
                suppressBouncing: true,
                completion: { [weak self] success in
                    guard success else { return }
                    self?.relativeAnchorControlPointIndex = targetPointIndex
                    completion?(success)
                }
            )
        } else {
            updateInsets(forAnimation: false)
            drivenScrollView.contentOffset.y = targetContentOffset
            relativeAnchorControlPointIndex = targetPointIndex
            DispatchQueue.main.asyncAfter(deadline: .now()) { completion?(true) }
        }
    }

    // MARK: - Private Properties

    fileprivate let drivenScrollView: UIScrollView

    fileprivate var observations: [NSKeyValueObservation] = []

    fileprivate var currentAnimationContext: AnimationContext?

}

extension ScrollPagingController: UIScrollViewDelegate {

    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard scrollView === drivenScrollView else { assert(false); return }

        currentAnimationContext = nil
        updateInsets(forAnimation: false)
    }

    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView === drivenScrollView else { assert(false); return }
        guard let matchedAbsoluteControlPoint = getAbsoluteControlPoint(
                forTargetContentOffset: targetContentOffset.pointee,
                direction: velocity.verticalDirection
            )
        else {
            // Free scroll
            relativeAnchorControlPointIndex = nil
            return
        }

        // Stop scrolling
        targetContentOffset.pointee = scrollView.contentOffset

        guard canAnchorMostBottomControlPointViaGesture || scrollView.contentOffset.y >= absoluteControlPoints[1].value else {
            // System animation to bottom - 1 control point
            return
        }

        let bouncingDirection = relativeControlPoints[matchedAbsoluteControlPoint.originalIndex].bouncingDirection
        let suppressBouncing = bouncingDirection == .none ||
                               !bouncingDirection.contains(.up) && scrollView.contentOffset.y <= matchedAbsoluteControlPoint.value ||
                               !bouncingDirection.contains(.down) && scrollView.contentOffset.y >= matchedAbsoluteControlPoint.value

        animate(
            toContentOffset: matchedAbsoluteControlPoint.value,
            velocity: velocity.y,
            suppressBouncing: suppressBouncing,
            completion: { [weak self] success in
                guard success else { return }
                self?.relativeAnchorControlPointIndex = matchedAbsoluteControlPoint.originalIndex
            }
        )
    }

    public func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        guard scrollView === drivenScrollView else { assert(false); return false }
        guard let mostTopRelativeControlPointIndex = absoluteControlPoints.last?.originalIndex else { assert(false); return true }
        guard relativeAnchorControlPointIndex != mostTopRelativeControlPointIndex else { return false }

        currentAnimationContext = nil
        scrollView.setContentOffset(scrollView.contentOffset, animated: false)
        anchor(toPointWithIndex: mostTopRelativeControlPointIndex, animated: true)

        return false
    }

}

fileprivate extension ScrollPagingController {

    // MARK: - Private Methods

    fileprivate func updateAbsoluteControlPoints() {
        let height = drivenScrollView.bounds.height

        absoluteControlPoints = relativeControlPoints
            .enumerated()
            .map { index, controlPoint in
                return AbsoluteControlPoint(
                    originalIndex: index,
                    value: {
                        switch controlPoint.anchor {
                        case .top: return -controlPoint.value
                        case .bottom: return -(height - controlPoint.value)
                        }
                    }()
                )
            }
            .sorted { lhs, rhs in return lhs.value < rhs.value }
    }

    fileprivate func updateInsets(forAnimation: Bool) {
        let topInset = drivenScrollView.bounds.height
        let bottomInset = max(0.0, drivenScrollView.bounds.height - drivenScrollView.contentSize.height)

        if forAnimation || canAnchorMostBottomControlPointViaGesture {
            drivenScrollView.contentInset.top = topInset
        } else {
            let topPageLength = absoluteControlPoints[1].value - absoluteControlPoints[0].value
            drivenScrollView.contentInset.top = topInset - topPageLength
        }

        drivenScrollView.contentInset.bottom = bottomInset
    }

    fileprivate func getAbsoluteControlPoint(forTargetContentOffset targetContentOffset: CGPoint, direction: CGPoint.Direction) -> AbsoluteControlPoint? {
        // If we has enough valocity for passing any control point than we must anchor it
        let passedControlPoint: AbsoluteControlPoint?
        switch direction {
        case .forward:
            passedControlPoint = absoluteControlPoints.first {
                return drivenScrollView.contentOffset.y < $0.value && $0.value < targetContentOffset.y
            }

        case .backward:
            passedControlPoint = absoluteControlPoints.reversed().first {
                return drivenScrollView.contentOffset.y > $0.value && $0.value > targetContentOffset.y
            }
        }

        if let passedControlPoint = passedControlPoint {
            return passedControlPoint
        }

        // Don't pass via any control point so just find nearest (it should be first or last control point)
        guard let nearestControlPoint = absoluteControlPoints
            .map({ (distance: fabs($0.value - targetContentOffset.y), item: $0) })
            .enumerated()
            .sorted(by: { $0.element.distance < $1.element.distance })
            .first
        else {
            return nil
        }

        // It safe force unwrap first/last here bacause of we found nearestControlPoint so absoluteControlPoints is not empty
        // Free scroll above most top control point
        if nearestControlPoint.offset == (absoluteControlPoints.count - 1) && targetContentOffset.y > absoluteControlPoints.last!.value {
            return nil
        }

        // Free scroll below most bottom control point
        if nearestControlPoint.offset == 0 && targetContentOffset.y < absoluteControlPoints.first!.value {
            return nil
        }

        return nearestControlPoint.element.item
    }

    // MARK: -

    fileprivate func animate(
        toContentOffset targetContentOffset: CGFloat,
        velocity: CGFloat?,
        suppressBouncing: Bool,
        completion: ((Bool) -> Void)? = nil)
    {
        updateInsets(forAnimation: true)
        currentAnimationContext = AnimationContext.run(
            on: drivenScrollView,
            toContentOffset: targetContentOffset,
            savingVelocity: velocity,
            bounce: !suppressBouncing,
            completion: completion
        )
    }

}

fileprivate extension CGPoint {

    enum Direction {
        case forward
        case backward
    }

    var verticalDirection: Direction { return y > 0.0 ? .forward : .backward }

}
