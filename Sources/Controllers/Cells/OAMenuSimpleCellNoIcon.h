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

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textBottomMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descrTopMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textHeightPrimary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textHeightSecondary;

@end
