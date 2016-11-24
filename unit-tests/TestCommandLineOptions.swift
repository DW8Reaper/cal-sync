//
//  TestCommandLineOptions.swift
//  cal-sync
//
//  Created by De Wildt van Reenen on 11/7/16.
//  Copyright (c) 2016 Broken-D. All rights reserved.
//

import XCTest

class TestCommandLine: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testArgumentParseSyncValid() {

        // Test valid list calendars
        do {
            let args = try SyncArguments(args: ["program name", "--list"])
            XCTAssert(args.operation == SyncOperation.listCalendars, "Operation is not list")
        } catch {
            XCTFail("unexpected error in parsing valid arguments")
        }

        // Test valid sync calendar parameters
        do {
            let args = try SyncArguments(args: ["program name", "--src", "s1", "--dst", "d1"])
            XCTAssert(args.srcCalID == "s1", "Source calendar was not correctly set")
            XCTAssert(args.dstCalID == "d1", "Destination calendar was not correctly set")
            XCTAssert(args.forceUpdate == false, "forceUpdate must default to false")
            XCTAssert(args.testMode == false, "testMode must default to false")
            XCTAssert(args.maxAuthorizeWaitSeconds == MAX_AUTH_WAIT, "Maximum auth wait default is incorrect")
            XCTAssert(args.operation == SyncOperation.syncCalendars, "Operation did not defaul to sync")
        } catch {
            XCTFail("unexpected error in parsing valid aguments")
        }

