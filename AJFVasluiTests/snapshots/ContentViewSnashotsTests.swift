//
//  ContentViewSnashotsTests.swift
//  AJFVasluiTests
//
//  Created by Andrei-Stefan BURSUC on 24.04.2024.
//

import SwiftUI
import XCTest
@testable import AJFVaslui
import iOSSnapshotTestCase

final class ContentViewSnashotsTests: TestCase {

    private let config = SnapShotTestConfiguration.permutations(sizes: [.automaticHeight(targetWidth: 320)],
                                                                contentSizeCategories: [.large],
                                                                languages: ["en-EN"],
                                                                includeRightToLeft: false)

    override func setUp() {
        super.setUp()

        recordMode = false
    }

    func testContentView() {
        let view = ContentView()
        guard let hostedView = UIHostingController(rootView: view).view else {
            XCTFail("unabled to create hosting view controller")
            return
        }

        verifyView(configurations: config) { _ in
            hostedView
        }

    }

}
