//
//  OAMemoryLog.mm
//  OsmAnd Maps
//
//  Copyright © 2026 OsmAnd. All rights reserved.
//

#import "OAMemoryLog.h"
#import "OsmAndApp.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OARoutingHelper.h"
#import "OARouteCalculationResult.h"
#import "OASavingTrackHelper.h"
#import "OASelectedGPXHelper.h"
#import "OADestinationsHelper.h"
#import "OADownloadsManager.h"
#import "SceneDelegate.h"
#import "OAUtilities.h"
#import <UIKit/UIKit.h>
#import <mach/mach.h>
#import <malloc/malloc.h>
#import <os/proc.h>
#import <os/lock.h>
#import <sys/resource.h>
#import <sys/sysctl.h>
#import <atomic>
#import <mutex>

#include <OsmAndCore/Map/IMapRenderer.h>

static NSString * const kMemoryLogName = @"memory_log.txt";
static NSString * const kExitInfoName = @"exit_info.txt";
static NSString * const kExitMetricsName = @"exit_metrics.json";
static NSString * const kProcessStateName = @"process_state.txt";

// the timer ticks at the short interval, the sample itself decides whether it is due
static const NSTimeInterval kSampleInterval = 30;
// once the process nears its limit the interesting part is minutes long, not half an hour
static const NSTimeInterval kBusySampleInterval = 5;
static const double kBusyFootprintRatio = 0.7;
// a process that grew this much between two samples is worth watching closely
static const uint64_t kBusyGrowthBytes = 100 * 1024 * 1024;
// a sample is a few hundred bytes, so this holds days of them
static const unsigned long long kMaxFileSize = 4 * 1024 * 1024;
// malloc_zone_statistics walks every zone under its lock; stop if a device makes that expensive
static const double kMallocBudgetMs = 200;
// the main thread answering later than this is written down, a watchdog kill starts at seconds
static const double kMainLagReportMs = 100;
static const NSUInteger kMaxExitRecords = 30;

static double monotonicSeconds()
{
    // counts while the device sleeps, like elapsedRealtime on Android
    return clock_gettime_nsec_np(CLOCK_MONOTONIC) / 1e9;
}

static uint64_t mb(uint64_t bytes)
{
    return bytes / (1024 * 1024);
}

static long bootTimeSeconds()
{
    struct timeval boot = {0, 0};
    size_t size = sizeof(boot);
    int mib[2] = {CTL_KERN, KERN_BOOTTIME};
    if (sysctl(mib, 2, &boot, &size, NULL, 0) != 0)
        return 0;
    return boot.tv_sec;
}

static NSString *appVersion()
{
    NSDictionary *info = NSBundle.mainBundle.infoDictionary;
    return [NSString stringWithFormat:@"%@(%@)", info[@"CFBundleShortVersionString"] ?: @"?", info[@"CFBundleVersion"] ?: @"?"];
}

@implementation OAMemoryLog
{
    dispatch_queue_t _queue;
    dispatch_source_t _timer;
    dispatch_source_t _pressureSource;
    NSURL *_directoryURL;
    NSURL *_processStateURL;
    NSString *_uncleanExitIdentifier;

    // sampler queue only
    double _lastSampleTime;
    uint64_t _lastFootprint;
    uint64_t _previousCpuMs;
    BOOL _sessionStarted;
    BOOL _mallocAffordable;
    double _pingTime;
    unsigned long _pressureLevel;

    // written from other threads, the sample only reads and resets them
    std::atomic<int> _routeCalculations;
    std::atomic<int> _searches;
    std::atomic<int> _memoryWarnings;
    std::atomic<int> _pressureCount;
    std::atomic<double> _pongTime;
    std::atomic<bool> _inBackground;
    // with scenes the application state reads "background" in didFinishLaunching even for a launch
    // onto the screen, so a process is only known to be on screen once it became active
    std::atomic<bool> _becameActive;
    // the helpers below are singletons created on first use, and creating the routing helper
    // before the resources manager exists crashes, so they are read only once the map UI is up
    std::atomic<bool> _appReady;

    // the renderer is released by the main thread; the sampler keeps only a weak reference
    std::mutex _rendererLock;
    std::weak_ptr<OsmAnd::IMapRenderer> _renderer;

    // the process state file is written from the main thread on lifecycle changes and from the
    // sampler, so its content is guarded
    os_unfair_lock _stateLock;
    NSString *_lastSample;
    NSTimeInterval _startedAt;
    BOOL _cleanExit;
}

