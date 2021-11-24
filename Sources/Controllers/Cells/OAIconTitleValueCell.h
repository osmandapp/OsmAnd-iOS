//
//  OAIconTitleValueCell.h
//  OsmAnd
//
//  Created by Paul on 1.06.19.
//  Copyright (c) 2019 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAIconTitleValueCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;
@property (weak, nonatomic) IBOutlet UIImageView *leftIconView;
@property (weak, nonatomic) IBOutlet UIImageView *rightIconView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *noLeftIconTextLeadingMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leftIconTextLeadingMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *noRightIconDecsLeadingMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *rightIconDescLeadingMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topLabelMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomLabelMargin;
@property (weak, nonatomic) IBOutlet UIButton *openCloseGroupButton;

-(void)showLeftIcon:(BOOL)show;
-(void)showRightIcon:(BOOL)show;

@end
