//
//  OAGPXWptViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 08/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"
#import "OAGpxWptItem.h"
#import <CoreLocation/CoreLocation.h>


@protocol OAGPXWptViewControllerDelegate <NSObject>

@optional
- (void)changedWptItem;

@end


@class OAMapViewController, OAPOI;

@interface OAGPXWptViewController : OATargetInfoViewController

@property (nonatomic) OAMapViewController *mapViewController;
@property (nonatomic) OAGpxWptItem *wpt;

@property (nonatomic, weak) id<OAGPXWptViewControllerDelegate> wptDelegate;

- (instancetype) initWithItem:(OAGpxWptItem *)wpt headerOnly:(BOOL)headerOnly;

// the amenity of the point card: the map amenity with the point's custom tags, or the point's own tags
+ (OAPOI *) cardAmenityForPoint:(OAGpxWptItem *)wpt mapAmenity:(OAPOI *)mapAmenity genericRowKeys:(NSSet<NSString *> *)genericRowKeys;

- (NSString *) getGpxFileName;
- (NSString *) getItemName;
- (NSString *) getItemGroup;
- (NSString *) getItemDesc;
- (UIImage *) getIcon;
- (NSDate *) getTimestamp;

@end
