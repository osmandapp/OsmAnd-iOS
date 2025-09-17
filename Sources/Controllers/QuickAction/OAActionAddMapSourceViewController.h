//
//  OAActionAddMapSourceViewController.h
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABaseNavbarViewController.h"

typedef NS_ENUM(NSInteger, EOAMapSourceType)
{
    EOAMapSourceTypePrimary = 0,
    EOAMapSourceTypeOverlay,
    EOAMapSourceTypeUnderlay,
    EOAMapSourceTypeOrientation
};

@class OAQuickSearchListItem;

@protocol OAAddMapSourceDelegate <NSObject>

@required

- (void)onMapSourceSelected:(NSArray *)items mapSourceType:(EOAMapSourceType)mapSourceType;

@end

@interface OAActionAddMapSourceViewController : OABaseNavbarViewController

-(instancetype)initWithNames:(NSMutableArray<NSString *> *)names type:(EOAMapSourceType)type;

@property (nonatomic) id<OAAddMapSourceDelegate> delegate;

@end
