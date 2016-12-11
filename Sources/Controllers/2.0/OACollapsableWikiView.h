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

@property (nonatomic) NSArray<OAPOI *> *nearestWiki;

@end
