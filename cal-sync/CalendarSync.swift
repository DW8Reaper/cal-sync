//
// Created by De Wildt van Reenen on 11/7/16.
// Copyright (c) 2016 Broken-D. All rights reserved.
//

import Foundation
import EventKit


public class CalendarSync {

    private var syncConfig: SyncArguments

    private(set) var srcCalendar: EKCalendar
    private(set) var dstCalendar: EKCalendar
    private(set) var syncStart: Date
    private(set) var syncEnd: Date

    private var eventStore = EKEventStore()

    init(syncConfig: SyncArguments) throws {
        //Store configuration
        self.syncConfig = syncConfig

        eventStore = try createEventStore(maxAuthWaitSeconds: MAX_AUTH_WAIT)
        guard let src = eventStore.calendar(withIdentifier: syncConfig.srcCalID) else {
            throw SyncError.invalidSourceCalendar
        }
        guard let dst = eventStore.calendar(withIdentifier: syncConfig.dstCalID) else {
            throw SyncError.invalidDestinationCalendar
        }

        guard src.calendarIdentifier != dst.calendarIdentifier else {
            throw SyncError.sameSrcDst
        }

        srcCalendar = src
        dstCalendar = dst

        syncStart = Date().addingTimeInterval(TimeInterval(-syncConfig.historyDays*24*60*60))
        syncEnd =  Date().addingTimeInterval(TimeInterval(syncConfig.futureDays*24*60*60))

    }

    private func getName(calendar: EKCalendar) -> String {
        return "\(calendar.source.title): \"\(calendar.title)\" (\(calendar.title))"
    }

    public func getSourceName() -> String {
        return getName(calendar: srcCalendar)
    }

    public func getDestinationName() -> String {
        return getName(calendar: dstCalendar)
    }

    public func makeHash(event: EKEvent, config: SyncArguments) -> String {

        let sep = ";;##--##;;"

        var data: String = "\(event.startDate) to \(event.endDate) length \(event.isAllDay)"

        if config.syncTitle {
            data = "\(data)\(sep)\(event.title)"
        }

        if config.syncLocation {
            data = "\(data)\(sep)\(event.location)"
        }

        if config.syncAvailability {
            data = "\(data)\(sep)\(event.availability.rawValue)"
        } else {
            data = "\(data)\(sep)FREE"
        }

        if config.syncNotes {
            data = "\(data)\(sep)\(event.notes)"
        }

        return makeHashSHA1(data: data)
    }

    public func determineEventActions() throws -> [SyncEvent] {
        return try determineEventActions(from: syncStart, to: syncEnd)
    }

    public func determineEventActions(from: Date, to: Date) throws -> [SyncEvent] {
        var dstEvents: [String: EKEvent] = [:]
        var actions: [SyncEvent] = []
        var processed: [String] = []

        //Get destination events and remove them
        let dstStartDate = Date(timeIntervalSinceNow: TimeInterval((-200 * 1) * 24 * 60 * 60))
        let dstEndDate = Date(timeIntervalSinceNow: TimeInterval((200 * 1) * 24 * 60 * 60))
        let dstEventMatcher = eventStore.predicateForEvents(withStart: dstStartDate, end: dstEndDate, calendars: [dstCalendar])
        let dstEvList = eventStore.events(matching: dstEventMatcher)

        for dstEvent in dstEvList {
            if let url = dstEvent.url {
                if url.absoluteString.hasPrefix(syncConfig.prefix) {
                    var parts: [String] = url.absoluteString.components(separatedBy: ":")
                    if parts.count == 3 {
                        dstEvents.updateValue(dstEvent, forKey: parts[2])
                    } else {
                        // doesn't have a valid ID but the prefix matched so add with own ID so it will be unique
                        dstEvents.updateValue(dstEvent, forKey: dstEvent.eventIdentifier)
                    }
                }
            }
        }

        //Get source events
        let srcEventMatcher = eventStore.predicateForEvents(withStart: from, end: to, calendars: [srcCalendar])
        let srcEvents = eventStore.events(matching: srcEventMatcher)

        for srcEvent in srcEvents {
            // only process recurring events the first time we find them
            if processed.contains(srcEvent.eventIdentifier) {
                continue
            } else {
                processed.append(srcEvent.eventIdentifier)
            }

            let srcHash = makeHash(event: srcEvent, config: syncConfig)
            if let dstEvent = dstEvents[srcEvent.eventIdentifier] {
                var parts: [String] = dstEvent.url!.absoluteString.components(separatedBy: ":")
                if ( parts.count < 2 ) || ( parts[1] != srcHash ) {
                    // exists but the data has changed
                    actions.append(SyncEvent(action: SyncEventAction.update, src: srcEvent, dst: dstEvent, srcHash: srcHash))
                }
                dstEvents.removeValue(forKey: srcEvent.eventIdentifier)
            } else {
                // New Event
                actions.append(SyncEvent(action: SyncEventAction.create, src: srcEvent, dst: nil, srcHash: srcHash))
            }
        }

        // remove any remaining events
        for (_, value) in dstEvents {
            actions.append(SyncEvent(action: SyncEventAction.delete, src: value, dst: value, srcHash: ""))
        }
        return actions
    }

