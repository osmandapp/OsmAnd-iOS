//
//  OAObjectType.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/search/core/ObjectType.java
//  git revision f1c7d7e276fd3f2ea7cb80699387c3e8cfb7d809

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, EOAObjectType)
{
    EOAObjectTypeUNDEFINED = -1,
    EOAObjectTypeCITY = 0,
    EOAObjectTypeVILLAGE,
    EOAObjectTypePOSTCODE,
    EOAObjectTypeSTREET,
    EOAObjectTypeHOUSE,
    EOAObjectTypeSTREET_INTERSECTION,
    // POI
    EOAObjectTypePOI_TYPE,
    EOAObjectTypePOI,
    // LOCATION
    EOAObjectTypeLOCATION,
    EOAObjectTypePARTIAL_LOCATION,
    // UI OBJECTS
    EOAObjectTypeFAVORITE,
    EOAObjectTypeFAVORITE_GROUP,
    EOAObjectTypeWPT,
    EOAObjectTypeRECENT_OBJ,
    EOAObjectTypeGPX_TRACK,

    EOAObjectTypeREGION,
    
    EOAObjectTypeSEARCH_STARTED,
    EOAObjectTypeSEARCH_FINISHED,
    EOAObjectTypeFILTER_FINISHED,
    EOAObjectTypeSEARCH_API_FINISHED,
    EOAObjectTypeSEARCH_API_REGION_FINISHED,
    EOAObjectTypeUNKNOWN_NAME_FILTER
};

@interface OAObjectType : NSObject

@property (nonatomic, readonly) EOAObjectType type;

+ (instancetype)withType:(EOAObjectType)type;

+ (BOOL) hasLocation:(EOAObjectType)objecType;
+ (BOOL) isAddress:(EOAObjectType)objecType;
+ (BOOL) isTopVisible:(EOAObjectType)objecType;
+ (NSString *) toString:(EOAObjectType)objecType;
+ (OAObjectType *) getExclusiveSearchType:(EOAObjectType)objectType;
+ (double) getTypeWeight:(EOAObjectType)objectType;

+ (OAObjectType *)valueOf:(NSString *)type;

@end
