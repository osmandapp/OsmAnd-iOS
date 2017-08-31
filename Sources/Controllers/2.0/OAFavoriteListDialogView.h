//
//  OAFavoriteListDialogView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 28/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OAFavoriteItem;

@protocol OAFavoriteListDialogDelegate <NSObject>

@required
- (void) onFavoriteSelected:(OAFavoriteItem *)item;

@end

@interface OAFavoriteListDialogView : UIView

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, weak) id<OAFavoriteListDialogDelegate> delegate;

@property (nonatomic) NSUInteger sortingType;

- (instancetype) initWithFrame:(CGRect)frame sortingType:(int)sortingType;

- (void) switchSorting;

@end
