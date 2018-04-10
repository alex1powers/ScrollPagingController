//
//  DLSynchronizedAnimationTimingFunctionsPresets.swift
//  ScrollPagingController
//
//  Created by Alexander Goremykin on 08.04.2018.
//  Copyright © 2018 Alexander Goremykin. All rights reserved.
//

import Foundation

public class DLSynchronizedAnimationBlockTimingFunction: DLSynchronizedAnimationTimingFunction {

    // MARK: - Constructors

    public init(block: @escaping (_ progress: TimeInterval) -> TimeInterval) {
        self.block = block
    }

    // MARK: - Public Methods

    public func translateProgress(_ progress: TimeInterval) -> TimeInterval {
        return block(progress)
    }

    // MARK: - Private Properties

    private let block: (_ progress: TimeInterval) -> TimeInterval

}

extension DLSynchronizedAnimation {

    public class TimingFunctionPreset {
        
        public static var linear: DLSynchronizedAnimationTimingFunction {
            return DLSynchronizedAnimationBlockTimingFunction { return $0 }
        }

        public static var easeIn: DLSynchronizedAnimationTimingFunction {
            return DLSynchronizedAnimationBlockTimingFunction { progress in
                return progress * progress
            }
        }

        public static var easeOut: DLSynchronizedAnimationTimingFunction {
            return DLSynchronizedAnimationBlockTimingFunction { progress in
                return progress * (2.0 - progress)
            }
        }

        private init() {}

    }

}
