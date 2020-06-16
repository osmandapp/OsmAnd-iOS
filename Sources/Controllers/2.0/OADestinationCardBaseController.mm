//
//  OADestinationCardBaseController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OADestinationCardBaseController.h"

@implementation OADestinationCardBaseController

- (instancetype)initWithSection:(NSInteger)section tableView:(UITableView *)tableView
{
    self = [super init];
    if (self)
    {
        _section = section;
        _tableView = tableView;
    }
    return self;
}

-(void)dealloc
{
    [self onDisappear];
}

- (void)generateData
{
    
}

- (void)updateSectionNumber:(NSInteger)section
{
    _section = section;
}

- (NSInteger)rowsCount
{
    return 0;
}

- (UITableViewCell *)cellForRow:(NSInteger)row
{
    return nil;
}

- (void)didSelectRow:(NSInteger)row
{
    
}

- (id)getItem:(NSInteger)row
{
    return nil;
}

- (void)updateCell:(UITableViewCell *)cell item:(id)item row:(NSInteger)row
{
    
}

- (void) reorderObjects:(NSInteger) source dest:(NSInteger)dest
{
    
}

- (NSArray *)getSwipeButtons:(NSInteger)row
{
    return nil;
}

- (void)onAppear
{
    
}

- (void)onDisappear
{
    
}

- (void)refreshSwipeButtons;
{
    if (self.delegate)
        [self.delegate refreshSwipeButtons:self.section];
}

- (void)refreshFirstRow
{
    if (self.delegate)
        [self.delegate refreshFirstRow:self.section];
}

- (void)refreshVisibleRows
{
    if (self.delegate)
        [self.delegate refreshVisibleRows:self.section];
}

- (void)refreshAllRows
{
    if (self.delegate)
        [self.delegate refreshAllRows:self.section];
}

- (BOOL)isDecelerating
{
    if (self.delegate)
        return [self.delegate isDecelerating];
    else
        return NO;
}

- (BOOL)isSwiping
{
    if (self.delegate)
        return [self.delegate isSwiping];
    else
        return NO;
}

- (void)removeCard
{
    if (self.delegate)
        [self.delegate cardRemoved:self.section];
}

@end
