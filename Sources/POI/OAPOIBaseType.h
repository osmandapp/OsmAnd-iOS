//
//  OAPOIBaseType.h
//  OsmAnd
//
//  Created by Alexey Kulish on 20/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OAPOIType;

@interface OAPOIBaseType : NSObject

@property (nonatomic, readonly) NSString *name;

@property (nonatomic) NSString *nameLocalizedEN;
@property (nonatomic) NSString *nameLocalized;

@property (nonatomic) BOOL top;

@property (nonatomic) OAPOIBaseType *baseLangType;
@property (nonatomic) NSString *lang;
@property (nonatomic) NSArray<OAPOIType *> *poiAdditionals;

- (instancetype)initWithName:(NSString *)name;

- (BOOL)isAdditional;
- (void)addPoiAdditional:(OAPOIType *)poiType;

- (UIImage *)icon;

@end
