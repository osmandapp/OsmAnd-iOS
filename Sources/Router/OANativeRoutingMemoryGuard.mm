//
//  OANativeRoutingMemoryGuard.mm
//  OsmAnd Maps
//
//  OsmAnd/src/net/osmand/plus/routing/NativeRoutingMemoryGuard.java
//  git revision 1026318c413e7baea7b2c3d7d858d96ef8e59366

#import "OANativeRoutingMemoryGuard.h"
#import "OARouteCalculationParams.h"

#include <atomic>
#include <mach/mach.h>
#include <os/proc.h>

static const uint64_t kMB = 1 << 20;
static const uint64_t kReservedMemory = 300 * kMB; // left before the process memory limit
static const NSTimeInterval kCheckInterval = 0.2;

@implementation OANativeRoutingMemoryGuard
{
    OARouteCalculationParams *_params;
    std::shared_ptr<RouteCalculationProgress> _progress;
    dispatch_semaphore_t _stopSignal;
    dispatch_semaphore_t _finished;
    std::atomic<bool> _exceeded;
    BOOL _stopped;
}

- (instancetype) initWithParams:(OARouteCalculationParams *)params
{
    self = [super init];
    if (self)
    {
        _params = params;
        _progress = params.calculationProgress;
        _stopSignal = dispatch_semaphore_create(0);
        _finished = dispatch_semaphore_create(0);
        _exceeded = false;
        _stopped = _progress == nullptr;
    }
    return self;
}

+ (instancetype) start:(OARouteCalculationParams *)params
{
    OANativeRoutingMemoryGuard *guard = [[self alloc] initWithParams:params];
    if (!guard->_stopped)
    {
        NSThread *thread = [[NSThread alloc] initWithBlock:^{
            [guard watch];
        }];
        thread.name = @"RoutingMemoryGuard";
        [thread start];
    }
    return guard;
}

+ (uint64_t) footprint
{
    task_vm_info_data_t vm;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    if (task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vm, &count) != KERN_SUCCESS)
        return 0;
    return vm.phys_footprint;
}

- (void) watch
{
    uint64_t peakFootprint = 0;
    while (!_progress->isCancelled())
    {
        uint64_t footprint = [self.class footprint];
        peakFootprint = MAX(peakFootprint, footprint);
        // 0 when the process has no memory limit
        size_t available = os_proc_available_memory();
        if (available > 0 && available < kReservedMemory)
        {
            _exceeded = true;
            _params.memoryLimitExceeded = YES;
            _progress->cancelled = true;
            NSLog(@"Route calculation stopped: footprint %llu MB, %zu MB left before the limit", footprint / kMB, available / kMB);
            break;
        }
        if (dispatch_semaphore_wait(_stopSignal, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kCheckInterval * NSEC_PER_SEC))) == 0)
            break;
    }
    NSLog(@"Route calculation footprint peak %llu MB", peakFootprint / kMB);
    dispatch_semaphore_signal(_finished);
}

- (BOOL) isExceeded
{
    return _exceeded;
}

- (BOOL) stop
{
    if (!_stopped)
    {
        _stopped = YES;
        dispatch_semaphore_signal(_stopSignal);
        dispatch_semaphore_wait(_finished, DISPATCH_TIME_FOREVER);
    }
    return _exceeded;
}

@end
