//
//  StartupLogging.h
//  OsmAnd
//
//  Created by Oleksandr Panchenko on 07.07.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OsmAnd_Maps-Swift.h"

#ifndef StartupLogging_h
#define StartupLogging_h

// Logs startup event with class name (from:self)
#define LogStartup(eventName) [[AppStartupMonitor shared] log:(eventName) from:self]

// Logs startup event without class name
#define LogStartupSimple(eventName) [[AppStartupMonitor shared] log:(eventName) from:nil]

// Marks startup as finished and prints timeline
#define MarkStartupFinished() [[AppStartupMonitor shared] markStartupFinishedIfNeeded]

#endif /* StartupLogging_h */
