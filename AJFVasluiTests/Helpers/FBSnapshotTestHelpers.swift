//
//  FBSnapshotTestHelpers.swift
//  AJFVasluiTests
//
//  Created by Andrei-Stefan BURSUC on 25.04.2024.
//

import iOSSnapshotTestCase
import UIKit

// Allow users of the package to inherit without importing the iOSSnapshotTestCase package
public typealias TestCase = FBSnapshotTestCase

public protocol SnapshotEnvironment {
    func showKeyboard()
    func hideKeyboard()
}

public extension FBSnapshotTestCase {

    func verifyViewController<T: UIViewController>(configurations: [SnapShotTestConfiguration], file: StaticString = #file, line: UInt = #line, controllerInstantiation: (SnapShotTestConfiguration) -> T) {
        verifyViewController(configurations: configurations, file: file, line: line, controllerInstantiation: controllerInstantiation, afterDidAppear: nil)
    }

    func verifyViewController<T: UIViewController>(configurations: [SnapShotTestConfiguration], file: StaticString = #file, line: UInt = #line, controllerInstantiation: (SnapShotTestConfiguration) -> T, afterDidAppear: ((T, SnapshotEnvironment) -> Void)?) {
        for config in configurations {
            verifyViewController(configuration: config, file: file, line: line, controllerInstantiation: {
                controllerInstantiation(config)
            }, afterDidAppear: afterDidAppear)
        }
    }

    func verifyViewController<T: UIViewController>(configuration: SnapShotTestConfiguration, file: StaticString = #file, line: UInt = #line, controllerInstantiation: () -> T, afterDidAppear: ((T, SnapshotEnvironment) -> Void)? = nil) {
        snapshot(with: configuration, file: file, line: line) {
            let viewController = controllerInstantiation()
            let container = SnapshotContainer(size: configuration.size, viewController: viewController)
            container.fakeAppearance()
            afterDidAppear?(viewController, container)

            return container
        }
    }

    func verifyView(configurations: [SnapShotTestConfiguration], file: StaticString = #file, line: UInt = #line, viewInstantiation: (SnapShotTestConfiguration) -> UIView) {
        for config in configurations {
            verifyView(configuration: config, file: file, line: line) {
                viewInstantiation(config)
            }
        }
    }

    func verifyView(configuration: SnapShotTestConfiguration, file: StaticString = #file, line: UInt = #line, viewInstantiation: () -> UIView) {
        snapshot(with: configuration, file: file, line: line) {
            let view = viewInstantiation()
            let container = SnapshotContainer(size: configuration.size, view: view)
            container.fakeAppearance()

            return container
        }
    }

}

private extension FBSnapshotTestCase {
    func snapshot(with configuration: SnapShotTestConfiguration, file: StaticString = #file, line: UInt = #line, containerInstantiation: () -> SnapshotContainer) {
        let screenScale = UIScreen.main.scale
        Swift.assert(screenScale == 2, "View snapshots require @2x resolution, e.g. iPhone 6,7,8")
        let screenSize = CGSize(width: UIScreen.main.bounds.size.width * screenScale, height: UIScreen.main.bounds.size.height * screenScale)
        Swift.assert(screenSize.equalTo(CGSize(width: 750, height: 1334)), "Snapshot tests require device with 4.7\" screen size, e.g. iPhone 6,7,8")

        let configClass: AnyClass? = NSClassFromString("SDSTextStyleConfiguration")
        configClass?.performSelector(onMainThread: Selector(("setContentSizeCategory:")), with: configuration.contentSizeCategory, waitUntilDone: true)

        // remember current language and set app language to match configuration
        let defaults = UserDefaults.standard
        let languagesKey = "AppleLanguages"
        let languagesBefore = defaults.object(forKey: languagesKey)
        defaults.set([configuration.languageIdentifier], forKey: languagesKey)
        defaults.synchronize()

        // we must set the layout direction before creating the container or any of view that we plan on snapshotting,
        // because forcing the layout direction on existing view will not work.
        UIApplication.shared.setForcedUserInterfaceLayoutDirection(configuration.layoutDirection)
        var container: SnapshotContainer?
        UIView.performWithoutAnimation {
            container = containerInstantiation()
        }
        guard let safeContainer = container else {
            XCTFail("Failed to create container")
            return
        }
        // snapshotting the container without explicitly showing it would produce empty snapshots
        safeContainer.isHidden = false

        Swift.assert(FBSnapshotTestCaseIs64Bit(), "view snapshots require 64 bit device. e.g. iPhone 8 sim")
        let suffixes = NSOrderedSet(array: ["_64"])
        UIView.performWithoutAnimation {
            FBSnapshotVerifyView(safeContainer, identifier: configuration.identifier, suffixes: suffixes, perPixelTolerance: configuration.perPixelTolerance, overallTolerance: configuration.overallTolerance, file: file, line: line)
        }

        // remove container from screen and make it let go the viewcontroller
        safeContainer.isHidden = true
        safeContainer.rootViewController = nil

        // reset language
        defaults.set(languagesBefore, forKey: languagesKey)
        defaults.synchronize()
    }
}

