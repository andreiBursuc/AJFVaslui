//
//  SnapShotTestConfiguration+AJFVaslui.swift
//  AJFVasluiTests
//
//  Created by Andrei-Stefan BURSUC on 25.04.2024.
//

import UIKit

extension SnapShotTestConfiguration {

    var withDefaultTolerance: SnapShotTestConfiguration {
        withUpdated(perPixelTolerance: 2.01, overallTolerance: 0.0001)
    }

}

extension Array where Element == SnapShotTestConfiguration {

    /// Extended set of permutations incl. some edge cases.
    static var defaultPermutations: [SnapShotTestConfiguration] {
        SnapShotTestConfiguration
            .permutations(sizes: [.iphone_4inch, .iphone_4_7inch, .iphone_5_8inch, .ipadSheet],
                          contentSizeCategories: [.extraSmall, .large, .accessibilityExtraExtraExtraLarge])
            .map { $0.withDefaultTolerance }
    }

    /// Very limited set of permutations, but including RTL.
    static var minimalPermutations: [SnapShotTestConfiguration] {
        SnapShotTestConfiguration.permutations(sizes: [.iphone_4_7inch], contentSizeCategories: [.large])
            .map { $0.withDefaultTolerance }
    }

    /// Includes one device and font size only (but checks RTL). Use to test minor content variations
    /// on screens whose general layout is already covered by defaultCheckoutPermutations.
    static var simpleCheckoutPermutations: [SnapShotTestConfiguration] {
        SnapShotTestConfiguration
            .permutations(sizes: [.iphone_5_8inch], contentSizeCategories: [.large])
            .map { $0.withDefaultTolerance }
    }

    /// Default permutations for screens that are part of the checkout flow.
    static var defaultCheckoutPermutations: [SnapShotTestConfiguration] {
        SnapShotTestConfiguration
            .permutations(sizes: [.iphone_4inch, .iphone_4_7inch, .iphone_5_8inch, .ipadPaymentNavigationSubview])
            .map { $0.withDefaultTolerance }
    }

    /// Extended set of permutations incl. some edge cases.
    static var extendedPermutations: [SnapShotTestConfiguration] {
        SnapShotTestConfiguration
            .permutations(sizes: [.iphone_4inch, .iphone_4_7inch, .iphone_5_8inch, .ipadSheet],
                          contentSizeCategories: [.extraSmall, .large, .accessibilityExtraExtraExtraLarge])
            .map { $0.withDefaultTolerance }
    }

}

extension SnapShotTestConfiguration.Size {
    static let ipadPaymentNavigationSubview = SnapShotTestConfiguration.Size.overridingTraitCollection(.ipadSheet, .ipadSize)
}

private extension UITraitCollection {
    static let ipadSize = UITraitCollection(traitsFrom: [UITraitCollection(horizontalSizeClass: .regular),
                                                         UITraitCollection(verticalSizeClass: .regular),
                                                         UITraitCollection(userInterfaceIdiom: .pad)])
}

