//
//  OACrashDiagnosticsKSCrashBridge.mm
//  OsmAnd Maps
//

#import "OACrashDiagnosticsKSCrashBridge.h"

#import <KSCrash.h>
#import <KSCrashConfiguration.h>
#import <KSCrashReport.h>
#import <KSCrashReportStore.h>

#include <signal.h>
#include <stdexcept>

@implementation OACrashDiagnosticsKSCrashBridge

+ (BOOL)installAtPath:(NSString *)installPath
{
    static BOOL installed = NO;
    if (installed)
        return YES;

    KSCrashConfiguration *configuration = [KSCrashConfiguration new];
    configuration.installPath = installPath;
    configuration.reportStoreConfiguration.reportsPath = [installPath stringByAppendingPathComponent:@"RawReports"];
    configuration.reportStoreConfiguration.maxReportCount = 3;
    configuration.reportStoreConfiguration.reportCleanupPolicy = KSCrashReportCleanupPolicyNever;
    configuration.monitors = KSCrashMonitorTypeMachException
        | KSCrashMonitorTypeSignal
        | KSCrashMonitorTypeCPPException
        | KSCrashMonitorTypeNSException
        | KSCrashMonitorTypeSystem
        | KSCrashMonitorTypeApplicationState;
    configuration.deadlockWatchdogInterval = 0;
    configuration.enableQueueNameSearch = NO;
    configuration.enableMemoryIntrospection = NO;
    configuration.doNotIntrospectClasses = @[];
    configuration.addConsoleLogToReport = NO;
    configuration.printPreviousLogOnStartup = NO;
    configuration.enableSigTermMonitoring = NO;
    configuration.userInfoJSON = @{ @"privacy_schema" : @1 };

    NSError *error = nil;
    installed = [KSCrash.sharedInstance installWithConfiguration:configuration error:&error];
    if (!installed)
        NSLog(@"[CrashDiagnostics] KSCrash installation failed: %@", error.localizedDescription ?: @"unknown");
    return installed;
}

+ (NSArray<NSDictionary<NSString *, id> *> *)pendingReports
{
    KSCrashReportStore *store = KSCrash.sharedInstance.reportStore;
    if (store == nil)
        return @[];

    NSMutableArray<NSDictionary<NSString *, id> *> *reports = [NSMutableArray array];
    for (NSNumber *reportID in store.reportIDs)
    {
        KSCrashReportDictionary *report = [store reportForID:reportID.longLongValue];
        if (report != nil)
        {
            [reports addObject:@{
                @"report_id" : reportID,
                @"report" : report.value,
            }];
        }
    }
    return reports;
}

+ (void)deleteReportWithID:(int64_t)reportID
{
    [KSCrash.sharedInstance.reportStore deleteReportWithID:reportID];
}

#if DEBUG
+ (void)triggerObjectiveCException
{
    [NSException raise:@"OsmAndCrashDiagnosticsTest"
                format:@"Intentional crash generated from the diagnostics developer menu"];
}

+ (void)triggerSignalCrash
{
    raise(SIGABRT);
}

+ (void)triggerInvalidMemoryAccess
{
    volatile int *invalidAddress = (int *)0x1;
    *invalidAddress = 1;
}

+ (void)triggerCPPException
{
    throw std::runtime_error("Intentional OsmAnd crash diagnostics C++ test");
}
#endif

@end