private extension UIView {
    /// Calls the given block with every view in the view hiearachy, including the view itself
    func applyToSubtree(_ block: (UIView) -> Void) {
        block(self)
        for subview in subviews {
            subview.applyToSubtree(block)
        }
    }
}

private final class SnapshotContainer: UIWindow, SnapshotEnvironment {
    private enum Content {
        case view(UIView)
        case viewController(UIViewController)
    }

    private let size: SnapShotTestConfiguration.Size
    private let content: Content

    private weak var keyboardView: UIView?
    private weak var safeAreaHighlightView: UIView?

    // MARK: - Instantiation

    init(size: SnapShotTestConfiguration.Size, view: UIView) {
        self.size = size
        self.content = .view(view)
        super.init(frame: CGRect(origin: .zero, size: size.dimensions(for: view)))
    }

    init(size: SnapShotTestConfiguration.Size, viewController: UIViewController) {
        self.size = size
        self.content = .viewController(viewController)
        super.init(frame: CGRect(origin: .zero, size: size.dimensions(for: viewController.view)))
    }

    func fakeAppearance() {
        isHidden = false

        switch content {
        case .view(let view):
            addSubview(view)
            view.frame = bounds
            view.layoutIfNeeded()
        case .viewController(let vc):
            let rootVC = UIViewController()
            rootViewController = rootVC

            vc.view.frame = bounds
            vc.modalPresentationStyle = .fullScreen
            rootVC.present(vc, animated: false, completion: nil)
            vc.view.layoutIfNeeded()

            // This makes sure the current run loop pass goes through before continuing.
            // The intended effect is that viewDidAppear is called.
            RunLoop.main.run(until: Date())

            if vc.view.superview == nil {
                print("WARNING: present call failed. Adding view using addSubview instead. Use a host app for running your tests to avoid this.")
                addSubview(vc.view)
                RunLoop.main.run(until: Date())
            }
        }

        addSafeAreaHighlight()
    }

    @available(*, unavailable)
    override init(frame: CGRect) {
        fatalError("Please use init(size:view:) or init(size:viewController:)")
    }

    @available(*, unavailable)
    init() {
        fatalError("Please use init(size:view:) or init(size:viewController:)")
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("Please use init(size:view:) or init(size:viewController:)")
    }

    // MARK: - Layout

    override var traitCollection: UITraitCollection {
        UITraitCollection(traitsFrom: [super.traitCollection, size.traitCollection])
    }

    override var safeAreaInsets: UIEdgeInsets {
        size.safeAreaInsets
    }

