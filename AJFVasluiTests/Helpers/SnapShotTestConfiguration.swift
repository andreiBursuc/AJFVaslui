//
//  SnapShotTestConfiguration.swift
//  AJFVasluiTests
//
//  Created by Andrei-Stefan BURSUC on 25.04.2024.
//

import UIKit

public struct SnapShotTestConfiguration {
    public enum Size {
        case iphone_4inch
        case iphone_4_7inch
        case iphone_5_5inch
        case iphone_5_8inch
        case ipadSheet
        case ipadPro
        case ipadPro_landscape
        case noResize
        case custom(CGSize)
        case automatic(targetSize: CGSize)
        case automaticHeight(targetWidth: CGFloat)

        indirect case overridingTraitCollection(Size, UITraitCollection)

        private var defaultDimensions: CGSize {
            switch self {
            case .iphone_4inch:
                return CGSize(width: 320, height: 568)
            case .iphone_4_7inch:
                return CGSize(width: 375, height: 667)
            case .iphone_5_5inch:
                return CGSize(width: 414, height: 736)
            case .iphone_5_8inch:
                return CGSize(width: 375, height: 812)
            case .ipadSheet:
                return CGSize(width: 540, height: 620)
            case .ipadPro:
                return CGSize(width: 1024, height: 1366)
            case .ipadPro_landscape:
                return CGSize(width: 1366, height: 1024)
            case .noResize, .automatic, .automaticHeight:
                return .zero
            case .custom(let customSize):
                return customSize
            case .overridingTraitCollection(let underlyingSize, _):
                return underlyingSize.defaultDimensions
            }
        }

        /**
         Returns the dimensions of the snapshot based on configuration size property.
         In case size is `automatic`, system layout fitting dimensions for `view` is returned.
         In case size is `noResize`, the dimensions of view are returned as is.
         For all other cases `view` does not affect the size.
         - Parameter view: The view required to calculate the dimensions if the size is `noResize` or `automatic`.
         */
        public func dimensions(for view: UIView) -> CGSize {
            switch self {
            case .iphone_4inch, .iphone_4_7inch, .iphone_5_5inch, .iphone_5_8inch, .ipadSheet, .ipadPro, .ipadPro_landscape, .custom:
                return defaultDimensions

            case .noResize:
                return view.bounds.size

            case .automatic(let targetSize):
                return view.systemLayoutSizeFitting(targetSize)

            case .automaticHeight(let targetWidth):
                return view.systemLayoutSizeFitting(CGSize(width: targetWidth, height: 0), withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)

            case .overridingTraitCollection(let underlyingSize, _):
                return underlyingSize.dimensions(for: view)
            }
        }

        var safeAreaInsets: UIEdgeInsets {
            switch self {
            case .iphone_4inch,
                 .iphone_4_7inch,
                 .iphone_5_5inch:
                return UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0)
            case .iphone_5_8inch:
                return UIEdgeInsets(top: 44, left: 0, bottom: 34, right: 0)
            case .ipadPro,
                 .ipadPro_landscape:
                return UIEdgeInsets(top: 24, left: 0, bottom: 20, right: 0)
            case .ipadSheet,
                 .noResize,
                 .custom,
                 .automatic,
                 .automaticHeight:
                return .zero
            case .overridingTraitCollection(let underlyingSize, _):
                return underlyingSize.safeAreaInsets
            }
        }

        var identifier: String {
            switch self {
            case .iphone_4inch, .iphone_4_7inch, .iphone_5_5inch, .iphone_5_8inch, .ipadSheet, .ipadPro, .ipadPro_landscape, .custom:
                return "w\(Int(defaultDimensions.width))h\(Int(defaultDimensions.height))"
            case .noResize:
                return "noResize"
            case .automatic:
                return "automatic"
            case .automaticHeight(let targetWidth):
                return "w\(Int(targetWidth))hAuto"
            case .overridingTraitCollection(let underlyingSize, _):
                return underlyingSize.identifier
            }
        }

        private var sizeClasses: (horizontal: UIUserInterfaceSizeClass, vertical: UIUserInterfaceSizeClass) {
            switch self {
            case .ipadSheet:
                return (.compact, .regular)
            case .ipadPro,
                 .ipadPro_landscape:
                return (.regular, .regular)
            case .iphone_4inch,
                 .iphone_4_7inch,
                 .iphone_5_5inch,
                 .iphone_5_8inch,
                 .noResize,
                 .custom,
                 .automatic,
                 .automaticHeight,
                 .overridingTraitCollection:
                return (.compact, .compact)
            }
        }

