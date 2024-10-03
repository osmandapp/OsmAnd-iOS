//
//  OAGpxInfo.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 30.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OASGpxDataItem;

@interface OAGpxInfo : NSObject

@property (nonatomic) BOOL currentlyRecordingTrack;
@property (nonatomic) OASGpxDataItem *gpx;
@property (nonatomic) NSString *file;
@property (nonatomic) NSString *subfolder;

- (instancetype)initWithGpx:(OASGpxDataItem *)gpx name:(NSString *)name;
- (NSString *)getName;
- (BOOL)isCorrupted;
- (NSInteger)getSize;
- (NSDate *)getFileDate;
- (NSString *)getFileName;

@end
