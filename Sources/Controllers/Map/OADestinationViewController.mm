//
//  OADestinationViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OADestinationViewController.h"
#import "OADestination.h"

@interface OADestinationViewController ()

@property (nonatomic) NSMutableArray *destinations;
@property (nonatomic) NSMutableArray *destinationCells;

@property (nonatomic) NSArray *colors;
@property (nonatomic) NSMutableArray *usedColors;

@end

@implementation OADestinationViewController {
    
    BOOL _singleLineMode;
}

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.destinations = [NSMutableArray array];
        self.usedColors = [NSMutableArray array];
        
        self.colors = @[[UIColor colorWithRed:0.369f green:0.510f blue:0.914f alpha:1.00f],
                        [UIColor colorWithRed:0.992f green:0.627f blue:0.200f alpha:1.00f],
                        [UIColor colorWithRed:0.541f green:0.741f blue:0.373f alpha:1.00f],
                        [UIColor colorWithRed:0.988f green:0.502f blue:0.337f alpha:1.00f]];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillLayoutSubviews
{
    [self updateLayout];
}

- (void)updateFrame
{
    CGFloat big;
    CGFloat small;
    
    CGRect rect = self.parentViewController.view.bounds;
    if (rect.size.width > rect.size.height) {
        big = rect.size.width;
        small = rect.size.height;
    } else {
        big = rect.size.height;
        small = rect.size.width;
    }
    
    CGRect frame;
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
        } else {
           
            _singleLineMode = NO;
            CGFloat h = 50.0 * _destinations.count + _destinations.count - 1.0;
            if (h < 0.0)
                h = 0.0;
            frame = CGRectMake(0.0, _top, small, h);
        }
        
    } else {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
        } else {
            
            _singleLineMode = YES;
            CGFloat h = 50.0;
            frame = CGRectMake(0.0, _top, big, h);
        }
    }
    
    self.view.frame = frame;
}

- (void)updateLayout
{
    
    if (_destinations.count == 0)
        self.view.alpha = 0.0;
    else
        self.view.alpha = 1.0;
    
    CGFloat big;
    CGFloat small;
    
    CGRect rect = self.view.bounds;
    if (rect.size.width > rect.size.height) {
        big = rect.size.width;
        small = rect.size.height;
    } else {
        big = rect.size.height;
        small = rect.size.width;
    }
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            
        } else {
            
            if (_destinationCells.count > 0) {
                OADestinationCell *cell = _destinationCells[0];
                cell.destinations = @[_destinations[0]];
            }
            
            int i = 0;
            for (OADestinationCell *cell in _destinationCells) {
                CGRect frame = CGRectMake(0.0, 50.0 * i + i, small, 50.0);
                [cell updateLayout:frame];
                cell.contentView.alpha = 1.0;
                i++;
            }
            
        }
        
    } else {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            
        } else {
            
            if (_destinationCells.count > 0) {
                OADestinationCell *cell = _destinationCells[0];
                cell.destinations = [NSArray arrayWithArray:_destinations];
            }

            int i = 0;
            for (OADestinationCell *cell in _destinationCells) {
                CGRect frame = CGRectMake(0.0, 50.0 * i + i, small, 50.0);
                [cell updateLayout:frame];
                cell.contentView.alpha = (i == 0) ? 1.0 : 0.0;
                i++;
            }
        }
        
    }
    
}

- (void)btnCloseClicked:(NSInteger)tag
{
    if (_destinations.count > tag) {
        if (_destinationCells.count > tag) {
            
            OADestination *destination = _destinations[tag];
            [_usedColors removeObject:destination.color];

            OADestinationCell *cell = _destinationCells[tag];
            [cell.contentView removeFromSuperview];
            [_destinationCells removeObjectAtIndex:tag];
            [_destinations removeObjectAtIndex:tag];
            
            [self updateFrame];
            
        } else {
            [self updateLayout];
        }
        
    }
}

- (BOOL) addDestination:(OADestination *)destination
{
    if (_destinations.count >= 3)
        return NO;
    
    [_destinations addObject:destination];
    destination.color = [self getFreeColor];

    OADestinationCell *cell = [[OADestinationCell alloc] initWithDestination:destination];
    [_destinationCells addObject:cell];
    [self.view addSubview:cell.contentView];
    
    [self updateFrame];

    return YES;
}

- (UIColor *)getFreeColor
{
    for (UIColor *c in _colors) {
        if (![_usedColors containsObject:c]) {
            [_usedColors addObject:c];
            return c;
        }
    }
    return nil;
}

- (void)doLocationUpdate
{
    for (OADestinationCell *cell in _destinationCells)
        [cell updateDirections];
}

@end
