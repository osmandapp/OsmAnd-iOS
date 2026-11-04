//
//  OAGpxApproximator.m
//  OsmAnd Maps
//
//  Created by Paul on 12.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAGpxApproximator.h"
#import "OARouteProvider.h"
#import "OARoutingHelper.h"
#import "OARoutingHelper+cpp.h"
#import "OAApplicationMode.h"
#import "OALocationsHolder.h"
#import "OAResultMatcher.h"
#import "OAGpxRouteApproximation.h"
#import "OACppRouteCalculationProgress.h"
#import "OsmAndSharedWrapper.h"

#include <routePlannerFrontEnd.h>
#include <gpxRouteApproximation.h>

static BOOL OAIsValidRoutingEnvironment(OARoutingEnvironment *env)
{
	return env && env.router && env.ctx && env.ctx->config;
}

static BOOL OAHasValidProgress(const SHARED_PTR<GpxRouteApproximation>& gctx)
{
	return gctx != nullptr && gctx->ctx != nullptr && gctx->ctx->progress != nullptr;
}

@interface OAGpxApproximator ()

@property (nonatomic) NSThread *approximationTask;

@end

// One approximation, run after the one before it has finished. What it approximates - the C++
// planner or the OsmAndShared one - is the block it is given.
@interface OAApproximationTask : NSThread

@property (nonatomic) NSThread *previousTask;

- (instancetype)initWithApproximator:(OAGpxApproximator *)approximator run:(void (^)(void))run;

@end

@implementation OAApproximationTask
{
	__weak OAGpxApproximator *_approximator;
	void (^_run)(void);
}

- (instancetype)initWithApproximator:(OAGpxApproximator *)approximator run:(void (^)(void))run
{
	self = [super init];
	if (self)
	{
		self.qualityOfService = NSQualityOfServiceUtility;
		_approximator = approximator;
		_run = run;
	}
	return self;
}

- (void) main
{
	@synchronized (_approximator)
	{
		_approximator.approximationTask = self;
	}
	
	if (self.previousTask)
	{
		while (self.previousTask.executing)
		{
			[NSThread sleepForTimeInterval:.05];
		}
	}
	@synchronized (_approximator)
	{
		_approximator.approximationTask = self;
	}
	_run();
	@synchronized (_approximator)
	{
		_approximator.approximationTask = nil;
	}
}

@end

@implementation OAGpxApproximator
{
	OARoutingHelper *_routingHelper;

	OARoutingEnvironment *_env;
	vector<SHARED_PTR<GpxPoint>> _points;
	// the track points when the environment is an OsmAndShared one; only one of the two is ever filled
	NSArray<OASGpxPoint *> *_sharedPoints;
	// the progress of the approximation that is running, whichever planner runs it
	OASRouteCalculationProgress *_progress;
	CLLocation *_start;
	CLLocation *_end;
	
}

@synthesize mode = _mode;

- (instancetype) initWithLocationsHolder:(OALocationsHolder *)locationsHolder
{
	self = [super init];
	if (self) {
		_locationsHolder = locationsHolder;
		_routingHelper = OARoutingHelper.sharedInstance;
		_mode = OAApplicationMode.CAR;
		[self initEnvironment:_mode locationsHolder:locationsHolder];
	}
	return self;
}

- (instancetype) initWithApplicationMode:(OAApplicationMode *)mode pointApproximation:(double)pointApproximation locationsHolder:(OALocationsHolder *)locationsHolder
{
    self = [super init];
    if (self) {
        if (locationsHolder.size < 2)
            return nil;
        
        _locationsHolder = locationsHolder;
        _pointApproximation = pointApproximation;
        _routingHelper = OARoutingHelper.sharedInstance;
        _mode = mode;
        [self initEnvironment:mode locationsHolder:locationsHolder];
    }
    return self;
}

- (void) initEnvironment:(OAApplicationMode *)mode locationsHolder:(OALocationsHolder *)locationsHolder
{
    _start = [locationsHolder getLocation:0];
    _end = [locationsHolder getLocation:_locationsHolder.size - 1];
    [self prepareEnvironment:mode];
}

- (void) prepareEnvironment:(OAApplicationMode *)mode
{
	_env = [_routingHelper getRoutingEnvironment:mode start:_start end:_end];
}

