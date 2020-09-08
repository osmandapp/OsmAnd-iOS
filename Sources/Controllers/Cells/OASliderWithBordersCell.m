//
//  OASliderWithBordersCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 29.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASliderWithBordersCell.h"
#import "OAColors.h"

@implementation OASliderWithBordersCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self setNumberOfMarks:2];
}

- (IBAction)sliderValueChanged:(id)sender
{

}


- (IBAction)sliderDidEndEditing:(id)sender
{
    
}

@end
