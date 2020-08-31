// Copyright 2020 Raising the Floor - International
// Copyright 2020 OCAD University
//
// Licensed under the New BSD license. You may not use this file except in
// compliance with this License.
//
// You may obtain a copy of the License at
// https://github.com/GPII/universal/blob/master/LICENSE.txt
//
// The R&D leading to these results received funding from the:
// * Rehabilitation Services Administration, US Dept. of Education under
//   grant H421A150006 (APCP)
// * National Institute on Disability, Independent Living, and
//   Rehabilitation Research (NIDILRR)
// * Administration for Independent Living & Dept. of Education under grants
//   H133E080022 (RERC-IT) and H133E130028/90RE5003-01-00 (UIITA-RERC)
// * European Union's Seventh Framework Programme (FP7/2007-2013) grant
//   agreement nos. 289016 (Cloud4all) and 610510 (Prosperity4All)
// * William and Flora Hewlett Foundation
// * Ontario Ministry of Research and Innovation
// * Canadian Foundation for Innovation
// * Adobe Foundation
// * Consumer Electronics Association Foundation
//
//  StorageTests.swift
//  MorphicCoreTests

import XCTest
@testable import MorphicCore

class StorageTests: XCTestCase {

    public private(set) var storage = Storage.shared

    var prefsToStore: Preferences!
    let prefsId = UUID().uuidString
    let userId = UUID().uuidString

    let magnifierName = "Magnifier"
    let magFactorPref = "magfactor"
    let magFactorVal: Double = 2.5
    let magFactorKey = Preferences.Key(solution: "Magnifier", preference: "magFactor")

    let inverseVideoPref = "inverse_video"
    let inverseVideoVal: Bool = true
    let inverseVideoKey = Preferences.Key(solution: "Magnifier", preference: "inverse_video")

    let defaultsId = "__default__"
    let defaultsUserId:String? = nil

    let noSuchPrefsId = "NoSuchPrefsIdZzz"
    let fileManager:FileManager = .default

    override func setUpWithError() throws {
        prefsToStore = Preferences(identifier: prefsId)
        prefsToStore.userId = userId
        prefsToStore.set(magFactorVal, for: magFactorKey)
        prefsToStore.set(inverseVideoVal, for: inverseVideoKey)
    }

    override func tearDownWithError() throws {
        let removeExpect = XCTestExpectation(description: "Test removal of preferences")
        try storage.remove(record: prefsToStore, completion: { (_ status:Storage.LoadStatus, _ prefs:Preferences? ) -> Void in
            let actualPrefsId = prefs?.identifier ?? ""
            XCTAssertEqual(status, Storage.LoadStatus.success, "Test remove preferences from Storage " + actualPrefsId)
            removeExpect.fulfill()
        })
        wait(for: [removeExpect], timeout: 10.0)

        prefsToStore.remove(key: magFactorKey)      // necessary?
        prefsToStore.remove(key: inverseVideoKey)   // necessary?
        prefsToStore = nil
    }

    func testSaveReload() {
        let saveExpect = XCTestExpectation(description: "Test saving of preferences")
        let loadExpect = XCTestExpectation(description: "Test loading of just saved preferences")
        storage.save(record: prefsToStore, completion: { (_ saveSuccessful: Bool) -> Void in
            XCTAssertTrue(saveSuccessful, "Test storing preferences")
            saveExpect.fulfill()
        })
        storage.load(identifier: prefsId, completion: { (_ status:Storage.LoadStatus, _ actual: Preferences?) -> Void in
            XCTAssertEqual(status, Storage.LoadStatus.success, "Test success status on load of preferences")
            guard let actualPrefs = actual else {
                XCTFail("Test loading preferences: failed to load")
                loadExpect.fulfill()
                return
            }
            XCTAssertEqual(actualPrefs.userId, self.userId, "Test loaded preferences user id")

            let loadedMagFactor: Double = actualPrefs.get(key: self.magFactorKey) as! Double
            XCTAssertEqual(loadedMagFactor, self.magFactorVal, "Test loaded magnification factor")

            let loadedInverseVideo: Bool = actualPrefs.get(key: self.inverseVideoKey) as! Bool
            XCTAssertEqual(loadedInverseVideo, self.inverseVideoVal, "Test loaded inverse video")

            loadExpect.fulfill()
        })
        wait(for: [saveExpect, loadExpect], timeout: 10.0, enforceOrder: true)
    }

    func testContains() {
        let containExpect = XCTestExpectation(description: "Test store contains preferences")
        storage.save(record: prefsToStore, completion: { (_ succeeded: Bool) -> Void in
            if succeeded {
                var isContained = self.storage.contains(identifier: self.prefsId, type: Preferences.self)
                XCTAssertTrue(isContained, "Test store contains known preferences")
                isContained = self.storage.contains(identifier: self.noSuchPrefsId, type: Preferences.self)
                XCTAssertFalse(isContained, "Test store does not contains unknown preferences")
            } else {
                XCTFail("Test store for contains preferences: failure to save preferences")
            }
            containExpect.fulfill()
        })
        wait(for: [containExpect], timeout: 10.0)
    }

    func testLoadDefaults() {
        let loadExpect = XCTestExpectation(description: "Test loading from default preferences")
        storage.load(identifier: defaultsId, completion: { (_ status:Storage.LoadStatus, _ actual: Preferences?) -> Void in
            XCTAssertEqual(status, Storage.LoadStatus.success, "Test success status on load of default preferences")
            guard let actualPrefs = actual else {
                XCTFail("Test loading default preferences: failed to load")
                loadExpect.fulfill()
                return
            }
            XCTAssertEqual(actualPrefs.identifier, self.defaultsId, "Test loaded default preferences identifier")
            XCTAssertEqual(actualPrefs.userId, self.defaultsUserId, "Test loaded default preferences user id")
            loadExpect.fulfill()
        })
        wait(for: [loadExpect], timeout: 10.0)
    }
}
