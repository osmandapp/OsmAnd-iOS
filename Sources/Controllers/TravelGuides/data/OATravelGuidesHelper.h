//
//  OATravelGuidesHelper.h
//  OsmAnd
//
//  Created by nnngrach on 08.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OATravelArticle, OAGPXDocumentAdapter, OASGpxDataItem;

/**
 What is left of the travel guides on the app's side: where the map is looking, how an article's
 text is trimmed, and writing a built gpx file out to disk and into the tracks database.

 The reading itself - the obf files, the articles, the gpx build - lives in OsmAndShared, behind
 OATravelObfHelper.
 */
@interface OATravelGuidesHelper : NSObject

+ (void) showContextMenuWithLatitude:(double)latitude longitude:(double)longitude;

+ (CLLocation *) getMapCenter;

+ (NSString *) getPatrialContent:(NSString *)content;

+ (NSString *) normalizeFileUrl:(NSString *)url;

+ (NSString *) createGpxFile:(OATravelArticle *)article fileName:(NSString *)fileName;

+ (OASGpxDataItem *) buildGpx:(NSString *)path title:(NSString *)title document:(OAGPXDocumentAdapter *)document;

+ (void)showGpx:(NSString *)path documentAdapter:(OAGPXDocumentAdapter *)documentAdapter;

+ (NSString *) getSelectedGPXFilePath:(NSString *)fileName;

@end
