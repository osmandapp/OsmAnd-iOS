//
//  OASelectSubcategoryViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAPOICategory;
@class OAPOIUIFilter;
@class OAPOIType;

@protocol OASelectSubcategoryDelegate

@required

- (void)selectSubcategoryCancel;
- (void)selectSubcategoryDone:(OAPOICategory *)category keys:(NSMutableSet<NSString *> *)keys allSelected:(BOOL)allSelected;
- (UIImage *)getPoiIcon:(OAPOIType *)poiType;

@end

@interface OASelectSubcategoryViewController : OACompoundViewController

@property (nonatomic, weak) id<OASelectSubcategoryDelegate> delegate;

- (instancetype)initWithCategory:(OAPOICategory *)category filter:(OAPOIUIFilter *)filter;

@end
