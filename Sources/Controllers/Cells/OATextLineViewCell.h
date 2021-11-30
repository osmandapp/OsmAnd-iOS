//
//  OATextLineViewCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 01/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OATextLineViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *textView;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textTopLargeConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textTopSmallConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textBottomLargeConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textBottomSmallConstraint;

- (void)makeSmallMargins:(BOOL)small;

@end
