//
//  OADestinationCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#define kOADestinationEditModeEnabled YES
#define kOADestinationEditModeGlobal YES

@class OADestination;

@protocol OADestinatioCellProtocol <NSObject>
@optional

- (void)btnCloseClicked:(id)sender destination:(OADestination *)destination;
- (void)openHideDestinationCardsView:(id)sender;

@end

@interface OADestinationCell : NSObject

@property (nonatomic) UIView *directionsView;
@property (nonatomic) UIButton *btnClose;
@property (nonatomic) UIView *colorView;
@property (nonatomic) UIImageView *compassImage;
@property (nonatomic) UIView *markerView;
@property (nonatomic) UIImageView *markerImage;
@property (nonatomic) UILabel *distanceLabel;
@property (nonatomic) UILabel *descLabel;
@property (nonatomic) UILabel *infoLabel;

@property (nonatomic) UIView *contentView;
@property (nonatomic) NSArray *destinations;
@property (weak, nonatomic) id<OADestinatioCellProtocol> delegate;
@property (nonatomic, assign) BOOL drawSplitLine;

@property (nonatomic, assign) CLLocationCoordinate2D currentLocation;
@property (nonatomic, assign) CLLocationDirection currentDirection;

@property (nonatomic, assign) BOOL mapCenterArrow;
@property (nonatomic, assign) CGFloat infoLabelWidth;

@property (nonatomic, assign) NSInteger destinationIndex;

@property (nonatomic) UIFont *primaryFont;
@property (nonatomic) UIFont *unitsFont;
@property (nonatomic) UIColor *primaryColor;
@property (nonatomic) UIColor *unitsColor;


+ (NSString *)parkingTimeStr:(OADestination *)destination shortText:(BOOL)shortText;
+ (void)setParkingTimerStr:(OADestination *)destination label:(UILabel *)label shortText:(BOOL)shortText;

- (instancetype)initWithDestination:(OADestination *)destination destinationIndex:(NSInteger)destinationIndex;

- (void)updateLayout:(CGRect)frame;
- (void)reloadData;
- (void)updateDirections:(CLLocationCoordinate2D)myLocation direction:(CLLocationDirection)direction;

- (void)updateDirection:(OADestination *)destination imageView:(UIImageView *)imageView;

- (OADestination *)destinationByPoint:(CGPoint)point;

- (void)openDestinationsView:(id)sender;

@end