+ (OAMemoryLog *)sharedInstance
{
    static OAMemoryLog *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[OAMemoryLog alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _queue = dispatch_queue_create("net.osmand.memory-log", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_UTILITY, 0));
        _mallocAffordable = YES;
        _stateLock = OS_UNFAIR_LOCK_INIT;
        _startedAt = NSDate.date.timeIntervalSince1970;
        NSURL *support = [NSFileManager.defaultManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask].firstObject;
        _directoryURL = [support URLByAppendingPathComponent:@"CrashDiagnostics" isDirectory:YES];
        _memoryLogURL = [_directoryURL URLByAppendingPathComponent:kMemoryLogName];
        _exitInfoURL = [_directoryURL URLByAppendingPathComponent:kExitInfoName];
        _exitMetricsURL = [_directoryURL URLByAppendingPathComponent:kExitMetricsName];
        _processStateURL = [_directoryURL URLByAppendingPathComponent:kProcessStateName];
    }
    return self;
}

- (NSString *)uncleanExitIdentifier
{
    return _uncleanExitIdentifier;
}

- (void)start
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self prepareDirectory];
        [self recordPreviousExit];
        [self writeProcessState];
        [self observeLifecycle];
        [self observeMemoryPressure];

        _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, _queue);
        dispatch_source_set_timer(_timer, dispatch_time(DISPATCH_TIME_NOW, 0), (uint64_t)(kBusySampleInterval * NSEC_PER_SEC), NSEC_PER_SEC);
        __weak OAMemoryLog *weakSelf = self;
        dispatch_source_set_event_handler(_timer, ^{
            [weakSelf sampleIfDue];
        });
        dispatch_resume(_timer);
    });
}

- (void)onRouteCalculated
{
    _routeCalculations++;
}

- (void)onSearchRun
{
    _searches++;
}

#pragma mark - Lifecycle

