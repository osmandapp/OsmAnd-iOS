//
//  OAMultiselectableHeaderView.h
//  OsmAnd
//
//  Created by Alexey Kulish on 25/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol OAMultiselectableHeaderDelegate <NSObject>

@optional
-(void)headerCheckboxChanged:(id)sender value:(BOOL)value;

@end

@interface OAMultiselectableHeaderView : UIView

@property (nonatomic) UIButton *checkmark;
@property (nonatomic) UILabel *title;
@property (nonatomic, assign) NSInteger section;
@property (nonatomic, assign) BOOL editable;
@property (nonatomic, weak) id<OAMultiselectableHeaderDelegate> delegate;
@property (nonatomic, assign) BOOL selected;

@property (nonatomic, assign) NSInteger checkmarkIndent;

- (void)setEditing:(BOOL)editing animated:(BOOL)animated;
- (void)setTitleText:(NSString *)title;


@end
