//
//  OAGPXDocumentAdapter.h
//  OsmAnd
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@class OASGpxTrackAnalysis, OASGpxFile;

@interface OAGPXDocumentAdapter : NSObject

@property (nonatomic) OASGpxFile *object;
@property (nonatomic) NSString *path;

- (OASGpxTrackAnalysis *)getAnalysis:(long)fileTimestamp;
- (BOOL)hasAltitude;
- (int)pointsCount;
- (NSString *)getMetadataValueBy:(NSString *)tag;

@end
