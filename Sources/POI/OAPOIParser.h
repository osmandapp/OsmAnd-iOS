//
//  OAPOIParser.h
//  OsmAnd
//
//  Created by Alexey Kulish on 18/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <libxml/tree.h>

@class OAPOI;
@protocol OAPOIParserDelegate;

// define a struct to hold the attribute info
struct _xmlSAX2Attributes {
    const xmlChar* localname;
    const xmlChar* prefix;
    const xmlChar* uri;
    const xmlChar* value;
    const xmlChar* end;
};
typedef struct _xmlSAX2Attributes xmlSAX2Attributes;


@interface OAPOIParser : NSObject {
    
    BOOL _done;
    BOOL _error;
    xmlParserCtxtPtr _xmlParserContext;
    NSOperationQueue *_retrieverQueue;
    
    // libxml2 parsing stuff
    NSMutableString *_elevation;
    BOOL _parsingElevation;
    NSMutableString *_time;
    BOOL _parsingTime;
    NSMutableString *_speed;
    BOOL _parsingSpeed;
    NSMutableString *_course;
    BOOL _parsingCourse;
}

@property(nonatomic) NSArray *pois;
@property(nonatomic) NSArray *categories;
@property(nonatomic) BOOL error;
@property(nonatomic) OAPOI *currentPOIItem;
@property(nonatomic) NSMutableString *propertyValue;
@property(nonatomic, weak) id<OAPOIParserDelegate> delegate;
@property(nonatomic) NSOperationQueue *retrieverQueue;
@property(nonatomic) NSString *fileName;

- (void)getPOIDataSync:(NSString*)poiFileName;
- (void)getPOIDataAsync:(NSString*)poiFileName;

@end

@protocol OAPOIParserDelegate <NSObject>

@required
- (void)parserFinished;

@optional
- (void)encounteredError:(NSError *)error;

@end