        // Test valid sync calendar parameters with test mode
        do {
            let args = try SyncArguments(args: ["program name", "--src", "s1", "--test", "--dst", "d1"])
            XCTAssert(args.srcCalID == "s1", "Source calendar was not correctly set")
            XCTAssert(args.dstCalID == "d1", "Destination calendar was not correctly set")
            XCTAssert(args.forceUpdate == false, "forceUpdate must default to false")
            XCTAssert(args.testMode == true, "testMode must be true")
            XCTAssert(args.maxAuthorizeWaitSeconds == MAX_AUTH_WAIT, "Maximum auth wait default is incorrect")
            XCTAssert(args.operation == SyncOperation.syncCalendars, "Operation did not defaul to sync")
        } catch {
            XCTFail("unexpected error in parsing valid aguments")
        }
    }

    func testSyncPrefix() {
        do {
            var args = try SyncArguments(args: ["program name", "--src", "s1", "--dst", "d1"])
            XCTAssert(args.prefix == CAL_SYNC_DEFAULT_PREFEX, "invalid default prefix")

            args = try SyncArguments(args: ["program name", "--src", "s1", "--dst", "d1", "--prefix", "alternate"])
            XCTAssert(args.prefix == "alternate", "did not read custom prefix")

            do {
                try SyncArguments(args: ["program name", "--src", "s1", "--dst", "d1", "--prefix"])
                XCTFail("no error for prefix command without a value")
            } catch (SyncArgumentError.noPrefix) {
                return
            }

        } catch {
            XCTFail("unexpected error in parsing valid aguments")
        }

    }

    func testSyncExclude() {
        do {
        var args = try SyncArguments(args: ["program name", "--src", "s1", "--dst", "d1", "--no-title"])
        XCTAssert(args.syncNotes)
        XCTAssertFalse(args.syncTitle)
        XCTAssert(args.syncLocation)
        XCTAssert(args.syncAvailability)
        
        args = try SyncArguments(args: ["program name", "--src", "s1", "--dst", "d1", "--no-notes"])
        XCTAssertFalse(args.syncNotes)
        XCTAssert(args.syncTitle)
        XCTAssert(args.syncLocation)
        XCTAssert(args.syncAvailability)
        
        args = try SyncArguments(args: ["program name", "--src", "s1", "--dst", "d1", "--no-location"])
        XCTAssert(args.syncNotes)
        XCTAssert(args.syncTitle)
        XCTAssertFalse(args.syncLocation)
        XCTAssert(args.syncAvailability)
        
        args = try SyncArguments(args: ["program name", "--src", "s1", "--dst", "d1", "--no-avail"])
        XCTAssert(args.syncNotes)
        XCTAssert(args.syncTitle)
        XCTAssert(args.syncLocation)
        XCTAssertFalse(args.syncAvailability)
        
        args = try SyncArguments(args: ["program name", "--src", "s1", "--dst", "d1", "--no-notes", "--no-title"])
        XCTAssertFalse(args.syncNotes)
        XCTAssertFalse(args.syncTitle)
        XCTAssert(args.syncLocation)
        XCTAssert(args.syncAvailability)

        args = try SyncArguments(args: ["program name", "--src", "s1", "--dst", "d1", "--no-title", "--no-title", "--no-location"])
        XCTAssert(args.syncNotes)
        XCTAssertFalse(args.syncTitle)
        XCTAssertFalse(args.syncLocation)
        XCTAssert(args.syncAvailability)
            
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }
    
    func testArgumentParseSyncForce() {

        // Test valid sync calendar parameters
        do {
            let args = try SyncArguments(args: ["program name", "--src", "s1", "--dst", "d1", "--force"])
            XCTAssert(args.srcCalID == "s1", "Source calendar was not correctly set")
            XCTAssert(args.dstCalID == "d1", "Destination calendar was not correctly set")
            XCTAssert(args.forceUpdate == true, "forceUpdate did not get set to true")
            XCTAssert(args.testMode == false, "testMode must default to false")
            XCTAssert(args.maxAuthorizeWaitSeconds == MAX_AUTH_WAIT, "Maximum auth wait default is incorrect")
            XCTAssert(args.operation == SyncOperation.syncCalendars, "Operation did not defaul to sync")
        } catch {
            XCTFail("unexpected error in parsing valid aguments")
        }

        // try alternate order
        do {
            let args = try SyncArguments(args: ["program name", "--force", "--src", "s1", "--dst", "d1"])
            XCTAssert(args.srcCalID == "s1", "Source calendar was not correctly set")
            XCTAssert(args.dstCalID == "d1", "Destination calendar was not correctly set")
            XCTAssert(args.forceUpdate == true, "forceUpdate did not get set to true")
            XCTAssert(args.testMode == false, "testMode must default to false")
            XCTAssert(args.maxAuthorizeWaitSeconds == MAX_AUTH_WAIT, "Maximum auth wait default is incorrect")
            XCTAssert(args.operation == SyncOperation.syncCalendars, "Operation did not defaul to sync")
        } catch {
            XCTFail("unexpected error in parsing valid arguments")
        }

    }

    func testArgumentParseDelete() {

        // Test valid sync calendar parameters
        do {
            let args = try SyncArguments(args: ["program name", "--src", "s1", "--dst", "d1", "--delete"])
            XCTAssert(args.srcCalID == "s1", "Source calendar was not correctly set")
            XCTAssert(args.dstCalID == "d1", "Destination calendar was not correctly set")
            XCTAssert(args.forceUpdate == false, "forceUpdate did not get set to true")
            XCTAssert(args.testMode == false, "testMode must default to false")
            XCTAssert(args.maxAuthorizeWaitSeconds == MAX_AUTH_WAIT, "Maximum auth wait default is incorrect")
            XCTAssert(args.operation == SyncOperation.deleteDestinationEvents, "Operation did not get set to delete")
        } catch {
            XCTFail("unexpected error in parsing valid aguments")
        }

        // try alternate order
        do {
            let args = try SyncArguments(args: ["program name", "--test", "--force", "--delete", "--dst", "d1"])
            XCTAssert(args.srcCalID == "", "Source calendar was has value when not set")
            XCTAssert(args.dstCalID == "d1", "Destination calendar was not correctly set")
            XCTAssert(args.forceUpdate == true, "forceUpdate did not get set to true")
            XCTAssert(args.testMode == true, "testMode must be true")
            XCTAssert(args.maxAuthorizeWaitSeconds == MAX_AUTH_WAIT, "Maximum auth wait default is incorrect")
            XCTAssert(args.operation == SyncOperation.deleteDestinationEvents, "Operation not set to delete")
        } catch SyncArgumentError.noSourceCalendar {
            XCTFail("source calendar was required for delete")
        } catch {
            XCTFail("unexpected error in parsing valid aguments")
        }

    }


    func testArgumentParseList() {

        // Test valid sync calendar parameters
        do {
            let args = try SyncArguments(args: ["program name", "--src", "s1", "--dst", "d1", "--list"])
            XCTAssert(args.srcCalID == "s1", "Source calendar was not correctly set")
            XCTAssert(args.dstCalID == "d1", "Destination calendar was not correctly set")
            XCTAssert(args.forceUpdate == false, "forceUpdate did not get set to true")
            XCTAssert(args.testMode == false, "testMode must default to false")
            XCTAssert(args.maxAuthorizeWaitSeconds == MAX_AUTH_WAIT, "Maximum auth wait default is incorrect")
            XCTAssert(args.operation == SyncOperation.listCalendars, "Operation did not get set to list")
        } catch {
            XCTFail("unexpected error in parsing valid aguments")
        }

        // try alternate order
        do {
            let args = try SyncArguments(args: ["program name", "--list"])
            XCTAssert(args.srcCalID == "", "Source calendar was has value when not set")
            XCTAssert(args.dstCalID == "", "Destination calendar has value when not set")
            XCTAssert(args.forceUpdate == false, "forceUpdate did not default to false")
            XCTAssert(args.testMode == false, "testMode did not default to false")
            XCTAssert(args.maxAuthorizeWaitSeconds == MAX_AUTH_WAIT, "Maximum auth wait default is incorrect")
            XCTAssert(args.operation == SyncOperation.listCalendars, "Operation not set to list")
        } catch {
            XCTFail("unexpected error in parsing valid aguments")
        }

    }

    func testArgumentParseHelp() {

        // Test valid sync calendar parameters
        do {
            let args = try SyncArguments(args: ["program name", "--src", "s1", "--dst", "d1", "--help"])
            XCTAssert(args.srcCalID == "s1", "Source calendar was not correctly set")
            XCTAssert(args.dstCalID == "d1", "Destination calendar was not correctly set")
            XCTAssert(args.forceUpdate == false, "forceUpdate did not get set to true")
            XCTAssert(args.testMode == false, "testMode must default to false")
            XCTAssert(args.maxAuthorizeWaitSeconds == MAX_AUTH_WAIT, "Maximum auth wait default is incorrect")
            XCTAssert(args.operation == SyncOperation.printHelp, "Operation did not get set to help")
        } catch {
            XCTFail("unexpected error in parsing valid aguments")
        }

        // try alternate order
        do {
            let args = try SyncArguments(args: ["program name", "--help"])
            XCTAssert(args.srcCalID == "", "Source calendar was has value when not set")
            XCTAssert(args.dstCalID == "", "Destination calendar has value when not set")
            XCTAssert(args.forceUpdate == false, "forceUpdate did not default to false")
            XCTAssert(args.testMode == false, "testMode did not default to false")
            XCTAssert(args.maxAuthorizeWaitSeconds == MAX_AUTH_WAIT, "Maximum auth wait default is incorrect")
            XCTAssert(args.operation == SyncOperation.printHelp, "Operation not set to help")
        } catch {
            XCTFail("unexpected error in parsing valid aguments")
        }

    }

    func testArgumentMultiple() {

        do {
            let _ = try SyncArguments(args: ["program name", "--src", "s1", "--dst", "d1", "--help", "--delete"])
            XCTFail("no error for multiple commands")
        } catch SyncArgumentError.singleCommandOnly {
            // expected
        } catch {
            XCTFail("unexpected error in parsing valid aguments")
        }

        do {
            let _ = try SyncArguments(args: ["program name", "--src", "s1", "--dst", "d1", "--help", "--list"])
            XCTFail("no error for multiple commands")
        } catch SyncArgumentError.singleCommandOnly {
            // expected
        } catch {
            XCTFail("unexpected error in parsing valid aguments")
        }

        do {
            let _ = try SyncArguments(args: ["program name", "--src", "s1", "--dst", "d1", "--delete", "--help"])
            XCTFail("no error for multiple commands")
        } catch SyncArgumentError.singleCommandOnly {
            // expected
        } catch {
            XCTFail("unexpected error in parsing valid aguments")
        }
    }
}
