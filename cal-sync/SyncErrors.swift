//
// Created by De Wildt van Reenen on 11/7/16.
// Copyright (c) 2016 Broken-D. All rights reserved.
//

import Foundation


public enum SyncError: Error {
    case noCalendarAccess
    case invalidSourceCalendar
    case invalidDestinationCalendar
    case sameSrcDst
}

public enum SyncArgumentError: Error {
    case singleCommandOnly
    case noDestinationCalendar
    case noSourceCalendar
    case noPrefix
}