    override func addSubview(_ view: UIView) {
        super.addSubview(view)
        if let highlightView = safeAreaHighlightView {
            bringSubviewToFront(highlightView)
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if case .viewController(let vc) = content {
            vc.traitCollectionDidChange(nil)
        }
    }

    // MARK: - SnapshotEnvironment

    private var baseKeyboardNotificationUserInfo: [AnyHashable: Any] {
        [
            UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: 7),
            UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 0.25),
            UIResponder.keyboardIsLocalUserInfoKey: NSNumber(value: true)
        ]
    }

    func showKeyboard() {
        guard size.keyboardSize != .zero else {
            XCTFail("Cannot show keyboard for snapshot size: \(size)")
            return
        }

        guard keyboardView == nil else {
            XCTFail("Cannot show keyboard when keyboard is already shown")
            return
        }

        let view = createMockKeyboardView(with: size.onscreenKeyboardFrame)
        addSubview(view)
        keyboardView = view

        var userInfo = baseKeyboardNotificationUserInfo
        userInfo[UIResponder.keyboardFrameBeginUserInfoKey] = size.offscreenKeyboardFrame
        userInfo[UIResponder.keyboardFrameEndUserInfoKey] = size.onscreenKeyboardFrame
        NotificationCenter.default.post(name: UIResponder.keyboardWillShowNotification, object: nil, userInfo: userInfo)
        NotificationCenter.default.post(name: UIResponder.keyboardDidShowNotification, object: nil, userInfo: userInfo)
    }

    func hideKeyboard() {
        keyboardView?.removeFromSuperview()

        var userInfo = baseKeyboardNotificationUserInfo
        userInfo[UIResponder.keyboardFrameBeginUserInfoKey] = size.onscreenKeyboardFrame
        userInfo[UIResponder.keyboardFrameEndUserInfoKey] = size.offscreenKeyboardFrame
        NotificationCenter.default.post(name: UIResponder.keyboardWillHideNotification, object: nil, userInfo: userInfo)
        NotificationCenter.default.post(name: UIResponder.keyboardDidHideNotification, object: nil, userInfo: userInfo)
    }

    private func createMockKeyboardView(with frame: CGRect) -> UIView {
        let strokeColor = UIColor.darkGray
        let strokeWidth: CGFloat = 2

        let view = UIView(frame: frame)
        view.backgroundColor = .gray
        view.layer.borderColor = strokeColor.cgColor
        view.layer.borderWidth = strokeWidth
        view.layer.masksToBounds = true

        let path = UIBezierPath()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: frame.width, y: frame.height))
        path.move(to: CGPoint(x: 0, y: frame.height))
        path.addLine(to: CGPoint(x: frame.width, y: 0))

        let overlay = CAShapeLayer()
        overlay.frame = view.bounds
        overlay.path = path.cgPath
        overlay.strokeColor = strokeColor.cgColor
        overlay.lineWidth = strokeWidth
        overlay.fillColor = nil
        view.layer.addSublayer(overlay)

        return view
    }

    // MARK: - Helpers

    private func addSafeAreaHighlight() {
        let highlightView = SafeAreaHighlightView(frame: bounds)
        highlightView.isOpaque = false
        addSubview(highlightView)
        safeAreaHighlightView = highlightView
    }
}

private final class SafeAreaHighlightView: UIView {
    override func draw(_ rect: CGRect) {
        func fillRect(_ rect: CGRect) {
            UIColor.red.withAlphaComponent(0.2).setFill()
            UIRectFill(rect)
        }

        if safeAreaInsets.top > 0 {
            fillRect(CGRect(x: 0,
                            y: 0,
                            width: bounds.width,
                            height: safeAreaInsets.top))
        }
        if safeAreaInsets.bottom > 0 {
            fillRect(CGRect(x: 0,
                            y: bounds.height - safeAreaInsets.bottom,
                            width: bounds.width,
                            height: safeAreaInsets.bottom))
        }
        if safeAreaInsets.left > 0 {
            fillRect(CGRect(x: 0,
                            y: safeAreaInsets.top,
                            width: safeAreaInsets.left,
                            height: bounds.height - safeAreaInsets.top - safeAreaInsets.bottom))
        }
        if safeAreaInsets.right > 0 {
            fillRect(CGRect(x: bounds.width - safeAreaInsets.right,
                            y: safeAreaInsets.top,
                            width: safeAreaInsets.right,
                            height: bounds.height - safeAreaInsets.top - safeAreaInsets.bottom))
        }
    }
}

private extension UIApplication {
    @objc func setForcedUserInterfaceLayoutDirection(_ direction: UIUserInterfaceLayoutDirection) {
        if responds(to: Selector(("_setForcedUserInterfaceLayoutDirection:"))) {
            perform(Selector(("_setForcedUserInterfaceLayoutDirection:")), with: direction.rawValue)
        }
    }
}
