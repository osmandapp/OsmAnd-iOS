//
//  OATileSource.m
//  OsmAnd
//
//  Created by Paul on 01.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OATileSource.h"
#import "OASQLiteTileSource.h"

#include <OsmAndCore/Map/OnlineTileSources.h>


@implementation OATileSource

+ (instancetype) tileSourceWithParameters:(NSDictionary *)params
{
    return [[self alloc] initWithParameters:params];
}

+ (instancetype) tileSourceFromOnlineSource:(const std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> &)source
{
    return [[self alloc] initFromSource:source];
}

+ (instancetype) tileSourceFromSqlSource:(OASQLiteTileSource *)source
{
    return [[self alloc] initFromSql:source];
}

- (instancetype) initFromSql:(OASQLiteTileSource *)source
{
    self = [super init];
    if (self) {
        _isSql = YES;
        _name = source.name;
        _title = source.title;
        if (_title.length == 0)
            _title = _name;
        
        _minZoom = source.minimumZoomSupported;
        _maxZoom = source.maximumZoomSupported;
        _url = source.urlTemplate;
        _randoms = source.randoms;
        _ellipsoid = source.isEllipticYTile;
        _invertedY = source.isInvertedYTile;
        _referer = source.referer;
        _timesupported = source.isTimeSupported;
        _expire = source.getExpirationTimeMillis;
        _inversiveZoom = source.isInversiveZoom;
        _ext = source.tileFormat;
        _tileSize = source.tileSize;
        _bitDensity = source.bitDensity;
        _avgSize = 18000;
        _rule = source.rule;
    }
    return self;
}

- (instancetype) initFromSource:(const std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> &)source
{
    self = [super init];
    if (self) {
        _isSql = NO;
        _name = source->name.toNSString();
        _title = _name;
        
        _minZoom = source->minZoom;
        _maxZoom = source->maxZoom;
        _url = source->urlToLoad.toNSString();
        _randoms = source->randoms.toNSString();
        _ellipsoid = source->ellipticYTile;
        _invertedY = source->invertedYTile;
        _referer = @"";
        _timesupported = source->expirationTimeMillis > 0;
        _expire = source->expirationTimeMillis;
        _inversiveZoom = NO;
        _ext = source->ext.toNSString();
        _tileSize = source->tileSize;
        _bitDensity = source->bitDensity;
        _avgSize = source->avgSize;
        _rule = source->rule.toNSString();
    }
    return self;
}

- (instancetype) initFromTileSource:(OATileSource *)other newName:(NSString *)newName
{
    self = [super init];
    if (self) {
        _isSql = other.isSql;
        _name = newName;
        if ([other.title isEqualToString:other.name])
            _title = newName;
        
        _minZoom = other.minZoom;
        _maxZoom = other.maxZoom;
        _url = other.url;
        _randoms = other.randoms;
        _ellipsoid = other.ellipsoid;
        _invertedY = other.invertedY;
        _referer = other.referer;
        _timesupported = other.timesupported;
        _expire = other.expire;
        _inversiveZoom = other.inversiveZoom;
        _ext = other.ext;
        _tileSize = other.tileSize;
        _bitDensity = other.bitDensity;
        _avgSize = other.avgSize;
        _rule = other.rule;
    }
    return self;
}

- (instancetype) initWithParameters:(NSDictionary *)params
{
    self = [super init];
    if (self) {
        [self parseParameters:params];
    }
    return self;
}

- (void) parseParameters:(NSDictionary *)params
{
    _isSql = [params[@"sql"] boolValue];
    
    _name = params[@"name"];
    _title = params[@"title"];
    if (_title.length == 0)
        _title = _name;

    _minZoom = [params[@"minZoom"] intValue];
    _maxZoom = [params[@"maxZoom"] intValue];
    _url = params[@"url"];
    _randoms = params[@"randoms"];
    _ellipsoid = params[@"ellipsoid"] ? [params[@"ellipsoid"] boolValue] : NO;
    _invertedY = params[@"inverted_y"] ? [params[@"inverted_y"] boolValue] : NO;
    _referer = params[@"referer"];
    _timesupported = params[@"timesupported"] ? [params[@"timesupported"] boolValue] : NO;
    _expire = [params[@"expire"] longValue];
    _inversiveZoom = params[@"inversiveZoom"] ? [params[@"inversiveZoom"] boolValue] : NO;
    _ext = params[@"ext"];
    _tileSize = [params[@"tileSize"] intValue];
    _bitDensity = [params[@"bitDensity"] intValue];
    _avgSize = [params[@"avgSize"] intValue];
    _rule = params[@"rule"];
}

- (NSDictionary *) toSqlParams
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    params[@"minzoom"] = [NSString stringWithFormat:@"%d", _minZoom];
    params[@"maxzoom"] = [NSString stringWithFormat:@"%d", _maxZoom];
    params[@"url"] = _url;
    params[@"title"] = _title;
    params[@"ellipsoid"] = _ellipsoid ? @(1) : @(0);
    params[@"inverted_y"] = _invertedY ? @(1) : @(0);
    params[@"expireminutes"] = _expire != -1 ? [NSString stringWithFormat:@"%ld", _expire] : @"";
    params[@"timecolumn"] = _timesupported ? @"yes" : @"no";
    params[@"rule"] = _rule;
    params[@"randoms"] = _randoms;
    params[@"referer"] = _referer;
    params[@"inversiveZoom"] = _inversiveZoom ? @(1) : @(0);
    params[@"ext"] = _ext;
    params[@"tileSize"] = [NSString stringWithFormat:@"%d", _tileSize];
    params[@"bitDensity"] = [NSString stringWithFormat:@"%d", _bitDensity];
    return params;
}

- (std::shared_ptr<OsmAnd::IOnlineTileSources::Source>) toOnlineTileSource
{
    const auto result = std::make_shared<OsmAnd::IOnlineTileSources::Source>(QString::fromNSString(_name));

    result->urlToLoad = QString::fromNSString(_url);
    result->minZoom = OsmAnd::ZoomLevel(_minZoom);
    result->maxZoom = OsmAnd::ZoomLevel(_maxZoom);
    result->expirationTimeMillis = _expire;
    result->ellipticYTile = _ellipsoid;
    //result->priority = _tileSource->priority;
    result->tileSize = _tileSize;
    result->ext = QString::fromNSString(_ext);
    result->avgSize = _avgSize;
    result->bitDensity = _bitDensity;
    result->invertedYTile = _invertedY;
    result->randoms = QString::fromNSString(_randoms);
    result->randomsArray = OsmAnd::OnlineTileSources::parseRandoms(result->randoms);
    result->rule = QString::fromNSString(_rule);
    return result;
}

@end
