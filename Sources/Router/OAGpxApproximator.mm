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
	std::shared_ptr<GpxRouteApproximation> _gctx;
	vector<SHARED_PTR<GpxPoint>> _points;
	// the same two when the environment is an OsmAndShared one; only one of the two pairs is ever filled
	OASGpxRouteApproximation *_sharedGctx;
	NSArray<OASGpxPoint *> *_sharedPoints;
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

- (SHARED_PTR<GpxRouteApproximation>) getNewGpxApproximationContext
{
	if (!OAIsValidRoutingEnvironment(_env))
		return nullptr;

	const auto newContext = std::make_shared<GpxRouteApproximation>(_env.ctx.get());
	if (newContext->ctx == nullptr || newContext->ctx->config == nullptr)
		return nullptr;

	newContext->ctx->progress = std::make_shared<RouteCalculationProgress>();
	newContext->ctx->config->minPointApproximation = _pointApproximation;
	return newContext;
}

- (std::vector<SHARED_PTR<GpxPoint>>) getPoints
{
	if (_points.empty())
	{
		auto gctx = [self getNewGpxApproximationContext];
		if (gctx == nullptr)
			return {};

		_points = [_routingHelper generateGpxPoints:_env gctx:gctx locationsHolder:_locationsHolder];
	}
	vector<SHARED_PTR<GpxPoint>> points(_points.size());
	for (int i = 0; i < _points.size(); i++)
		points[i] = make_shared<GpxPoint>(_points[i]);
	return points;
}

- (OASGpxRouteApproximation *) getNewSharedGpxApproximationContext
{
	if (!_env.sharedRouter || !_env.sharedCtx)
		return nil;

	OASGpxRouteApproximation *newContext = [[OASGpxRouteApproximation alloc] initWithCtx:_env.sharedCtx];
	newContext.ctx.calculationProgress = [[OASRouteCalculationProgress alloc] init];
	newContext.ctx.config.minPointApproximation = _pointApproximation;
	return newContext;
}

- (NSArray<OASGpxPoint *> *) getSharedPoints
{
	if (!_sharedPoints)
	{
		OASGpxRouteApproximation *gctx = [self getNewSharedGpxApproximationContext];
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
	if (_sharedGctx)
		return _sharedGctx.ctx.calculationProgress.isCancelled;

	return OAHasValidProgress(_gctx) && _gctx->ctx->progress->isCancelled();
}

- (void) cancelApproximation
{
	if (_sharedGctx)
		_sharedGctx.ctx.calculationProgress.isCancelled = YES;
	else if (OAHasValidProgress(_gctx))
		_gctx->ctx->progress->cancelled = true;
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

	auto gctx = [self getNewGpxApproximationContext];
	if (gctx == nullptr)
	{
		_gctx = nullptr;
		[resultMatcher publish:nil];
		return;
	}

	std::vector<SHARED_PTR<GpxPoint>> points = [self getPoints];
	if (points.empty())
	{
		_gctx = nullptr;
		[resultMatcher publish:nil];
		return;
	}

	_gctx = gctx;
	[self startProgress];
	[self updateProgress:gctx];
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
	OASGpxRouteApproximation *gctx = [self getNewSharedGpxApproximationContext];
	NSArray<OASGpxPoint *> *points = gctx ? [self getSharedPoints] : nil;
	if (!gctx || points.count == 0)
	{
		_sharedGctx = nil;
		[resultMatcher publish:nil];
		return;
	}

	_sharedGctx = gctx;
	[self startProgress];
	[self updateSharedProgress:gctx];
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
        OASGpxRouteApproximation *gctx = [self getNewSharedGpxApproximationContext];
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
        auto gctx = [self getNewGpxApproximationContext];
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

- (void) updateProgress:(SHARED_PTR<GpxRouteApproximation>)gctx
{
	if (!OAHasValidProgress(gctx))
		return;

	if (self.progressDelegate != nil)
	{
		double delayInSeconds = 0.3;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			if (!OAHasValidProgress(gctx))
				return;

            // + UI Thread
			const auto calculationProgress = gctx->ctx->progress;
			if (!_approximationTask && _gctx == gctx)
				[self finishProgress];
			
			if (_approximationTask != nil && calculationProgress != nullptr && !calculationProgress->isCancelled())
			{
				float pr = calculationProgress->getApproximationProgress();
                if ([self.progressDelegate respondsToSelector:@selector(updateProgress:progress:)])
                    [self.progressDelegate updateProgress:self progress:(int)pr];
				if (_gctx == gctx)
					[self updateProgress:gctx];
			}
		});
	}
}

- (void) updateSharedProgress:(OASGpxRouteApproximation *)gctx
{
	OASRouteCalculationProgress *calculationProgress = gctx.ctx.calculationProgress;
	if (!calculationProgress || self.progressDelegate == nil)
		return;

	double delayInSeconds = 0.3;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		// + UI Thread
		if (!_approximationTask && _sharedGctx == gctx)
			[self finishProgress];

		if (_approximationTask != nil && !calculationProgress.isCancelled)
		{
			float pr = [calculationProgress getApproximationProgress];
			if ([self.progressDelegate respondsToSelector:@selector(updateProgress:progress:)])
				[self.progressDelegate updateProgress:self progress:(int)pr];
			if (_sharedGctx == gctx)
				[self updateSharedProgress:gctx];
		}
	});
}

@end