// Whether the track is approximated by OsmAndShared rather than by the C++ planner: the setting
// behind which the shared planner sits is read once, when the environment is built.
- (BOOL) useShared
{
	return _env.sharedRouter != nil;
}

- (SHARED_PTR<GpxRouteApproximation>) getNewGpxApproximationContext:(OASRouteCalculationProgress *)progress
{
	if (!OAIsValidRoutingEnvironment(_env))
		return nullptr;

	const auto newContext = std::make_shared<GpxRouteApproximation>(_env.ctx.get());
	if (newContext->ctx == nullptr || newContext->ctx->config == nullptr)
		return nullptr;

	newContext->ctx->progress = std::make_shared<OACppRouteCalculationProgress>(progress);
	newContext->ctx->config->minPointApproximation = _pointApproximation;
	return newContext;
}

- (std::vector<SHARED_PTR<GpxPoint>>) getPoints
{
	if (_points.empty())
	{
		auto gctx = [self getNewGpxApproximationContext:[[OASRouteCalculationProgress alloc] init]];
		if (gctx == nullptr)
			return {};

		_points = [_routingHelper generateGpxPoints:_env gctx:gctx locationsHolder:_locationsHolder];
	}
	vector<SHARED_PTR<GpxPoint>> points(_points.size());
	for (int i = 0; i < _points.size(); i++)
		points[i] = make_shared<GpxPoint>(_points[i]);
	return points;
}

- (OASGpxRouteApproximation *) getNewSharedGpxApproximationContext:(OASRouteCalculationProgress *)progress
{
	if (!_env.sharedRouter || !_env.sharedCtx)
		return nil;

	OASGpxRouteApproximation *newContext = [[OASGpxRouteApproximation alloc] initWithCtx:_env.sharedCtx];
	newContext.ctx.calculationProgress = progress;
	newContext.ctx.config.minPointApproximation = _pointApproximation;
	return newContext;
}

- (NSArray<OASGpxPoint *> *) getSharedPoints
{
	if (!_sharedPoints)
	{
		OASGpxRouteApproximation *gctx = [self getNewSharedGpxApproximationContext:[[OASRouteCalculationProgress alloc] init]];
		if (!gctx)
			return @[];

		_sharedPoints = [_routingHelper generateSharedGpxPoints:_env gctx:gctx locationsHolder:_locationsHolder];
	}
	// the points themselves are generated once; every approximation gets its own copies of them to
	// attach roads to, as the C++ one does
	NSMutableArray<OASGpxPoint *> *points = [NSMutableArray arrayWithCapacity:_sharedPoints.count];
	for (OASGpxPoint *point in _sharedPoints)
		[points addObject:[[OASGpxPoint alloc] initWithPoint:point]];
	return points;
}

- (void)setMode:(OAApplicationMode *)mode
{
	if (_mode != mode)
	{
		_mode = mode;
		[self prepareEnvironment:mode];
	}
}

- (BOOL) isCancelled
{
	return _progress.isCancelled;
}

- (void) cancelApproximation
{
	_progress.isCancelled = YES;
}

- (void)calculateGpxApproximation:(OAResultMatcher<OAGpxRouteApproximation *> *)resultMatcher
            useExternalTimestamps:(BOOL)useExternalTimestamps
{
	[self cancelApproximation];
	if ([self useShared])
	{
		[self calculateSharedGpxApproximation:resultMatcher useExternalTimestamps:useExternalTimestamps];
		return;
	}

	OASRouteCalculationProgress *progress = [[OASRouteCalculationProgress alloc] init];
	auto gctx = [self getNewGpxApproximationContext:progress];
	if (gctx == nullptr)
	{
		_progress = nil;
		[resultMatcher publish:nil];
		return;
	}

	std::vector<SHARED_PTR<GpxPoint>> points = [self getPoints];
	if (points.empty())
	{
		_progress = nil;
		[resultMatcher publish:nil];
		return;
	}

	_progress = progress;
	[self startProgress];
	[self updateProgress:progress];
	OARoutingEnvironment *env = _env;
	OALocationsHolder *locationsHolder = _locationsHolder;
	OARoutingHelper *routingHelper = _routingHelper;
	OAApproximationTask *task = [[OAApproximationTask alloc] initWithApproximator:self run:^{
		if (!OAIsValidRoutingEnvironment(env) || !OAHasValidProgress(gctx) || points.empty())
		{
			[resultMatcher publish:nil];
			return;
		}
		// a block captures a C++ value as const, and the search takes its points by reference
		std::vector<SHARED_PTR<GpxPoint>> gpxPoints = points;
		[routingHelper calculateGpxApproximation:env
											gctx:gctx
										  points:gpxPoints
								 locationsHolder:locationsHolder
						   useExternalTimestamps:useExternalTimestamps
								   resultMatcher:resultMatcher];
	}];
	task.previousTask = _approximationTask;
	[task start];
}

