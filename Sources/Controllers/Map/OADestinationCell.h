//
//  OADestinationCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OADestination;

@protocol OADestinatioCellProtocol <NSObject>
@optional

- (void)btnCloseClicked:(OADestination *)destination;

@end

@interface OADestinationCell : NSObject

@property (nonatomic) UIView *contentView;
@property (nonatomic) NSArray *destinations;
@property (weak, nonatomic) id<OADestinatioCellProtocol> delegate;
@property (nonatomic, assign) BOOL drawSplitLine;

- (instancetype)initWithDestination:(OADestination *)destination;
- (instancetype)initWithDestinations:(NSArray *)destinations;

- (void)updateLayout:(CGRect)frame;
- (void)reloadData;

- (void)updateDirections;


@end
