//
//  OAAbstractCard.h
//  OsmAnd
//
//  Created by Paul on 5/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class OAMapPanelViewController;
@class OAAbstractCard;

@protocol OAAbstractCardDelegate <NSObject>

@required

- (void) requestCardReload:(OAAbstractCard *) card;

@end

@interface OAAbstractCard : NSObject

@property (nonatomic) id<OAAbstractCardDelegate> delegate;

+ (NSString *) getCellNibId;

- (void) build:(UICollectionViewCell *) cell;
- (void) update;
- (void) onCardPressed:(OAMapPanelViewController *) mapPanel;

@end

NS_ASSUME_NONNULL_END
