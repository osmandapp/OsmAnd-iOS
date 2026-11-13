//
//  OAEditPointViewController.h
//  OsmAnd
//
//  Created by nnngrach on 05.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseNavbarSubviewViewController.h"
#import <CoreLocation/CoreLocation.h>

typedef NS_ENUM(NSInteger, EOAEditPointType) {
    EOAEditPointTypeFavorite = 0,
    EOAEditPointTypeWaypoint
};

@class OAFavoriteItem, OAGpxWptItem, OAPOI, OASGpxFile;
@class OATargetMenuViewControllerState;

@protocol OAGpxWptEditingHandlerDelegate <NSObject>

@required

- (BOOL)saveGpxWpt:(OAGpxWptItem *)gpxWpt gpxFileName:(NSString *)gpxFileName;
- (BOOL)updateGpxWpt:(OAGpxWptItem *)gpxWptItem docPath:(NSString *)docPath updateMap:(BOOL)updateMap;
- (BOOL)replaceGpxWpt:(OAGpxWptItem *)existingItem withItem:(OAGpxWptItem *)item newPoint:(BOOL)newPoint;
- (void)deleteGpxWpt:(OAGpxWptItem *)gpxWptItem docPath:(NSString *)docPath;
- (BOOL)saveItemToStorage:(OAGpxWptItem *)gpxWptItem;

@end

@protocol OAEditPointViewControllerDelegate <NSObject>

- (void)saveTapped;

@end

@interface OAEditPointViewController : OABaseNavbarSubviewViewController

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSString *gpxFileName;
@property (nonatomic, copy) NSString *savedGroupName;
@property (nonatomic, copy) NSString *groupTitle;

@property (nonatomic, weak) id<OAGpxWptEditingHandlerDelegate> gpxWptDelegate;
@property (nonatomic, weak) id<OAEditPointViewControllerDelegate> delegate;

- (instancetype)initWithFavorite:(OAFavoriteItem *)favorite;
- (instancetype)initWithGpxWpt:(OAGpxWptItem *)gpxWpt;
- (instancetype)initWithLocation:(CLLocationCoordinate2D)location
                           title:(NSString *)formattedTitle
                         address:(NSString *)address
                     customParam:(NSString *)customParam
                       pointType:(EOAEditPointType)pointType
                 targetMenuState:(OATargetMenuViewControllerState *)targetMenuState
                             poi:(OAPOI *)poi
                    targetObject:(id)targetObject;
- (instancetype)initWithLocation:(CLLocationCoordinate2D)location
                           title:(NSString *)formattedTitle
                         address:(NSString *)address
                     customParam:(NSString *)customParam
                       pointType:(EOAEditPointType)pointType
                 targetMenuState:(OATargetMenuViewControllerState *)targetMenuState
                             poi:(OAPOI *)poi
                         gpxFile:(OASGpxFile *)gpxFile
                    targetObject:(id)targetObject;

- (void)applyQuickActionParams:(NSDictionary *)params;

@end
