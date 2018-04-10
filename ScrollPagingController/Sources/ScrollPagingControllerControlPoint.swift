//
//  ScrollPagingControllerControlPoint.swift
//  ScrollPagingController
//
//  Created by Alexander Goremykin on 08.04.2018.
//  Copyright © 2018 Alexander Goremykin. All rights reserved.
//

import Foundation
import UIKit

public struct ScrollPagingControllerControlPoint {

    // MARK: - Public Nested

    public enum Anchor {
        case top
        case bottom
    }

    public struct BouncingDirection: OptionSet {

        // MARK: - Public Properties

        public let rawValue: Int

        // MARK: -

        public static let up = BouncingDirection(rawValue: 1)
        public static let down = BouncingDirection(rawValue: 2)
        public static let any: BouncingDirection = [.up, .down]
        public static let none: BouncingDirection = []

        // MARK: - Constructors

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

    }

    // MARK: - Public Properties

    let anchor: Anchor
    let value: CGFloat
    let bouncingDirection: BouncingDirection

    // MARK: - Constructors

    public init(anchor: Anchor = .top, value: CGFloat, bouncingDirection: BouncingDirection = .any) {
        self.anchor = anchor
        self.value = value
        self.bouncingDirection = bouncingDirection
    }

}
