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
#import "OAApplicationMode.h"
#import "OALocationsHolder.h"
#import "OAResultMatcher.h"
#import "OAGpxRouteApproximation.h"

#include <routePlannerFrontEnd.h>

@interface OAGpxApproximator ()

@property (nonatomic) NSThread *approximationTask;

@end

@interface OAApproximationTask : NSThread

@property (nonatomic) NSThread *previousTask;

- (instancetype)initWithApproximator:(OAGpxApproximator *)approximator
								 env:(OARoutingEnvironment *)env
								gctx:(SHARED_PTR<GpxRouteApproximation> &)gctx
							  points:(const std::vector<SHARED_PTR<GpxPoint>> &)points
					   resultMatcher:(OAResultMatcher<OAGpxRouteApproximation *> *)resultMatcher;

@end

@implementation OAApproximationTask
{
	__weak OAGpxApproximator *_approximator;
	OARoutingEnvironment *_env;
	SHARED_PTR<GpxRouteApproximation> _gctx;
	std::vector<SHARED_PTR<GpxPoint>> _points;
	OAResultMatcher<OAGpxRouteApproximation *> *_resultMatcher;
}

- (instancetype)initWithApproximator:(OAGpxApproximator *)approximator
								 env:(OARoutingEnvironment *)env
								gctx:(SHARED_PTR<GpxRouteApproximation> &)gctx
							  points:(const std::vector<SHARED_PTR<GpxPoint>> &)points
					   resultMatcher:(OAResultMatcher<OAGpxRouteApproximation *> *)resultMatcher
{
	self = [super init];
	if (self)
	{
		self.qualityOfService = NSQualityOfServiceUtility;
		_approximator = approximator;
		_env = env;
		_gctx = gctx;
		_points = points;
		_resultMatcher = resultMatcher;
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
	[OARoutingHelper.sharedInstance calculateGpxApproximation:_env gctx:_gctx points:_points resultMatcher:_resultMatcher];
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

- (SHARED_PTR<GpxRouteApproximation>) getNewGpxApproximationContext
{
	const auto newContext = std::make_shared<GpxRouteApproximation>(_env.ctx.get());
	newContext->ctx->progress = std::make_shared<RouteCalculationProgress>();
//	newContext->MINIMUM_POINT_APPROXIMATION = _pointApproximation;
	return newContext;
}

- (std::vector<SHARED_PTR<GpxPoint>>) getPoints
{
	if (_points.empty())
		_points = [_routingHelper generateGpxPoints:_env gctx:[self getNewGpxApproximationContext] locationsHolder:_locationsHolder];
	vector<SHARED_PTR<GpxPoint>> points(_points.size());
	for (int i = 0; i < _points.size(); i++)
		points[i] = make_shared<GpxPoint>(_points[i]);
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
	return _gctx != nullptr && _gctx->ctx->progress->isCancelled();
}

- (void) cancelApproximation
{
	if (_gctx != nullptr)
		_gctx->ctx->progress->cancelled = true;
}

- (void) calculateGpxApproximation:(OAResultMatcher<OAGpxRouteApproximation *> *)resultMatcher
{
	if (_gctx != nullptr)
		_gctx->ctx->progress->cancelled = true;
	auto gctx = [self getNewGpxApproximationContext];
	_gctx = gctx;
	[self startProgress];
	[self updateProgress:gctx];
	OAApproximationTask *task = [[OAApproximationTask alloc] initWithApproximator:self env:_env gctx:_gctx points:self.getPoints resultMatcher:resultMatcher];
	task.previousTask = _approximationTask;
	[task start];
}

- (void) startProgress
{
	if (self.progressDelegate)
		[self.progressDelegate start:self];
}

- (void) finishProgress
{
	if (self.progressDelegate != nil)
		[self.progressDelegate finish:self];
}

- (void) updateProgress:(SHARED_PTR<GpxRouteApproximation>)gctx
{
	if (self.progressDelegate != nil)
	{
		double delayInSeconds = 0.3;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			const auto calculationProgress = _gctx->ctx->progress;
			if (_approximationTask && _gctx == gctx)
				[self finishProgress];
			
			if (_approximationTask != nil && calculationProgress != nullptr && !calculationProgress->isCancelled())
			{
				float pr = calculationProgress->getLinearProgress();
				if (self.progressDelegate)
					[self.progressDelegate updateProgress:self progress:(int)pr];
				if (_gctx == gctx)
					[self updateProgress:gctx];
			}
		});
	}
}

@end
