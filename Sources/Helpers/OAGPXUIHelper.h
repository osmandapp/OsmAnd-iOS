//
//  OAGPXUIHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 9/12/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OAGPXDocument, OAGpxTrkSeg;
@class OARouteCalculationResult;
@class OAGPX;

@interface OAGpxFileInfo : NSObject

@property (nonatomic, readonly) NSString *fileName;
@property (nonatomic, readonly) long lastModified;
@property (nonatomic, readonly) long fileSize;
@property (nonatomic) BOOL selected;

- (instancetype) initWithFileName:(NSString *)fileName lastModified:(long)lastModified fileSize:(long)fileSize;

@end

@interface OAGPXUIHelper : NSObject

+ (OAGPXDocument *) makeGpxFromRoute:(OARouteCalculationResult *)route;
+ (NSString *) getDescription:(OAGPX *)gpx;

+ (long) getSegmentTime:(OAGpxTrkSeg *)segment;
+ (double) getSegmentDistance:(OAGpxTrkSeg *)segment;

+ (NSArray<OAGpxFileInfo *> *) getSortedGPXFilesInfo:(NSString *)dir selectedGpxList:(NSArray<NSString *> *)selectedGpxList absolutePath:(BOOL)absolutePath;

@end

