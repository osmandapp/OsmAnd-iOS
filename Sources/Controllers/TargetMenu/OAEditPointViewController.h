//
//  OAEditPointViewController.h
//  OsmAnd
//
//  Created by nnngrach on 05.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseTableViewController.h"
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSInteger, EOAEditPointType) {
    EOAEditPointTypeFavorite = 0,
    EOAEditPointTypeWaypoint
};

@class OAFavoriteItem, OAGpxWptItem, OAPOI;
@class OATargetMenuViewControllerState;

@protocol OAGpxWptEditingHandlerDelegate <NSObject>

@required

- (void)saveGpxWpt:(OAGpxWptItem *)gpxWpt gpxFileName:(NSString *)gpxFileName;
- (void)updateGpxWpt:(OAGpxWptItem *)gpxWptItem docPath:(NSString *)docPath updateMap:(BOOL)updateMap;
- (void)deleteGpxWpt:(OAGpxWptItem *)gpxWptItem docPath:(NSString *)docPath;
- (void)saveItemToStorage:(OAGpxWptItem *)gpxWptItem;

@end

@interface OAEditPointViewController : OABaseTableViewController

@property (weak, nonatomic) IBOutlet UIImageView *headerIconPoi;
@property (weak, nonatomic) IBOutlet UIImageView *headerIconBackground;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *navBarHeightConstraint;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSString *gpxFileName;
@property (nonatomic, assign) NSInteger savedColorIndex;
@property (nonatomic, copy) NSString *savedGroupName;
@property (nonatomic, copy) NSString *groupTitle;
@property (nonatomic, copy) UIColor *groupColor;

@property (nonatomic, weak) id<OAGpxWptEditingHandlerDelegate> gpxWptDelegate;

- (id)initWithFavorite:(OAFavoriteItem *)favorite;
- (id)initWithGpxWpt:(OAGpxWptItem *)gpxWpt;
- (id)initWithLocation:(CLLocationCoordinate2D)location
                 title:(NSString *)formattedTitle
           customParam:(NSString *)customParam
             pointType:(EOAEditPointType)pointType
       targetMenuState:(OATargetMenuViewControllerState *)targetMenuState
                   poi:(OAPOI *)poi;

@end
