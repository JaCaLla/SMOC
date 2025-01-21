//
//  SMOCTests.swift
//  SMOCTests
//
//  Created by Javier Calatrava on 14/1/25.
//

import Foundation
@testable import SMOC
import Testing

struct SMOCTests {

    @Test func testAppVerssion() async throws {
        guard let appVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let appBuild = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
            fatalError("testAppVersionAndBuild failed on fetching keys from dictionary")
        }
        #expect(appVersion == "0.0.1")
        #expect(appBuild == "4")
    }

}
