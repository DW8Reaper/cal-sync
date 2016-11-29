//
//  TestCalendarSync.swift
//  cal-sync
//
//  Created by De Wildt van Reenen on 11/7/16.
//  Copyright (c) 2016 Broken-D. All rights reserved.
//

import XCTest
import EventKit

enum TestSyncResult {
    case sync
    case none
    case delete
}

class TestCalendarSync: XCTestCase {

    var cleanupTestCalendars = false
    var eventStore: EKEventStore?
    var srcCalendar: EKCalendar?
    var dstCalendar: EKCalendar?
    var srcId = ""
    var dstId = ""

    var testEvent1: EKEvent?
    var testEvent2: EKEvent?
    var testEvent3: EKEvent?
    var testEvent4: EKEvent?
    var testEvent5: EKEvent?

    let syncDateStart = Date(timeIntervalSinceNow: TimeInterval(-20000))
    let syncDateEnd = Date(timeIntervalSinceNow: TimeInterval(40000))

    func makeEvent(calendar: EKCalendar, title: String, location: String, start: Date, end: Date, allDay: Bool, available: EKEventAvailability, notes: String, url: String, rule: EKRecurrenceRule? = nil) throws -> EKEvent {
        let event = EKEvent(eventStore: eventStore!)
        event.calendar = calendar
        event.title = title
        event.location = location
        event.availability = available
        event.startDate = start
        event.endDate = end
        event.isAllDay = allDay
        event.notes = notes
        event.url = URL(string: url)

        if let recRule = rule {
            event.addRecurrenceRule(recRule)
        }

        try eventStore!.save(event, span: EKSpan.thisEvent, commit: false)
        return event
    }

    override func setUp() {
        super.setUp()

        eventStore = try! createEventStore(maxAuthWaitSeconds: MAX_AUTH_WAIT)

        do {
            // create dates to test with
            let event1Start = Date(timeIntervalSinceNow: TimeInterval(-1200))
            let event1End = Date(timeIntervalSinceNow: TimeInterval(1200))
            let event2Start = Date(timeIntervalSinceNow: TimeInterval(24000))
            let event2End = Date(timeIntervalSinceNow: TimeInterval(36000))
            let event3Start = Date(timeIntervalSinceNow: TimeInterval(6000))
            let event3End = Date(timeIntervalSinceNow: TimeInterval(8000))


            let eventDest1Start = Date(timeIntervalSinceNow: TimeInterval(3000))
            let eventDest1End = Date(timeIntervalSinceNow: TimeInterval(4800))

            let eventDest2Start = Date(timeIntervalSinceNow: TimeInterval(-18000))
            let eventDest2End = Date(timeIntervalSinceNow: TimeInterval(-14000))

            // Find a source to put test calendars in
            var calendarSource: EKSource!
            for source: EKSource in eventStore!.sources {
                if (source.sourceType == EKSourceType.local && source.title == "On My Mac") {
                    calendarSource = source
                }
            }
            XCTAssert(calendarSource != nil, "Could not find a local calendar source call \"On My Mac\" to create test calendars")

            // Create a source calendar
            srcCalendar = EKCalendar(for: EKEntityType.event, eventStore: eventStore!)
            srcCalendar!.source = calendarSource
            srcCalendar!.title = "cal-sync source - unit test"

            // Create source events
            testEvent1 = try makeEvent(calendar: srcCalendar!, title: "event 1", location: "location 1",
                    start: event1Start,
                    end: event1End,
                    allDay: false, available: EKEventAvailability.busy,
                    notes: "notes 1",
                    url: "")

            let rule = EKRecurrenceRule(recurrenceWith: EKRecurrenceFrequency.daily, interval: 1, end: EKRecurrenceEnd(occurrenceCount: 3))
            testEvent2 = try makeEvent(calendar: srcCalendar!, title: "event 2", location: "location 2",
                    start: event2Start,
                    end: event2End,
                    allDay: false, available: EKEventAvailability.free,
                    notes: "notes 2",
                    url: "",
                    rule: rule)

            testEvent3 = try makeEvent(calendar: srcCalendar!, title: "event 3", location: "location 3",
                    start: event3Start,
                    end: event3End,
                    allDay: true, available: EKEventAvailability.busy,
                    notes: "notes 3",
                    url: "")
            try eventStore!.saveCalendar(srcCalendar!, commit: true)

            // Create a target calendar
            dstCalendar = EKCalendar(for: EKEntityType.event, eventStore: eventStore!)
            dstCalendar!.source = calendarSource
            dstCalendar!.title = "cal-sync target - unit test"


            // Create target events that must always stay

            testEvent4 = try makeEvent(calendar: dstCalendar!, title: "pre-existing target event", location: "location fixed",
                    start: eventDest1Start,
                    end: eventDest1End,
                    allDay: false, available: EKEventAvailability.busy,
                    notes: "notes fixed",
                    url: "")

            testEvent5 = try makeEvent(calendar: dstCalendar!, title: "pre-existing must delete", location: "location delete",
                    start: eventDest2Start,
                    end: eventDest2End,
                    allDay: false, available: EKEventAvailability.busy,
                    notes: "event that should delete",
                    url: CAL_SYNC_DEFAULT_PREFEX)


            // Save test calendars
            try eventStore!.saveCalendar(dstCalendar!, commit: true)

            // Save calendar ID's
            srcId = srcCalendar!.calendarIdentifier
            dstId = dstCalendar!.calendarIdentifier

        } catch {
            XCTFail("Unabled to create test calendars: \(error)")
        }
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.

        do {
            if srcId != nil && srcId.isEmpty == false {
                // get calendar again in case eventStore was reset
                srcCalendar = try eventStore?.calendar(withIdentifier: srcId)
                try eventStore?.removeCalendar(srcCalendar!, commit: true)
            }
        } catch {
            XCTFail("Failed to cleanup test source calendar")
        }

        do {
            if dstId != nil && dstId.isEmpty == false {
                // get calendar again in case eventStore was reset
                dstCalendar = try eventStore?.calendar(withIdentifier: dstId)
                try eventStore?.removeCalendar(dstCalendar!, commit: true)
            }
        } catch {
            XCTFail("Failed to cleanup test source calendar")
        }
        super.tearDown()
    }

