//
// Created by De Wildt van Reenen on 11/7/16.
// Copyright (c) 2016 Broken-D. All rights reserved.
//

import Foundation
import EventKit

let MAX_AUTH_WAIT = 20.0  // Maximum seconds to wait for calendar authorizations

public enum SyncOperation {
    case none
    case printHelp
    case syncCalendars
    case deleteDestinationEvents
    case listCalendars
}

public enum SyncEventAction {
    case create
    case update
    case delete
}

public struct SyncEvent {
    var action = SyncEventAction.create
    var srcEvent : EKEvent
    var dstEvent : EKEvent?
    var srcHash : String

    public init(action : SyncEventAction, src: EKEvent, dst: EKEvent?, srcHash: String) {
        self.action = action
        self.srcEvent = src
        self.dstEvent = dst
        self.srcHash = srcHash
    }
}

public class SyncArguments {
    private(set) var maxAuthorizeWaitSeconds = MAX_AUTH_WAIT
    // Maximum seconds to wait for calendar authorization
    private(set) var operation = SyncOperation.none
    private(set) var forceUpdate = false
    //Update even if no changes are found
    private(set) var testMode = false
    //Test only don't do any real updates
    private(set) var srcCalID = ""
    private(set) var dstCalID = ""

    private(set) var verbose = false
    private(set) var syncTitle = true
    private(set) var syncLocation = true
    private(set) var syncNotes = true
    private(set) var syncAvailability = true
    private(set) var prefix : String = CAL_SYNC_DEFAULT_PREFEX
    private(set) var historyDays = 7
    private(set) var futureDays = 14

    func validateArgs() throws {
        if (operation == SyncOperation.deleteDestinationEvents && dstCalID.isEmpty) {
            throw SyncArgumentError.noDestinationCalendar
        }
        if (operation == SyncOperation.syncCalendars && dstCalID.isEmpty) {
            throw SyncArgumentError.noDestinationCalendar
        }
        if (operation == SyncOperation.syncCalendars && srcCalID.isEmpty) {
            throw SyncArgumentError.noSourceCalendar
        }
        if (prefix.isEmpty) {
            throw SyncArgumentError.noPrefix
        }

        return
    }

    init(args: [String]) throws {
        var previous = ""  //Previous found argument
        var first = true   //Is the first argument?

        for argument in args {
            if first {
                first = false
                continue  //Skip the program name
            }

            //Reset operation to check for new ones
            var newOperation = SyncOperation.none

            //Check if we are reading a calendar ID
            switch previous {
            case "--src":
                srcCalID = argument
            case "--dst":
                dstCalID = argument
            case "--prefix":
                prefix = argument
            default:
                //Read this argument it is not a calendar ID
                switch argument {
                case "--src":
                    break;
                case "--dst":
                    break;
                case "--list":
                    newOperation = SyncOperation.listCalendars
                case "--test":
                    testMode = true
                case "--delete":
                    newOperation = SyncOperation.deleteDestinationEvents
                case "--force":
                    forceUpdate = true
                case "--verbose":
                    verbose = true
                case "--help":
                    newOperation = SyncOperation.printHelp
                case "--no-title":
                    syncTitle = false
                case "--no-notes":
                    syncNotes = false
                case "--no-location":
                    syncLocation = false
                case "--no-avail":
                    syncAvailability = false
                case "--prefix":
                    prefix = ""
                default:
                    print("Invalid/unknown argument \"\(argument)\"")
                    newOperation = SyncOperation.printHelp
                }
            }

            if (newOperation != SyncOperation.none && operation != SyncOperation.none) {
                throw SyncArgumentError.singleCommandOnly
            } else if newOperation != SyncOperation.none {
                operation = newOperation
            }

            previous = argument;
        }

        if operation == SyncOperation.none {
            operation = SyncOperation.syncCalendars
        }

        try validateArgs()

    }
}
