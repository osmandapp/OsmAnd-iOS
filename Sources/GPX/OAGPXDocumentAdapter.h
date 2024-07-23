//
//  OAGPXDocumentAdapter.h
//  OsmAnd
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

@class OAGPXTrackAnalysis, OAGPXDocument;

@interface OAGPXDocumentAdapter : NSObject

@property (nonatomic) OAGPXDocument *object;
@property (nonatomic) NSString *path;

- (OAGPXTrackAnalysis *) getAnalysis:(long)fileTimestamp;
- (BOOL) hasAltitude;
- (int) pointsCount;
- (NSString *) getMetadataValueBy:(NSString *)tag;

@end