    func testInvalidSrcDst() {

        do {
            let conf = try SyncArguments(args: ["program", "--src", dstId, "--dst", dstId])
            let _ = try CalendarSync(syncConfig: conf)
            XCTFail("No error for same src and dst")
        } catch SyncError.sameSrcDst {
        } catch {
            XCTFail("Unexpected error \(error) in test")
        }

        do {
            let conf = try SyncArguments(args: ["program", "--src", "Invalid calendar ID", "--dst", dstId])
            let _ = try CalendarSync(syncConfig: conf)
            XCTFail("No error with invalid destination calendar")
        } catch (SyncError.invalidSourceCalendar) {
            // This is the expected behaviour
        } catch {
            XCTFail("Unexpected error \(error) in test")
        }
        
        do {
            let conf = try SyncArguments(args: ["program", "--src", srcId, "--dst", "invalid calendar ID"])
            let _ = try CalendarSync(syncConfig: conf)
            XCTFail("No error with invalid destination calendar")
        } catch (SyncError.invalidDestinationCalendar) {
            // This is the expected behaviour
        } catch {
            XCTFail("Unexpected error \(error) in test")
        }
        
    }

    func testSync() throws {
        let conf = try SyncArguments(args: ["program", "--src", srcId, "--dst", dstId])
        let calSync = try CalendarSync(syncConfig: conf)

        // do an initial sync
        var act = try calSync.determineEventActions(from: syncDateStart, to: syncDateEnd)
        var act2 = try calSync.determineEventActions(from: syncDateStart, to: syncDateEnd)
        
        XCTAssert(act.count == act2.count, "similar calls to determineSyncActions returns different results")
        for i in 0...act.count-1 {
            XCTAssert(act[i].action == act2[i].action)
            XCTAssert(act[i].srcHash == act2[i].srcHash)
            XCTAssert(act[i].srcEvent == act2[i].srcEvent)
            XCTAssert(act[i].dstEvent == act2[i].dstEvent)
        }
        
        try calSync.syncEvents(actions: act)
        validateEvents(conf: conf, expectedEvents: [(TestSyncResult.sync, self.testEvent1!),
                                                    (TestSyncResult.sync, self.testEvent2!),
                                                    (TestSyncResult.sync, self.testEvent3!),
                                                    (TestSyncResult.none, self.testEvent4!),
                                                    (TestSyncResult.delete, self.testEvent5!)])
        
        // Sync complete make sure a subsequent sync action gets not actions
        act = try calSync.determineEventActions(from: syncDateStart, to: syncDateEnd)
        XCTAssert(act.isEmpty, "After sync more sync actions exist")

        // edit something and then make an update sync
        testEvent1!.title = "the new title"
        try eventStore!.save(testEvent1!, span: EKSpan.thisEvent, commit: true)
        calSync.resetEventStore()  // reset so it picks up new changes
        eventStore!.reset()

        act = try calSync.determineEventActions(from: syncDateStart, to: syncDateEnd)
        XCTAssert(act.count == 1, "Did not find updated event")
        if act.count > 0 {
            XCTAssert(act[0].action == SyncEventAction.update, "Event not flagged for update")
        }

        try calSync.syncEvents(actions: act)
        validateEvents(conf: conf, expectedEvents: [(TestSyncResult.sync, self.testEvent1!),
                                                    (TestSyncResult.sync, self.testEvent2!),
                                                    (TestSyncResult.sync, self.testEvent3!),
                                                    (TestSyncResult.none, self.testEvent4!)])
    }

