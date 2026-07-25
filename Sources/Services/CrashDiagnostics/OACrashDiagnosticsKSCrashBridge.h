//
//  OACrashDiagnosticsKSCrashBridge.h
//  OsmAnd Maps
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface OACrashDiagnosticsKSCrashBridge : NSObject

+ (BOOL)installAtPath:(NSString *)installPath NS_SWIFT_NAME(install(atPath:));
+ (NSArray<NSDictionary<NSString *, id> *> *)pendingReports;
+ (void)deleteReportWithID:(int64_t)reportID NS_SWIFT_NAME(deleteReport(withID:));

#if DEBUG
+ (void)triggerObjectiveCException;
+ (void)triggerSignalCrash;
+ (void)triggerInvalidMemoryAccess;
+ (void)triggerCPPException;
#endif

@end

NS_ASSUME_NONNULL_END
