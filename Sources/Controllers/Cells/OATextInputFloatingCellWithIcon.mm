//
//  OATextInputFloatingCellWithIcon.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATextInputFloatingCellWithIcon.h"
#import "OAUtilities.h"

@implementation OATextInputFloatingCellWithIcon

+ (NSString *) getCellIdentifier
{
    return @"OATextInputFloatingCellWithIcon";
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    return [self.textField becomeFirstResponder];
}

@end
