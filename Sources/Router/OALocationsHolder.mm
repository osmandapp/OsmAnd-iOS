//
//  OALocationsHolder.m
//  OsmAnd Maps
//
//  Created by Paul on 12.06.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OALocationsHolder.h"
#import "OAGPXDocumentPrimitives.h"

#import <CoreLocation/CoreLocation.h>

#define LOCATION_TYPE_UNKNOWN -1
#define LOCATION_TYPE_LOCATION 0
#define LOCATION_TYPE_WPTPT 1

@interface OALocationsHolder ()

@property (nonatomic, assign) NSInteger locationType;

@end

@implementation OALocationsHolder
{
	NSArray<CLLocation *> *_locationList;
	NSArray<OAWptPt *> *_wptPtList;
}

- (instancetype) initWithLocations:(NSArray *)locations
{
	self = [super init];
	if (self)
	{
		_locationType = [self resolveLocationType:locations];
		switch (_locationType) {
			case LOCATION_TYPE_LOCATION:
			{
				_locationList = [NSArray arrayWithArray:locations];
				break;
			}
			case LOCATION_TYPE_WPTPT:
			{
				_wptPtList = [NSArray arrayWithArray:locations];
				break;
			}
		}
		_size = locations.count;
	}
	return self;
}


- (NSInteger) resolveLocationType:(NSArray *)locations
{
	if (locations.count > 0)
	{
		id locationObj = locations.firstObject;
		if ([locationObj isKindOfClass:OAWptPt.class])
			return LOCATION_TYPE_WPTPT;
		else if ([locationObj isKindOfClass:CLLocation.class])
			return LOCATION_TYPE_LOCATION;
		else
			@throw [NSException exceptionWithName:@"Illegal argument exception" reason:[NSString stringWithFormat:@"Unsupported location type: %@", NSStringFromClass([locationObj class])] userInfo:nil];
	}
	return LOCATION_TYPE_UNKNOWN;
}

- (double) getLatitude:(NSInteger)index
{
	switch (_locationType)
	{
		case LOCATION_TYPE_LOCATION:
		{
			if (index < _locationList.count)
				return _locationList[index].coordinate.latitude;
			break;
		}
		case LOCATION_TYPE_WPTPT:
		{
			if (index < _wptPtList.count)
				return _wptPtList[index].getLatitude;
		}
		default:
			return 0;
	}
	return 0;
}

- (double) getLongitude:(NSInteger)index
{
	switch (_locationType)
	{
		case LOCATION_TYPE_LOCATION:
		{
			if (index < _locationList.count)
				return _locationList[index].coordinate.longitude;
			break;
		}
		case LOCATION_TYPE_WPTPT:
		{
			if (index < _wptPtList.count)
				return _wptPtList[index].getLongitude;
		}
		default:
			return 0;
	}
	return 0;
}

- (NSArray *) getList:(NSInteger)locationType
{
	NSMutableArray *res = [NSMutableArray array];
	if (self.size > 0)
	{
		for (NSInteger i = 0; i < self.size; i++)
		{
			switch (_locationType)
			{
				case LOCATION_TYPE_LOCATION:
					[res addObject:[self getLocation:i]];
					break;
				case LOCATION_TYPE_WPTPT:
					[res addObject:[self getWptPt:i]];
					break;
			}
		}
	}
	return res;
}

- (std::vector<std::pair<double, double>>) getLatLonList
{
	std::vector<std::pair<double, double>> res;
	if (_locationType == LOCATION_TYPE_LOCATION)
	{
		for (CLLocation *loc in _locationList)
		{
			res.push_back({loc.coordinate.latitude, loc.coordinate.longitude});
		}
	}
	else if (_locationType == LOCATION_TYPE_WPTPT)
	{
		for (OAWptPt *wpt in _wptPtList)
		{
			res.push_back({wpt.getLatitude, wpt.getLongitude});
		}
	}
	return res;
}

- (NSArray<OAWptPt *> *)getWptPtList
{
	if (_locationType == LOCATION_TYPE_WPTPT)
		return _wptPtList;
	else
		return [self getList:LOCATION_TYPE_WPTPT];
}

- (NSArray<CLLocation *> *) getLocationsList
{
	if (_locationType == LOCATION_TYPE_LOCATION)
		return _locationList;
	else
		return [self getList:LOCATION_TYPE_LOCATION];
}

- (std::pair<double, double>) getLatLon:(NSInteger)index
{
	return std::pair<double, double>([self getLatitude:index], [self getLongitude:index]);
}

- (OAWptPt *) getWptPt:(NSInteger)index
{
	if (_locationType == LOCATION_TYPE_WPTPT)
	{
		return _wptPtList[index];
	}
	else
	{
		OAWptPt *wptPt = [[OAWptPt alloc] init];
		wptPt.position = CLLocationCoordinate2DMake([self getLatitude:index], [self getLongitude:index]);
		return wptPt;
	}
}

- (CLLocation *) getLocation:(NSInteger)index
{
	if (_locationType == LOCATION_TYPE_LOCATION)
		return _locationList[index];
	else
		return [[CLLocation alloc] initWithLatitude:[self getLatitude:index] longitude:[self getLongitude:index]];
}

// MARK: NSCopying

- (id) copyWithZone:(NSZone *)zone
{
	OALocationsHolder *copy = [[self.class alloc] initWithLocations:[self getList:_locationType]];
	return copy;
}

- (BOOL)isEqual:(id)other
{
	if (other == self) {
		return YES;
	} else {
		OALocationsHolder *otherObj = (OALocationsHolder *)other;
		return [[self getList:_locationType] isEqual:[otherObj getList:otherObj.locationType]];
	}
}

- (NSUInteger)hash
{
	NSUInteger result = _locationType;
	result += [[self getList:_locationType] hash];
	return result;
}

@end
