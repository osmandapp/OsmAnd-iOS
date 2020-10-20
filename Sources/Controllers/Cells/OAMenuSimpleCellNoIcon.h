//
//  OAMenuSimpleCellNoIcon.h
//  OsmAnd
//
//  Created by Paul on 19/09/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAMenuSimpleCellNoIcon : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;

@property (nonatomic) IBOutlet NSLayoutConstraint *textBottomMargin;
@property (nonatomic) IBOutlet NSLayoutConstraint *descrTopMargin;
@property (nonatomic) IBOutlet NSLayoutConstraint *textHeightPrimary;
@property (nonatomic) IBOutlet NSLayoutConstraint *textHeightSecondary;

@end
