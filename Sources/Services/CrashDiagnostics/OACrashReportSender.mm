//
//  OACrashReportSender.mm
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OACrashReportSender.h"
#import "OAMemoryLog.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAApplicationMode.h"
#import "OAPluginsHelper.h"
#import "OAPlugin.h"
#import "OARoutingHelper.h"
#import "OASelectedGPXHelper.h"
#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <malloc/malloc.h>
#import <os/proc.h>
#import <sys/utsname.h>
#import <sys/sysctl.h>

#include <OsmAndCore/ArchiveWriter.h>
#include <OsmAndCore/ResourcesManager.h>

static NSString * const kCrashReportURL = @"https://osmand.net/api/crash-report";
static NSString * const kStateName = @"state.txt";
static const NSUInteger kMaxCrashDiagnosticsInReport = 3;
// the memory log is kept at this size on disk too, so the whole ring travels
static const unsigned long long kMaxMemoryLogInReport = 4 * 1024 * 1024;
static const NSInteger kMaxTracksDepth = 8;

static NSString *mbString(uint64_t bytes)
{
    return [NSString stringWithFormat:@"%lluMB", bytes / (1024 * 1024)];
}

@implementation OACrashReportSender

+ (void)sendCrashReport:(NSArray<NSURL *> *)crashDiagnosticURLs completion:(void (^)(BOOL sent))completion
{
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        NSData *zip = [self buildReport:crashDiagnosticURLs];
        if (zip.length == 0)
        {
            dispatch_async(dispatch_get_main_queue(), ^{ completion(NO); });
            return;
        }
        NSDictionary *info = NSBundle.mainBundle.infoDictionary;
        NSURLComponents *components = [NSURLComponents componentsWithString:kCrashReportURL];
        components.queryItems = @[
            [NSURLQueryItem queryItemWithName:@"platform" value:@"ios"],
            [NSURLQueryItem queryItemWithName:@"version" value:info[@"CFBundleShortVersionString"] ?: @"0"],
            [NSURLQueryItem queryItemWithName:@"osversion" value:UIDevice.currentDevice.systemVersion]
        ];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:components.URL];
        request.HTTPMethod = @"POST";
        request.timeoutInterval = 120;
        [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"OsmAndiOS" forHTTPHeaderField:@"User-Agent"];
        NSURLSessionUploadTask *task = [NSURLSession.sharedSession uploadTaskWithRequest:request fromData:zip
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                NSInteger status = [response isKindOfClass:NSHTTPURLResponse.class] ? ((NSHTTPURLResponse *) response).statusCode : 0;
                BOOL sent = !error && status == 200;
                if (!sent)
                    NSLog(@"[CrashDiagnostics] Crash report upload failed: status=%ld error=%@", (long) status, error.localizedDescription);
                dispatch_async(dispatch_get_main_queue(), ^{ completion(sent); });
            }];
        [task resume];
    });
}

// the zip is built from copies in a scratch folder: the archive writer takes files relative to a
// base folder, and the originals keep being written while it runs
+ (NSData *)buildReport:(NSArray<NSURL *> *)crashDiagnosticURLs
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSURL *folder = [fileManager.temporaryDirectory URLByAppendingPathComponent:[NSString stringWithFormat:@"crash-report-%@", NSUUID.UUID.UUIDString]];
    if (![fileManager createDirectoryAtURL:folder withIntermediateDirectories:YES attributes:nil error:nil])
        return nil;

    NSMutableArray<NSString *> *names = [NSMutableArray array];
    NSString *state = [self buildState];
    if ([state writeToURL:[folder URLByAppendingPathComponent:kStateName] atomically:NO encoding:NSUTF8StringEncoding error:nil])
        [names addObject:kStateName];

    OAMemoryLog *memoryLog = OAMemoryLog.sharedInstance;
    [self copyTail:memoryLog.memoryLogURL to:folder maxLength:kMaxMemoryLogInReport names:names];
    [self copyTail:memoryLog.exitInfoURL to:folder maxLength:ULLONG_MAX names:names];
    [self copyTail:memoryLog.exitMetricsURL to:folder maxLength:ULLONG_MAX names:names];
    NSUInteger count = MIN(crashDiagnosticURLs.count, kMaxCrashDiagnosticsInReport);
    for (NSURL *url in [crashDiagnosticURLs subarrayWithRange:NSMakeRange(0, count)])
        [self copyTail:url to:folder maxLength:ULLONG_MAX names:names];

    QList<QString> files;
    for (NSString *name in names)
        files << QString::fromNSString([folder URLByAppendingPathComponent:name].path);
    bool ok = false;
    OsmAnd::ArchiveWriter archiveWriter;
    QByteArray archive = archiveWriter.createArchive(&ok, files, QString::fromNSString(folder.path), false);
    [fileManager removeItemAtURL:folder error:nil];
    return ok && !archive.isEmpty() ? [NSData dataWithBytes:archive.constData() length:archive.size()] : nil;
}

