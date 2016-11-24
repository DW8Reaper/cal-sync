//
//  main.swift
//  cal-sync
//
//  Created by De Wildt van Reenen on 11/7/16.
//  Copyright (c) 2016 Broken-D. All rights reserved.
//

import Foundation
import EventKit

func printHelp() {
    print("\nUsage: CalendarSync <arguments>")
    print("  --help               print this help message")
    print("  --list               List available calendars ")
    print("  --src <calendar ID>  ID of source calendar to copy from ")
    print("  --dst <calendar ID>  ID of the destination calendar to copy to ")
    print("  --test               Test mode don't commit changes ")
    // print("  --force              Force update even if no changes are detected")
    print("  --prefix <prefix>    URL Prefix to identify synced events. Default \(CAL_SYNC_DEFAULT_PREFEX)")
    print("  --no-title           Do not sync event titles")
    print("  --no-location        Do not sync event locations")
    print("  --no-notes           Do not sync event notes")
    print("  --no-avail           Do not sync availability (set to free)")
    print("  --verbose            Verbose output print actions performed")
    print("\n")
}

func printCalendars() throws {
    let store = try createEventStore(maxAuthWaitSeconds: MAX_AUTH_WAIT)
    var cals = store.calendars(for: EKEntityType.event)

    print()
cals.sort(by: { (left : EKCalendar, right : EKCalendar) in return left.source.title.compare(right.source.title) == ComparisonResult.orderedAscending })
var prev : String?
for calendar : EKCalendar in cals {
    if prev == nil || prev != calendar.source.title {
        print("  \(calendar.source.title)")
        prev = calendar.source.title
    }

    print("      \"\(calendar.title)\": \(calendar.calendarIdentifier) ")
}
print()
}

func run() throws {

    do {
        let args = try SyncArguments(args: CommandLine.arguments)


        switch args.operation {
            case SyncOperation.printHelp:
                printHelp()
            case SyncOperation.listCalendars:
                try printCalendars()
            case SyncOperation.syncCalendars:
                let calSync = try CalendarSync(syncConfig: args)
                let actions = try calSync.determineEventActions()

                print()
                if (args.testMode) {
                    print("\n TEST MODE!! \n\n")
                }
                print("Sync from calendar \(calSync.getSourceName())")
                print("       to calendar \(calSync.getDestinationName())")
                print()

                if actions.isEmpty {
                    print("All events are up to date")
                } else {
                    try calSync.syncEvents(actions: actions)
                }

                print()
            default:
                printHelp()
        }

    } catch SyncError.noCalendarAccess {
        print("Access denied to calendar data")
    } catch SyncError.invalidSourceCalendar {
        print("Specified source calendar does not exist")
    } catch SyncError.invalidDestinationCalendar {
        print("Specified destination calendar does not exist")
    } catch SyncError.sameSrcDst {
            print("Same calendar id provided for source and destination")
            printHelp()
    } catch SyncArgumentError.singleCommandOnly {
        print("Use only one command list/delete/help at a time")
        printHelp()
    } catch SyncArgumentError.noDestinationCalendar {
        print("No destination calendar provided")
        printHelp()
    } catch SyncArgumentError.noSourceCalendar {
        print("No source calendar provided")
        printHelp()
    } catch SyncArgumentError.noPrefix {
        print("No prefix was given with --prefix")
        printHelp()
    }
}

try run()