        private var userInterfaceIdiom: UIUserInterfaceIdiom {
            switch self {
            case .ipadSheet,
                 .ipadPro,
                 .ipadPro_landscape:
                return .pad
            case .iphone_4inch,
                 .iphone_4_7inch,
                 .iphone_5_5inch,
                 .iphone_5_8inch,
                 .noResize,
                 .custom,
                 .automatic,
                 .automaticHeight,
                 .overridingTraitCollection:
                return .phone
            }
        }

        /// Trait collection containing specific traits that should precede the default traits when snapshotting a view.
        /// As only iPhone screen sizes are supported, only compact size classes are returned at the moment.
        var traitCollection: UITraitCollection {
            let horizontalTraitCollection = UITraitCollection(horizontalSizeClass: sizeClasses.horizontal)
            let verticalTraitCollection = UITraitCollection(verticalSizeClass: sizeClasses.vertical)
            let idiomTraitCollection = UITraitCollection(userInterfaceIdiom: userInterfaceIdiom)

            var traits = [horizontalTraitCollection, verticalTraitCollection, idiomTraitCollection]
            if case .overridingTraitCollection(_, let overrideCollection) = self {
                // higher-indexed elements will override lower-indexed elements.
                // by adding the overrideCollection last, other traits will be overridden.
                traits.append(overrideCollection)
            }

            return UITraitCollection(traitsFrom: traits)
        }

        public var keyboardSize: CGSize {
            switch self {
            case .iphone_4inch:
                return CGSize(width: 320, height: 216)
            case .iphone_4_7inch:
                return CGSize(width: 375, height: 216)
            case .iphone_5_5inch:
                return CGSize(width: 414, height: 226)
            case .iphone_5_8inch:
                return CGSize(width: 375, height: 333)
            case .ipadPro:
                return CGSize(width: 1024, height: 264)
            case .ipadPro_landscape:
                return CGSize(width: 1366, height: 352)
            case .ipadSheet, .noResize, .custom, .automatic, .automaticHeight:
                return .zero
            case .overridingTraitCollection(let underlyingSize, _):
                return underlyingSize.keyboardSize
            }
        }

        var onscreenKeyboardFrame: CGRect {
            CGRect(origin: CGPoint(x: 0, y: defaultDimensions.height - keyboardSize.height), size: keyboardSize)
        }