    func testSyncWithoutTitle() throws {
        do {
        let conf = try SyncArguments(args: ["program", "--src", srcId, "--dst", dstId, "--no-title"])
        
        // Sync without titles
        let calSync = try CalendarSync(syncConfig: conf)
        let act = try calSync.determineEventActions(from: syncDateStart, to: syncDateEnd)
        try calSync.syncEvents(actions: act)
        self.testEvent1!.title = ""
        self.testEvent2!.title = ""
        self.testEvent3!.title = ""
        validateEvents(conf: conf, expectedEvents: [(TestSyncResult.sync, self.testEvent1!),
                                                    (TestSyncResult.sync, self.testEvent2!),
                                                    (TestSyncResult.sync, self.testEvent3!),
                                                    (TestSyncResult.none, self.testEvent4!),
                                                    (TestSyncResult.delete, self.testEvent5!)])
        } catch {
            XCTFail("Unexpected error \(error) in test")
        }
        
    }

    func testSyncWithoutNotes() throws {
        do {
            let conf = try SyncArguments(args: ["program", "--src", srcId, "--dst", dstId, "--no-notes"])

            // Sync without titles
            let calSync = try CalendarSync(syncConfig: conf)
            let act = try calSync.determineEventActions(from: syncDateStart, to: syncDateEnd)
            try calSync.syncEvents(actions: act)
            self.testEvent1!.notes = nil
            self.testEvent2!.notes = nil
            self.testEvent3!.notes = nil
            validateEvents(conf: conf, expectedEvents: [(TestSyncResult.sync, self.testEvent1!),
                                                        (TestSyncResult.sync, self.testEvent2!),
                                                        (TestSyncResult.sync, self.testEvent3!),
                                                        (TestSyncResult.none, self.testEvent4!),
                                                        (TestSyncResult.delete, self.testEvent5!)])
        } catch {
            XCTFail("Unexpected error \(error) in test")
        }

    }

    func testListCalendars() {
        do {
            let conf = try SyncArguments(args: ["program", "--src", srcId, "--dst", dstId, "--no-location"])
        }  catch {
            XCTFail("Unexpected error \(error) in test")
        }
    }

    func testSyncWithoutLocation() {
        do {
            let conf = try SyncArguments(args: ["program", "--src", srcId, "--dst", dstId, "--no-location"])

            // Sync without titles
            let calSync = try CalendarSync(syncConfig: conf)
            let act = try calSync.determineEventActions(from: syncDateStart, to: syncDateEnd)
            try calSync.syncEvents(actions: act)
            self.testEvent1!.location = nil
            self.testEvent2!.location = nil
            self.testEvent3!.location = nil
            validateEvents(conf: conf, expectedEvents: [(TestSyncResult.sync, self.testEvent1!),
                                                        (TestSyncResult.sync, self.testEvent2!),
                                                        (TestSyncResult.sync, self.testEvent3!),
                                                        (TestSyncResult.none, self.testEvent4!),
                                                        (TestSyncResult.delete, self.testEvent5!)])
        } catch {
            XCTFail("Unexpected error \(error) in test")
        }

    }

