//
//  OAPOIParser.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml/tree.h>

@class OAPOIType, OAPOICategory, OAPOIFilter;

@protocol OAPOITypesParserDelegate <NSObject>

@required
- (void)parserFinished;

@optional
- (void)encounteredError:(NSError *)error;

@end


// define a struct to hold the attribute info
struct _xmlSAX2Attributes {
    const xmlChar* localname;
    const xmlChar* prefix;
    const xmlChar* uri;
    const xmlChar* value;
    const xmlChar* end;
};
typedef struct _xmlSAX2Attributes xmlSAX2Attributes;


@interface OAPOIParser : NSObject

@property(nonatomic) NSArray<OAPOIType *> *poiTypes;
@property(nonatomic) NSDictionary<NSString *, OAPOIType *> *poiTypesByName;
@property(nonatomic) NSArray<OAPOICategory *> *poiCategories;
@property(nonatomic) OAPOICategory *otherMapCategory;
@property(nonatomic) NSArray<OAPOIFilter *> *poiFilters;
@property(nonatomic) NSArray<OAPOIType *> *textPoiAdditionals;
@property(nonatomic) NSDictionary<NSString *, NSString *> *poiAdditionalCategoryIcons;
@property(nonatomic, weak) id<OAPOITypesParserDelegate> delegate;
@property(nonatomic) BOOL error;
@property(nonatomic) NSString *fileName;

- (void)getPOITypesSync:(NSString*)fileName;
- (void)getPOITypesAsync:(NSString*)fileName;

@end
