//
//  OACollapsableMapillaryView.h
//  OsmAnd
//
//  Created by Paul on 24/05/2019.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OACollapsableView.h"

#define TYPE_MAPILLARY_PHOTO @"mapillary-photo"
#define TYPE_MAPILLARY_CONTRIBUTE @"mapillary-contribute"
#define TYPE_MAPILLARY_EMPTY @"mapillary-empty"
#define TYPE_URL_PHOTO @"url-photo"
#define TYPE_WIKIMEDIA_PHOTO @"wikimedia-photo"
#define TYPE_WIKIDATA_PHOTO @"wikidata-photo"

@class OAAbstractCard;

@protocol OACollapsableCardViewDelegate <NSObject>

@required

- (void) onViewExpanded;

@end

@interface OACollapsableCardsView : OACollapsableView

@property (nonatomic) id<OACollapsableCardViewDelegate> delegate;
@property (nonatomic, readonly) NSArray<OAAbstractCard *> *cards;

- (void) setCards:(NSArray<OAAbstractCard *> *)cards;

@end