        var offscreenKeyboardFrame: CGRect {
            // In the simulator, the offscreen frame (beginFrame for show; endFrame for dismiss)
            // will have a height of 0, unlike on a real device. We mimic the behavior of a real device,
            // which will have the actual height at all times.
            return CGRect(origin: CGPoint(x: 0, y: defaultDimensions.height), size: keyboardSize)
        }
    }

    /// Permutation set describing the snapshot configuration options to generate the configuration permutations from
    public struct PermutationSet {
        public var forceRightToLeft: Bool
        public var sizes: [Size]
        public var contentSizeCategories: [UIContentSizeCategory]
        public var languages: [String]

        public static let `default`: Self = {
            .init(forceRightToLeft: false,
                  sizes: [.iphone_4_7inch, .iphone_5_8inch],
                  contentSizeCategories: [.large, .small, .extraExtraLarge],
                  languages: ["en"])
        }()

        /**
         Builder method to update permutation sets.

         Example:
         ```
         PermutationSet.default.updating(\.sizes, with: [.ipadPro])
         ```
         */
        public func updating<T>(_ keyPath: WritableKeyPath<Self, T>, with value: T) -> Self {
            var mutable = self
            mutable[keyPath: keyPath] = value
            return mutable
        }
    }

    /// Create configuration permutations for the given property values.
    ///
    /// - Parameter includeRightToLeft:
    ///      Will create one permutation from the first elements of the permutation sets via the other parameters, in forced RTL direction if set to `true`.
    ///      Default value: `true`
    public static func permutations(sizes: [Size] = PermutationSet.default.sizes,
                                    contentSizeCategories: [UIContentSizeCategory] = PermutationSet.default.contentSizeCategories,
                                    languages: [String] = PermutationSet.default.languages,
                                    includeRightToLeft: Bool = true,
                                    tolerance: CGFloat = Self.defaultTolerance) -> [SnapShotTestConfiguration] {
        var permutationSets: [PermutationSet] = [
            .init(forceRightToLeft: false,
                  sizes: sizes,
                  contentSizeCategories: contentSizeCategories,
                  languages: languages)
        ]
        if includeRightToLeft,
           let size = sizes.first,
           let contentSizeCategory = contentSizeCategories.first,
           let language = languages.first {
            permutationSets.append(
                .init(forceRightToLeft: true,
                      sizes: [size],
                      contentSizeCategories: [contentSizeCategory],
                      languages: [language])
            )
        }
        return permutations(from: permutationSets, tolerance: tolerance)
    }

    public static func permutations(from permutationSets: PermutationSet...) -> [SnapShotTestConfiguration] {
        permutations(from: .init(permutationSets), tolerance: Self.defaultTolerance)
    }

    public static func permutations(from permutationSets: [PermutationSet] = [.default]) -> [SnapShotTestConfiguration] {
        permutations(from: permutationSets, tolerance: Self.defaultTolerance)
    }

    static func permutations(from permutationSets: [PermutationSet], tolerance: CGFloat) -> [SnapShotTestConfiguration] {
        permutationSets.flatMap { permutationSet in
            permutationSet.languages.flatMap { language in
                permutationSet.sizes.flatMap { size in
                    permutationSet.contentSizeCategories.map { contentSizeCategory in
                        SnapShotTestConfiguration(contentSizeCategory: contentSizeCategory,
                                                  forceRightToLeft: permutationSet.forceRightToLeft,
                                                  languageIdentifier: language,
                                                  size: size,
                                                  tolerance: tolerance)
                    }
                }
            }
        }
    }

    public let contentSizeCategory: UIContentSizeCategory
    public let forceRightToLeft: Bool
    public let languageIdentifier: String
    public let size: Size

    public init(contentSizeCategory: UIContentSizeCategory,
                forceRightToLeft: Bool,
                languageIdentifier: String,
                size: Size,
                tolerance: CGFloat = Self.defaultTolerance) {
        self.init(contentSizeCategory: contentSizeCategory,
                  forceRightToLeft: forceRightToLeft,
                  languageIdentifier: languageIdentifier,
                  size: size,
                  perPixelTolerance: tolerance,
                  overallTolerance: tolerance)
    }

    public init(contentSizeCategory: UIContentSizeCategory,
                forceRightToLeft: Bool,
                languageIdentifier: String,
                size: Size,
                perPixelTolerance: CGFloat,
                overallTolerance: CGFloat) {
        self.contentSizeCategory = contentSizeCategory
        self.forceRightToLeft = forceRightToLeft
        self.languageIdentifier = languageIdentifier
        self.size = size
        self.perPixelTolerance = perPixelTolerance
        self.overallTolerance = overallTolerance
    }

    /// The identifier provides a string representation of the configuration's value
    /// suitable for filenames and other identification purposes.
    /// Example: "size=w320h480_dir=LTR_sizeCategory=L_lang=en"
    var identifier: String {
        let rtlSuffix = forceRightToLeft ? "RTL" : "LTR"
        let contentSizeIdentifier = contentSizeCategory.rawValue.replacingOccurrences(of: "UICTContentSizeCategory", with: "")
        let components = ["size=" + size.identifier,
                          "dir=" + rtlSuffix,
                          "sizeCategory=" + contentSizeIdentifier,
                          "lang=" + languageIdentifier]
        return components.joined(separator: "_")
    }

    public var layoutDirection: UIUserInterfaceLayoutDirection {
        forceRightToLeft ? .rightToLeft : .leftToRight
    }

    // MARK: Customizable properties
    var perPixelTolerance: CGFloat
    var overallTolerance: CGFloat

    /// Default value of the `tolerance` that can be updated by the ``withUpdated(tolerance:)`` method
    public static var defaultTolerance: CGFloat = 0

    /**
     Convenience builder method for setting the tolerance applied when comparing the snapshots.

     - Parameter tolerance: The percentage difference to be applied to both `perPixelTolerance` and `overallTolerance`

     **See also:**
     ``withUpdated(perPixelTolerance:overallTolerance:)``
     */
    public func withUpdated(tolerance: CGFloat) -> Self {
        self.withUpdated(perPixelTolerance: tolerance, overallTolerance: tolerance)
    }

    /**
     Convenience builder method for individually setting the tolerances applied when comparing the snapshots.

     - Parameter perPixelTolerance: The percentage a given pixel's R,G,B and A components can differ and still be considered 'identical'. Each color shade difference represents a 0.390625% change.
     - Parameter overallTolerance: The percentage difference to still count as identical - 0 mean pixel perfect, 1 means I don't care.
     */
    public func withUpdated(perPixelTolerance: CGFloat, overallTolerance: CGFloat) -> Self {
        var mutating = self
        mutating.perPixelTolerance = perPixelTolerance
        mutating.overallTolerance = overallTolerance
        return mutating
    }
}