- (void)observeLifecycle
{
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self selector:@selector(onDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(onDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [center addObserver:self selector:@selector(onWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    [center addObserver:self selector:@selector(onMemoryWarning) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    [center addObserver:self selector:@selector(onMainApplicationUIReady) name:OAMainApplicationUIReadyNotification object:nil];
}

- (void)onMainApplicationUIReady
{
    _appReady = true;
    [self captureRenderer];
}

- (void)onDidBecomeActive
{
    _inBackground = false;
    _becameActive = true;
    [self captureRenderer];
    [self writeProcessState];
}

// written right away: the process may be suspended and then killed without running again
- (void)onDidEnterBackground
{
    _inBackground = true;
    _becameActive = true;
    [self writeProcessState];
}

- (void)onWillTerminate
{
    os_unfair_lock_lock(&_stateLock);
    _cleanExit = YES;
    os_unfair_lock_unlock(&_stateLock);
    [self writeProcessState];
}

- (void)onMemoryWarning
{
    _memoryWarnings++;
}

- (void)observeMemoryPressure
{
    _pressureSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_MEMORYPRESSURE, 0, DISPATCH_MEMORYPRESSURE_WARN | DISPATCH_MEMORYPRESSURE_CRITICAL, _queue);
    __weak OAMemoryLog *weakSelf = self;
    dispatch_source_set_event_handler(_pressureSource, ^{
        OAMemoryLog *strongSelf = weakSelf;
        if (!strongSelf)
            return;
        unsigned long level = dispatch_source_get_data(strongSelf->_pressureSource);
        strongSelf->_pressureLevel = MAX(strongSelf->_pressureLevel, level);
        strongSelf->_pressureCount++;
    });
    dispatch_resume(_pressureSource);
}

// main thread only: the view hierarchy is not touched from the sampler
- (void)captureRenderer
{
    OAMapRendererView *mapView = OARootViewController.instance.mapPanel.mapViewController.mapView;
    if (!mapView)
        return;
    std::lock_guard<std::mutex> lock(_rendererLock);
    _renderer = mapView.renderer;
}

#pragma mark - Sampling

- (void)sampleIfDue
{
    double time = monotonicSeconds();
    task_vm_info_data_t vm = {};
    mach_msg_type_number_t vmCount = TASK_VM_INFO_COUNT;
    if (task_info(mach_task_self(), TASK_VM_INFO, (task_info_t)&vm, &vmCount) != KERN_SUCCESS)
        return;
    uint64_t footprint = vm.phys_footprint;
    uint64_t available = os_proc_available_memory();
    uint64_t limit = available > 0 ? footprint + available : 0;
    BOOL busy = (limit > 0 && footprint > limit * kBusyFootprintRatio)
        || (_lastFootprint > 0 && footprint > _lastFootprint + kBusyGrowthBytes);
    NSTimeInterval interval = busy ? kBusySampleInterval : kSampleInterval;
    // the timer does not fire exactly on time, half a second either way is the same tick
    if (_lastSampleTime > 0 && time - _lastSampleTime < interval - 0.5)
        return;
    _lastSampleTime = time;
    _lastFootprint = footprint;

    @autoreleasepool
    {
        @try
        {
            NSMutableString *text = [NSMutableString string];
            if (!_sessionStarted)
            {
                _sessionStarted = YES;
                [text appendFormat:@"--- start %@ ios=%@ device=%@ ram=%llu\n", appVersion(),
                    UIDevice.currentDevice.systemVersion, [UIDevice machine] ?: @"?", mb(NSProcessInfo.processInfo.physicalMemory)];
            }
            NSString *sample = [self buildSample:time vm:vm vmCount:vmCount limit:limit];
            [text appendString:sample];
            [text appendString:@"\n"];
            [self append:text];

            os_unfair_lock_lock(&_stateLock);
            _lastSample = sample;
            os_unfair_lock_unlock(&_stateLock);
            [self writeProcessState];
        }
        @catch (NSException *e)
        {
            NSLog(@"[MemoryLog] sample failed: %@", e.reason);
        }
    }
}

- (NSString *)buildSample:(double)time vm:(const task_vm_info_data_t &)vm vmCount:(mach_msg_type_number_t)vmCount limit:(uint64_t)limit
{
    NSMutableString *sb = [NSMutableString string];
    [sb appendFormat:@"t=%lld", (long long)time];
    // the footprint is what the system compares with the limit before it kills the process
    if (limit > 0)
        [sb appendFormat:@" fp=%llu/%llu", mb(vm.phys_footprint), mb(limit)];
    else
        [sb appendFormat:@" fp=%llu", mb(vm.phys_footprint)];
    if (vmCount >= TASK_VM_INFO_REV3_COUNT)
        [sb appendFormat:@" fpeak=%llu", mb((uint64_t) MAX(vm.ledger_phys_footprint_peak, 0))];
    [sb appendFormat:@" rss=%llu cmp=%llu", mb(vm.resident_size), mb(vm.compressed)];
    // GPU textures and buffers are counted in the footprint but in no heap
    if (vmCount >= TASK_VM_INFO_REV3_COUNT)
        [sb appendFormat:@" gfx=%llu", mb((uint64_t) MAX(vm.ledger_tag_graphics_footprint, 0))];
    [sb appendFormat:@" vma=%d", vm.region_count];
    [self appendMalloc:sb];
    [self appendThreadsAndCpu:sb];
    [self appendMainLag:sb time:time];
    NSString *gpu = [self gpuMemory];
    if (gpu.length > 0)
        [sb appendFormat:@" gpu=%@", gpu];
    NSString *held = [self buildHeld];
    if (held.length > 0)
        [sb appendFormat:@" held=%@", held];

    int warnings = _memoryWarnings.exchange(0);
    if (warnings > 0)
        [sb appendFormat:@" memwarn=%d", warnings];
    int pressures = _pressureCount.exchange(0);
    if (pressures > 0)
        [sb appendFormat:@" press=%@x%d", (_pressureLevel & DISPATCH_MEMORYPRESSURE_CRITICAL) ? @"critical" : @"warn", pressures];
    _pressureLevel = 0;

    NSProcessInfoThermalState thermal = NSProcessInfo.processInfo.thermalState;
    if (thermal != NSProcessInfoThermalStateNominal)
        [sb appendFormat:@" therm=%@", thermal == NSProcessInfoThermalStateFair ? @"fair" : thermal == NSProcessInfoThermalStateSerious ? @"serious" : @"critical"];
    if (_inBackground || !_becameActive)
        [sb appendString:@" bg=1"];
    NSString *busy = [self busyWith];
    if (busy.length > 0)
        [sb appendFormat:@" busy=%@", busy];
    int calculations = _routeCalculations.exchange(0);
    if (calculations > 0)
        [sb appendFormat:@" rcalc=%d", calculations];
    // route calculations and searches both load map data in bursts
    int searches = _searches.exchange(0);
    if (searches > 0)
        [sb appendFormat:@" srch=%d", searches];
    return sb;
}

// allocated/size: size minus allocated is what the allocator holds and does not give back
- (void)appendMalloc:(NSMutableString *)sb
{
    if (!_mallocAffordable)
        return;
    double start = monotonicSeconds();
    malloc_statistics_t stats = {};
    malloc_zone_statistics(NULL, &stats);
    double spentMs = (monotonicSeconds() - start) * 1000;
    [sb appendFormat:@" nat=%llu/%llu", mb(stats.size_in_use), mb(stats.size_allocated)];
    if (spentMs > kMallocBudgetMs)
    {
        // a field that stops appearing without saying so looks like one that was never built
        _mallocAffordable = NO;
        [sb appendFormat:@" mallocOff=%d", (int) spentMs];
    }
}

- (void)appendThreadsAndCpu:(NSMutableString *)sb
{
    thread_act_array_t threads = NULL;
    mach_msg_type_number_t threadCount = 0;
    if (task_threads(mach_task_self(), &threads, &threadCount) == KERN_SUCCESS)
    {
        for (mach_msg_type_number_t i = 0; i < threadCount; i++)
            mach_port_deallocate(mach_task_self(), threads[i]);
        vm_deallocate(mach_task_self(), (vm_address_t) threads, threadCount * sizeof(thread_act_t));
        [sb appendFormat:@" thr=%u", threadCount];
    }
    struct rusage usage;
    if (getrusage(RUSAGE_SELF, &usage) == 0)
    {
        uint64_t cpuMs = (uint64_t) usage.ru_utime.tv_sec * 1000 + usage.ru_utime.tv_usec / 1000
            + (uint64_t) usage.ru_stime.tv_sec * 1000 + usage.ru_stime.tv_usec / 1000;
        if (_previousCpuMs > 0 && cpuMs >= _previousCpuMs)
            [sb appendFormat:@" cpums=%llu", cpuMs - _previousCpuMs];
        _previousCpuMs = cpuMs;
    }
}

// the main thread is pinged once per sample: a ping still unanswered at the next sample is a
// hang in progress, the kind the system watchdog ends without a crash report of its own
- (void)appendMainLag:(NSMutableString *)sb time:(double)time
{
    double pong = _pongTime.load();
    double lagMs = 0;
    BOOL pending = _pingTime > 0 && pong < _pingTime;
    if (pending)
        lagMs = (time - _pingTime) * 1000;
    else if (_pingTime > 0)
        lagMs = (pong - _pingTime) * 1000;
    if (lagMs >= kMainLagReportMs)
        [sb appendFormat:@" mainms=%d%@", (int) lagMs, pending ? @"+" : @""];
    if (!pending)
    {
        _pingTime = time;
        dispatch_async(dispatch_get_main_queue(), ^{
            _pongTime = monotonicSeconds();
        });
    }
}

// MB/count of what the map renderer keeps in GPU memory by type, e.g. "tex:120/340,vbo:10/180"
- (NSString *)gpuMemory
{
    std::shared_ptr<OsmAnd::IMapRenderer> renderer;
    {
        std::lock_guard<std::mutex> lock(_rendererLock);
        renderer = _renderer.lock();
    }
    if (!renderer)
        return nil;
    return renderer->getGpuMemoryStats().toNSString();
}

// what a few subsystems hold right now, in objects rather than bytes: counting what a
// collection already knows costs nothing. Each read is guarded on its own, a subsystem that is
// not up yet must not cost the whole sample
- (NSString *)buildHeld
{
    if (!_appReady)
        return nil;
    NSMutableArray<NSString *> *held = [NSMutableArray array];
    void (^add)(NSString *, NSUInteger) = ^(NSString *name, NSUInteger value) {
        if (value > 0)
            [held addObject:[NSString stringWithFormat:@"%@:%lu", name, (unsigned long) value]];
    };
    @try { add(@"gpx", OASelectedGPXHelper.instance.activeGpx.count); } @catch (NSException *e) {}
    @try { add(@"rec", (NSUInteger) MAX(OASavingTrackHelper.sharedInstance.points, 0)); } @catch (NSException *e) {}
    @try { add(@"rtloc", [[OARoutingHelper sharedInstance] getRoute].getImmutableAllLocations.count); } @catch (NSException *e) {}
    @try { add(@"marker", OADestinationsHelper.instance.sortedDestinations.count); } @catch (NSException *e) {}
    @try { add(@"dl", OsmAndApp.instance.downloadsManager.keysOfDownloadTasks.count); } @catch (NSException *e) {}
    return [held componentsJoinedByString:@","];
}

// what the app was doing, so that a spike can be told apart from a leak: a route calculation
// allocates a lot on purpose
- (NSString *)busyWith
{
    if (!_appReady)
        return nil;
    NSMutableArray<NSString *> *busy = [NSMutableArray array];
    @try
    {
        OARoutingHelper *routingHelper = [OARoutingHelper sharedInstance];
        if ([routingHelper isRouteBeingCalculated])
            [busy addObject:@"routing"];
        if ([routingHelper isFollowingMode])
            [busy addObject:@"navigation"];
        if (OsmAndApp.instance.downloadsManager.keysOfDownloadTasks.count > 0)
            [busy addObject:@"download"];
    }
    @catch (NSException *e)
    {
    }
    return [busy componentsJoinedByString:@","];
}

#pragma mark - Files

- (void)prepareDirectory
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSDictionary *attributes = @{ NSFileProtectionKey: NSFileProtectionCompleteUntilFirstUserAuthentication };
    [fileManager createDirectoryAtURL:_directoryURL withIntermediateDirectories:YES attributes:attributes error:nil];
    [fileManager setAttributes:attributes ofItemAtPath:_directoryURL.path error:nil];
    [_directoryURL setResourceValue:@YES forKey:NSURLIsExcludedFromBackupKey error:nil];
}

// keeps the newest kMaxFileSize bytes, the older samples are dropped
- (void)append:(NSString *)text
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    NSString *path = _memoryLogURL.path;
    if (![fileManager fileExistsAtPath:path])
        [fileManager createFileAtPath:path contents:nil attributes:@{ NSFileProtectionKey: NSFileProtectionCompleteUntilFirstUserAuthentication }];
    NSFileHandle *handle = [NSFileHandle fileHandleForUpdatingAtPath:path];
    if (!handle)
        return;
    @try
    {
        unsigned long long length = [handle seekToEndOfFile];
        if (length > kMaxFileSize)
        {
            // move the newer half to the start, beginning at a line so the first sample kept is whole
            [handle seekToFileOffset:length - kMaxFileSize / 2];
            NSData *tail = [handle readDataToEndOfFile];
            NSRange newline = [tail rangeOfData:[NSData dataWithBytes:"\n" length:1] options:0 range:NSMakeRange(0, tail.length)];
            if (newline.location != NSNotFound)
                tail = [tail subdataWithRange:NSMakeRange(newline.location + 1, tail.length - newline.location - 1)];
            [handle seekToFileOffset:0];
            [handle writeData:tail];
            [handle truncateFileAtOffset:tail.length];
        }
        [handle writeData:[text dataUsingEncoding:NSUTF8StringEncoding]];
    }
    @catch (NSException *e)
    {
        NSLog(@"[MemoryLog] write failed: %@", e.reason);
    }
    [handle closeFile];
}

// the state of this process, read back by the next one to tell how this one ended
- (void)writeProcessState
{
    os_unfair_lock_lock(&_stateLock);
    NSString *state = [NSString stringWithFormat:@"pid=%d\nboot=%ld\nversion=%@\nstarted=%.0f\nupdated=%.0f\nstate=%@\nclean=%d\nlast=%@\n",
        getpid(), bootTimeSeconds(), appVersion(), _startedAt, NSDate.date.timeIntervalSince1970,
        !_becameActive ? @"launch" : _inBackground ? @"bg" : @"fg", _cleanExit ? 1 : 0, _lastSample ?: @""];
    [[state dataUsingEncoding:NSUTF8StringEncoding] writeToURL:_processStateURL
        options:NSDataWritingAtomic | NSDataWritingFileProtectionCompleteUntilFirstUserAuthentication error:nil];
    os_unfair_lock_unlock(&_stateLock);
}

- (NSDictionary<NSString *, NSString *> *)readProcessState
{
    NSString *text = [NSString stringWithContentsOfURL:_processStateURL encoding:NSUTF8StringEncoding error:nil];
    if (text.length == 0)
        return nil;
    NSMutableDictionary<NSString *, NSString *> *values = [NSMutableDictionary dictionary];
    for (NSString *line in [text componentsSeparatedByString:@"\n"])
    {
        NSRange eq = [line rangeOfString:@"="];
        if (eq.location != NSNotFound)
            values[[line substringToIndex:eq.location]] = [line substringFromIndex:eq.location + 1];
    }
    return values;
}

/**
 * iOS gives no exit reason to the next process, and a process killed for its memory leaves no
 * crash report at all. The state file written while the previous process ran says whether it was
 * on screen and whether it said goodbye: on screen and no goodbye on the same boot and version is
 * a crash, a watchdog kill or a memory kill. A kill in the background is written down too, but it
 * is how iOS reclaims memory from suspended apps and says little by itself.
 */
- (void)recordPreviousExit
{
    NSDictionary<NSString *, NSString *> *previous = [self readProcessState];
    if (!previous || previous[@"clean"].intValue == 1 || previous[@"pid"].intValue == getpid())
        return;
    // a reboot or an update ends a process without any fault of it
    if (previous[@"boot"].longLongValue != bootTimeSeconds() || ![previous[@"version"] isEqualToString:appVersion()])
        return;

    NSString *state = previous[@"state"];
    BOOL foreground = [state isEqualToString:@"fg"];
    NSString *ended = foreground ? @"foreground-unclean" : [state isEqualToString:@"launch"] ? @"during-launch" : @"background";
    NSTimeInterval updated = previous[@"updated"].doubleValue;
    NSTimeInterval started = previous[@"started"].doubleValue;
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
    NSString *record = [NSString stringWithFormat:@"%@ ended=%@ version=%@ ran=%.0fs last: %@",
        [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:updated]],
        ended, previous[@"version"],
        MAX(updated - started, 0), previous[@"last"] ?: @""];

    NSString *existing = [NSString stringWithContentsOfURL:_exitInfoURL encoding:NSUTF8StringEncoding error:nil] ?: @"";
    NSMutableArray<NSString *> *lines = [NSMutableArray array];
    for (NSString *line in [existing componentsSeparatedByString:@"\n"])
    {
        if (line.length > 0)
            [lines addObject:line];
    }
    [lines addObject:record];
    if (lines.count > kMaxExitRecords)
        [lines removeObjectsInRange:NSMakeRange(0, lines.count - kMaxExitRecords)];
    [[[lines componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"] writeToURL:_exitInfoURL atomically:YES encoding:NSUTF8StringEncoding error:nil];

    if (foreground)
        _uncleanExitIdentifier = [NSString stringWithFormat:@"exit-%.0f", updated];
}

@end
