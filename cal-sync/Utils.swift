//
// Created by De Wildt van Reenen on 11/7/16.
// Copyright (c) 2016 Broken-D. All rights reserved.
//

import Foundation
import Security.CipherSuite
import EventKit

let CAL_SYNC_DEFAULT_PREFEX = "cal-sync"

func makeHashSHA1(data: String) -> String {
    var error: Unmanaged<CFError>?
    let transform = SecDigestTransformCreate(kSecDigestHMACSHA1, 0, &error)

    let inputData = data.data(using: String.Encoding.utf8)!

    SecTransformSetAttribute(transform, kSecTransformInputAttributeName, inputData as CFTypeRef, &error)

    let outputData = SecTransformExecute(transform, &error) as! Data

    return outputData.base64EncodedString().trimmingCharacters(in: ["="])
}

func createEventStore(maxAuthWaitSeconds: Double) throws -> EKEventStore {
    //Request permissions and Load the calendars
    var accessComplete = false
    var gotAccess = false

    let eventStore = EKEventStore()
    eventStore.requestAccess(to: EKEntityType.event, completion: { (accessGranted: Bool, error: Error?) in
        if accessGranted == true {
            gotAccess = true
        } else {
            gotAccess = false
        }
        accessComplete = true
    })

    let increment = UInt32(1000000 / 4)
    var seconds: Double = 0
    while (accessComplete == false && seconds < maxAuthWaitSeconds) {
        usleep(increment)
        seconds = seconds + (Double(increment) / 1000000.0)
    }

    if gotAccess == false {
        throw SyncError.noCalendarAccess
    }

    return eventStore
}