    func testSyncCustomPrefix() {
        do {
            let conf = try SyncArguments(args: ["program", "--src", srcId, "--dst", dstId, "--prefix", "new-prefix"])
            let calSync = try CalendarSync(syncConfig: conf)

            // get sync actions
            var act = try calSync.determineEventActions(from: syncDateStart, to: syncDateEnd)

            try calSync.syncEvents(actions: act)
            validateEvents(conf: conf, expectedEvents: [(TestSyncResult.sync, self.testEvent1!),
                                                        (TestSyncResult.sync, self.testEvent2!),
                                                        (TestSyncResult.sync, self.testEvent3!),
                                                        (TestSyncResult.none, self.testEvent4!),
                                                        (TestSyncResult.none, self.testEvent5!)],
                           prefix: "new-prefix")  // this event has the wrong prefix and must not change now
        } catch {
            XCTFail("Unexpected error \(error) in test")
        }
    }

    func testSyncWithoutAvailability() throws {
        do {
            let conf = try SyncArguments(args: ["program", "--src", srcId, "--dst", dstId, "--no-avail"])

            // Sync without titles
            let calSync = try CalendarSync(syncConfig: conf)
            let act = try calSync.determineEventActions(from: syncDateStart, to: syncDateEnd)
            try calSync.syncEvents(actions: act)
            self.testEvent1!.availability = EKEventAvailability.free
            self.testEvent2!.availability = EKEventAvailability.free
            self.testEvent3!.availability = EKEventAvailability.free
            validateEvents(conf: conf, expectedEvents: [(TestSyncResult.sync, self.testEvent1!),
                                                        (TestSyncResult.sync, self.testEvent2!),
                                                        (TestSyncResult.sync, self.testEvent3!),
                                                        (TestSyncResult.none, self.testEvent4!),
                                                        (TestSyncResult.delete, self.testEvent5!)])
        } catch {
            XCTFail("Unexpected error \(error) in test")
        }

    }

    func validateEvents(conf : SyncArguments, expectedEvents expected: [(TestSyncResult, EKEvent)], prefix : String = CAL_SYNC_DEFAULT_PREFEX) {
        let events = eventStore!.events(matching: eventStore!.predicateForEvents(withStart: syncDateStart, end: syncDateEnd, calendars: [dstCalendar!]))
        
        var expectedEvents = expected
        
        for event in events {
            let start = floor(event.startDate.timeIntervalSince1970)
            let end = floor(event.endDate.timeIntervalSince1970)
            
            var found = false
            for (offset: index, element:(syncResult, expEvent)) in expectedEvents.enumerated() {
                let eventId = expected.index(where: { (r, e) in return r == syncResult && e == expEvent })! + 1

                if start == floor(expEvent.startDate.timeIntervalSince1970) && end == floor(expEvent.endDate.timeIntervalSince1970) {
                    if syncResult == TestSyncResult.delete {
                        XCTFail("Test event \"\(eventId)\" was not deleted")
                    } else {
                        // Check other values are correctly set
                        XCTAssert(event.title == expEvent.title, "Test event \"\(eventId)\" has the wrong title \"\(event.title)\"")
                        XCTAssert(event.location == expEvent.location, "Test event \"\(eventId)\" has the wrong location \"\(event.location)\"")
                        XCTAssert(event.isAllDay == expEvent.isAllDay, "Test event \"\(eventId)\" has the wrong isAllDay \"\(event.isAllDay)\"")
                        XCTAssert(event.notes == expEvent.notes, "Test event \"\(eventId)\" has the wrong notes \"\(event.notes)\"")
                        XCTAssert(event.availability == expEvent.availability, "Test event \"\(eventId)\" has the wrong availability \"\(event.availability)\"")

                        // Check that synchronized events have the correct prefix
                        if syncResult == TestSyncResult.sync {
                            XCTAssert(event.url!.absoluteString.hasPrefix(prefix), "URL for test event \"\(eventId)\" does not have the correct prefix")
                        }
                    }

                    // Remove and flag that we found this guy
                    expectedEvents.remove(at: index)
                    found = true
                    break
                }
            }

            if found == false {
                XCTFail("Unknown/unexpected event \(event.title)")
            }
        }

        // expected events list must now only contain events that were deleted else we have an expected event
        // that did not exist in the calendar
        var expCount = 0
        for (syncResult, expEvent) in expected {
            if syncResult != TestSyncResult.delete {
                expCount += 1
            }
        }

        // check exact event count
        XCTAssert(events.count == expCount, "incorrect number of events in target calendar")

        // expected events list must now only contain events that were deleted else we have an expected event
        // that did not exist in the calendar
        for (syncResult, expEvent) in expectedEvents {
            if syncResult != TestSyncResult.delete {
                XCTFail("Could not find the expected event: \(expEvent.title)")
            }
        }

    }

}
