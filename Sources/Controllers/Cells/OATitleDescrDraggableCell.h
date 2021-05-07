//
//  OATitleDescrDraggableCell.h
//  OsmAnd
//
//  Created by Paul on 18/04/19.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseMGSwipeCell.h"
#import "MGSwipeTableCell.h"

@interface OATitleDescrDraggableCell : OABaseMGSwipeCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *textView;
@property (weak, nonatomic) IBOutlet UILabel *descView;
@property (weak, nonatomic) IBOutlet UIButton *overflowButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleBottomToCenter;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleToDescrConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleToIconCostraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descrToIconConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descrToMarginConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleToMarginConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descrBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textHeightSecondary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *textHeightPrimary;


-(void)showImage:(BOOL)show;

@end