    private func copyEvent(src: EKEvent, hash: String, dst: EKEvent) {
        dst.calendar = dstCalendar
        dst.startDate = src.startDate
        dst.endDate = src.endDate
        dst.isAllDay = src.isAllDay
        dst.alarms = src.alarms
        dst.url = URL(string: syncConfig.prefix + ":" + makeHash(event: src, config: syncConfig) + ":" + src.eventIdentifier)

        if syncConfig.syncTitle {
            dst.title = src.title
        } else {
            dst.title = ""
        }

        if syncConfig.syncNotes {
            dst.notes = src.notes
        } else {
            dst.notes = nil
        }

        if syncConfig.syncLocation {
            dst.location = src.location
        } else {
            dst.location = nil
        }

        if syncConfig.syncAvailability {
            dst.availability = src.availability
        } else {
            dst.availability = EKEventAvailability.free
        }

        if let rules = src.recurrenceRules {
            for rule : EKRecurrenceRule in rules {
                dst.addRecurrenceRule(rule)
            }
        }
    }

    public func resetEventStore() {
        eventStore.reset()
    }

    public func syncEvents(actions: [SyncEvent]) throws {
        let pref = (syncConfig.testMode) ? "TEST MODE ->  " : ""

        for action in actions {

            switch action.action {
                case SyncEventAction.delete:
                    if (syncConfig.verbose) {
                        print("  \(pref)Delete event \"\(action.srcEvent.title)\" (\(action.srcEvent.eventIdentifier)) starts \"\(action.srcEvent.startDate)\"")
                    }

                    if (syncConfig.testMode == false) {
                        try eventStore.remove(action.dstEvent!, span: EKSpan.thisEvent, commit: false)
                    }
                case SyncEventAction.create:
                    if (syncConfig.verbose) {
                        print("  \(pref)Create event \"\(action.srcEvent.title)\" (\(action.srcEvent.eventIdentifier)) starts \"\(action.srcEvent.startDate)\"")
                    }

                    if (syncConfig.testMode == false) {
                        let newEvent = EKEvent(eventStore: eventStore)
                        copyEvent(src: action.srcEvent, hash: action.srcHash, dst: newEvent)
                        try eventStore.save(newEvent, span: EKSpan.thisEvent, commit: false)
                    }
                case SyncEventAction.update:
                    if (syncConfig.verbose) {
                        print("  \(pref)Update event \"\(action.srcEvent.title)\" (\(action.srcEvent.eventIdentifier)) starts \"\(action.srcEvent.startDate)\"")
                    }

                    if (syncConfig.testMode == false) {
                        copyEvent(src: action.srcEvent, hash: action.srcHash, dst: action.dstEvent!)
                        try eventStore.save(action.dstEvent!, span: EKSpan.thisEvent, commit: false)
                    }
            }
        }

        if (syncConfig.testMode == false) {
            try eventStore.commit()
        }
    }

}