// copies at most the last maxLength bytes of the file
+ (void)copyTail:(NSURL *)source to:(NSURL *)folder maxLength:(unsigned long long)maxLength names:(NSMutableArray<NSString *> *)names
{
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingFromURL:source error:nil];
    if (!handle)
        return;
    NSData *data = nil;
    @try
    {
        unsigned long long length = [handle seekToEndOfFile];
        [handle seekToFileOffset:length > maxLength ? length - maxLength : 0];
        data = [handle readDataToEndOfFile];
    }
    @catch (NSException *e)
    {
        data = nil;
    }
    [handle closeFile];
    NSString *name = source.lastPathComponent;
    if (data.length > 0 && ![names containsObject:name] && [data writeToURL:[folder URLByAppendingPathComponent:name] atomically:NO])
        [names addObject:name];
}

+ (NSString *)buildState
{
    NSMutableString *sb = [NSMutableString stringWithString:@"# OsmAnd crash report state (counts and flags only, no personal data)\n"];
    @try
    {
        [self appendApp:sb];
        [self appendDevice:sb];
        [self appendMemory:sb];
        [self appendMaps:sb];
        [self appendTracks:sb];
        [self appendState:sb];
    }
    @catch (NSException *e)
    {
        [sb appendFormat:@"error: %@\n", e.name];
    }
    return sb;
}

+ (void)appendApp:(NSMutableString *)sb
{
    NSDictionary *info = NSBundle.mainBundle.infoDictionary;
    NSTimeInterval uptime = [self processUptime];
    [sb appendFormat:@"app: %@ (%@) bundle=%@ uptime=%.0fs\n", info[@"CFBundleShortVersionString"], info[@"CFBundleVersion"],
        NSBundle.mainBundle.bundleIdentifier, uptime];
}

// seconds since this process started, not since the device booted
+ (NSTimeInterval)processUptime
{
    struct kinfo_proc info;
    size_t size = sizeof(info);
    int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()};
    if (sysctl(mib, 4, &info, &size, NULL, 0) != 0 || size == 0)
        return 0;
    struct timeval start = info.kp_proc.p_starttime;
    return NSDate.date.timeIntervalSince1970 - (start.tv_sec + start.tv_usec / 1e6);
}

+ (void)appendDevice:(NSMutableString *)sb
{
    struct utsname system;
    uname(&system);
    NSProcessInfo *process = NSProcessInfo.processInfo;
    [sb appendFormat:@"device: %s ios=%@ ram=%@ cpus=%lu lowPower=%d thermal=%ld\n", system.machine,
        UIDevice.currentDevice.systemVersion, mbString(process.physicalMemory), (unsigned long) process.activeProcessorCount,
        process.isLowPowerModeEnabled, (long) process.thermalState];
}

+ (void)appendMemory:(NSMutableString *)sb
{
    task_vm_info_data_t vm = {};
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    if (task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&vm, &count) == KERN_SUCCESS)
    {
        [sb appendFormat:@"memory: footprint=%@ available=%@ resident=%@ compressed=%@ regions=%d", mbString(vm.phys_footprint),
            mbString(os_proc_available_memory()), mbString(vm.resident_size), mbString(vm.compressed), vm.region_count];
        if (count >= TASK_VM_INFO_REV3_COUNT)
            [sb appendFormat:@" peak=%@ graphics=%@", mbString((uint64_t) MAX(vm.ledger_phys_footprint_peak, 0)),
                mbString((uint64_t) MAX(vm.ledger_tag_graphics_footprint, 0))];
        [sb appendString:@"\n"];
    }
    malloc_statistics_t stats = {};
    malloc_zone_statistics(NULL, &stats);
    [sb appendFormat:@"malloc: allocated=%@ size=%@\n", mbString(stats.size_in_use), mbString(stats.size_allocated)];
}