- (void)calculateSharedGpxApproximation:(OAResultMatcher<OAGpxRouteApproximation *> *)resultMatcher
                  useExternalTimestamps:(BOOL)useExternalTimestamps
{
	OASRouteCalculationProgress *progress = [[OASRouteCalculationProgress alloc] init];
	OASGpxRouteApproximation *gctx = [self getNewSharedGpxApproximationContext:progress];
	NSArray<OASGpxPoint *> *points = gctx ? [self getSharedPoints] : nil;
	if (!gctx || points.count == 0)
	{
		_progress = nil;
		[resultMatcher publish:nil];
		return;
	}

	_progress = progress;
	[self startProgress];
	[self updateProgress:progress];
	OARoutingEnvironment *env = _env;
	OARoutingHelper *routingHelper = _routingHelper;
	OAApproximationTask *task = [[OAApproximationTask alloc] initWithApproximator:self run:^{
		[routingHelper calculateSharedGpxApproximation:env
												  gctx:gctx
												points:points
								 useExternalTimestamps:useExternalTimestamps
										 resultMatcher:resultMatcher];
	}];
	task.previousTask = _approximationTask;
	[task start];
}

- (void)calculateGpxApproximationSync:(OAResultMatcher<OAGpxRouteApproximation *> *)resultMatcher
                useExternalTimestamps:(BOOL)useExternalTimestamps
{
    if ([self useShared])
    {
        OASGpxRouteApproximation *gctx = [self getNewSharedGpxApproximationContext:[[OASRouteCalculationProgress alloc] init]];
        NSArray<OASGpxPoint *> *points = gctx ? [self getSharedPoints] : nil;
        if (!gctx || points.count == 0)
        {
            [resultMatcher publish:nil];
            return;
        }

        [_routingHelper calculateSharedGpxApproximation:_env
                                                   gctx:gctx
                                                 points:points
                                  useExternalTimestamps:useExternalTimestamps
                                          resultMatcher:resultMatcher];
        return;
    }

    @try {
        auto gctx = [self getNewGpxApproximationContext:[[OASRouteCalculationProgress alloc] init]];
        if (gctx == nullptr)
        {
            [resultMatcher publish:nil];
            return;
        }

        std::vector<SHARED_PTR<GpxPoint>> points = [self getPoints];
        if (points.empty())
        {
            [resultMatcher publish:nil];
            return;
        }

        [_routingHelper calculateGpxApproximation:_env
                                             gctx:gctx
                                           points:points
                                  locationsHolder:_locationsHolder
                             useExternalTimestamps:useExternalTimestamps
                                    resultMatcher:resultMatcher];
    } @catch (NSException *exception) {
        [resultMatcher publish:nil];
        NSLog(@"Error: %@", exception.reason);
    }
}

- (void) startProgress
{
    // UI Thread +
    if ([self.progressDelegate respondsToSelector:@selector(start:)])
        [self.progressDelegate start:self];
}

- (void) finishProgress
{
    // + UI Thread
    if ([self.progressDelegate respondsToSelector:@selector(finish:)])
        [self.progressDelegate finish:self];
}

- (void) updateProgress:(OASRouteCalculationProgress *)progress
{
	if (!progress || self.progressDelegate == nil)
		return;

	double delayInSeconds = 0.3;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		// + UI Thread
		if (!_approximationTask && _progress == progress)
			[self finishProgress];

		if (_approximationTask != nil && !progress.isCancelled)
		{
			float pr = [progress getApproximationProgress];
			if ([self.progressDelegate respondsToSelector:@selector(updateProgress:progress:)])
				[self.progressDelegate updateProgress:self progress:(int)pr];
			if (_progress == progress)
				[self updateProgress:progress];
		}
	});
}

@end
