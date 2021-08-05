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
@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UIImageView *leftImageView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *noImageTextLeadingMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageTextLeadingMargin;
@property (weak, nonatomic) IBOutlet UIButton *openCloseGroupButton;

-(void)showImage:(BOOL)show;

@end
