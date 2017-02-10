//
//  OACollapsableWikiView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACollapsableView.h"

@class OAPOI;

@interface OACollapsableWikiView : OACollapsableView

@property (nonatomic, readonly) NSArray<OAPOI *> *nearestWiki;
@property (nonatomic, readonly) BOOL hasOsmWiki;

- (void) setWikiArray:(NSArray<OAPOI *> *)nearestWiki hasOsmWiki:(BOOL)hasOsmWiki latitude:(double)latitude longitude:(double)longitude;

@end