+ (void)appendMaps:(NSMutableString *)sb
{
    const auto resourcesManager = OsmAndApp.instance.resourcesManager;
    if (!resourcesManager)
        return;
    int total = 0, standard = 0, road = 0, wiki = 0, srtm = 0, depth = 0, travel = 0, terrain = 0, weather = 0, other = 0;
    for (const auto& resource : resourcesManager->getLocalResources())
    {
        total++;
        switch (resource->type)
        {
            case OsmAnd::ResourcesManager::ResourceType::MapRegion: standard++; break;
            case OsmAnd::ResourcesManager::ResourceType::RoadMapRegion: road++; break;
            case OsmAnd::ResourcesManager::ResourceType::WikiMapRegion: wiki++; break;
            case OsmAnd::ResourcesManager::ResourceType::SrtmMapRegion: srtm++; break;
            case OsmAnd::ResourcesManager::ResourceType::DepthContourRegion:
            case OsmAnd::ResourcesManager::ResourceType::DepthMapRegion: depth++; break;
            case OsmAnd::ResourcesManager::ResourceType::Travel: travel++; break;
            case OsmAnd::ResourcesManager::ResourceType::HillshadeRegion:
            case OsmAnd::ResourcesManager::ResourceType::SlopeRegion:
            case OsmAnd::ResourcesManager::ResourceType::HeightmapRegionLegacy:
            case OsmAnd::ResourcesManager::ResourceType::GeoTiffRegion: terrain++; break;
            case OsmAnd::ResourcesManager::ResourceType::WeatherForecast: weather++; break;
            default: other++; break;
        }
    }
    [sb appendFormat:@"maps: resources=%d standard=%d road=%d wiki=%d srtm=%d depth=%d travel=%d terrain=%d weather=%d other=%d\n",
        total, standard, road, wiki, srtm, depth, travel, terrain, weather, other];
}

// counts only, never a file name; bounded depth so a deep import tree cannot stall the report
+ (void)appendTracks:(NSMutableString *)sb
{
    NSString *gpxPath = OsmAndApp.instance.gpxPath;
    NSUInteger files = 0;
    unsigned long long bytes = 0;
    NSDirectoryEnumerator<NSURL *> *enumerator = gpxPath ? [NSFileManager.defaultManager enumeratorAtURL:[NSURL fileURLWithPath:gpxPath]
        includingPropertiesForKeys:@[NSURLFileSizeKey, NSURLIsRegularFileKey] options:NSDirectoryEnumerationSkipsHiddenFiles errorHandler:nil] : nil;
    for (NSURL *url in enumerator)
    {
        if (enumerator.level > kMaxTracksDepth)
        {
            [enumerator skipDescendants];
            continue;
        }
        if (![url.pathExtension.lowercaseString isEqualToString:@"gpx"])
            continue;
        NSNumber *size = nil;
        [url getResourceValue:&size forKey:NSURLFileSizeKey error:nil];
        files++;
        bytes += size.unsignedLongLongValue;
    }
    [sb appendFormat:@"tracks: files=%lu size=%@\n", (unsigned long) files, mbString(bytes)];
    [sb appendFormat:@"tracks shown: files=%lu\n", (unsigned long) OASelectedGPXHelper.instance.activeGpx.count];
}

+ (void)appendState:(NSMutableString *)sb
{
    OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
    [sb appendFormat:@"state: navigation=%d route=%d profile=%@\n", [routingHelper isFollowingMode], [routingHelper isRouteCalculated],
        [self baseProfile:[OAAppSettings sharedManager].applicationMode.get]];
    NSMutableArray<NSString *> *plugins = [NSMutableArray array];
    for (OAPlugin *plugin in [OAPluginsHelper getEnabledPlugins])
    {
        NSString *pluginId = [plugin getId];
        if (pluginId)
            [plugins addObject:pluginId];
    }
    [sb appendFormat:@"plugins: %@\n", plugins.count > 0 ? [plugins componentsJoinedByString:@","] : @"-"];
}

// a custom profile can be named by the user, so only the built-in profile it derives from is reported
+ (NSString *)baseProfile:(OAApplicationMode *)mode
{
    if (!mode)
        return @"?";
    return mode.parent ? mode.parent.stringKey : mode.stringKey;
}

@end
