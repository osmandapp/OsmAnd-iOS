//
//  OADestinationViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OADestinationViewController.h"
#import "OADestination.h"
#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"

@interface OADestinationViewController ()

@property (nonatomic) NSMutableArray *destinations;
@property (nonatomic) NSMutableArray *destinationCells;

@property (nonatomic) NSArray *colors;
@property (nonatomic) NSMutableArray *usedColors;

@property (nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;

@end

@implementation OADestinationViewController {
    
    BOOL _singleLineMode;
}

-(instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.destinations = [NSMutableArray array];
        self.destinationCells = [NSMutableArray array];
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
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillLayoutSubviews
{
    [self updateLayout];
}

- (void)updateFrame
{
    CGFloat big;
    CGFloat small;
    
    CGRect rect = [UIScreen mainScreen].bounds;
    if (rect.size.width > rect.size.height) {
        big = rect.size.width;
        small = rect.size.height;
    } else {
        big = rect.size.height;
        small = rect.size.width;
    }
    
    CGRect frame;
    CGFloat top = self.view.frame.origin.y;
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
        } else {
           
            _singleLineMode = NO;
            CGFloat h = 50.0 * _destinations.count + _destinations.count - 1.0;
            if (h < 0.0)
                h = 0.0;
            frame = CGRectMake(0.0, top, small, h);
        }
        
    } else {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
        } else {
            
            _singleLineMode = YES;
            CGFloat h = 50.0;
            if (_destinations.count == 0)
                h = 0.0;
            
            frame = CGRectMake(0.0, top, big, h);
        }
    }
    
    self.view.frame = frame;
}

- (void)updateLayout
{
    CGFloat width = self.view.bounds.size.width;
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
            
        } else {
            
            if (_destinationCells.count > 0 && _destinations.count > 0) {
                OADestinationCell *cell = _destinationCells[0];
                cell.destinations = @[_destinations[0]];
            }
            
            int i = 0;
            for (OADestinationCell *cell in _destinationCells) {
                cell.drawSplitLine = i > 0;
                CGRect frame = CGRectMake(0.0, 50.0 * i + i - (cell.drawSplitLine ? 1 : 0), width, 50.0 + (cell.drawSplitLine ? 1 : 0));
                [cell updateLayout:frame];
                cell.contentView.hidden = NO;
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
                if (i == 0) {
                    CGRect frame = CGRectMake(0.0, 50.0 * i + i, width, 50.0);
                    [cell updateLayout:frame];
                }
                cell.contentView.hidden = (i == 0) ? NO : YES;
                i++;
            }
        }
        
    }
    
}

- (BOOL)processCell:(OADestinationCell *)cell destination:(OADestination *)destination
{
    BOOL isCellEmpty = NO;
    
    if (cell.destinations.count > 1) {
        NSMutableArray *arr = [NSMutableArray arrayWithArray:cell.destinations];
        [arr removeObject:destination];
        cell.destinations = [NSArray arrayWithArray:arr];
    } else {
        isCellEmpty = YES;
        cell.destinations = nil;
    }
    
    if (isCellEmpty) {
        [UIView animateWithDuration:.2 animations:^{
            cell.contentView.alpha = 0.0;
            
        } completion:^(BOOL finished) {
            [self updateFrame];
            [cell.contentView removeFromSuperview];
            if (_destinations.count == 0) {
                [self.view removeFromSuperview];
                [self stopLocationUpdate];
            }
        }];
    }
    
    return isCellEmpty;

}

- (void)btnCloseClicked:(OADestination *)destination
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([_destinations containsObject:destination]) {
            
            [_usedColors removeObject:destination.color];
            [_destinations removeObject:destination];
            
            NSMutableArray *cellsDel = [NSMutableArray array];
            for (OADestinationCell *c in _destinationCells)
                if ([c.destinations containsObject:destination])
                    if ([self processCell:c destination:destination])
                        [cellsDel addObject:c];
            
            for (OADestinationCell *c in cellsDel)
                [_destinationCells removeObject:c];
            
            if (_destinationCells.count > 1) {
                OADestinationCell *cell = _destinationCells[0];
                OADestination *d = cell.destinations[0];
                
                for (int i = 1; i < _destinationCells.count; i++) {
                    OADestinationCell *c = _destinationCells[i];
                    if ([c.destinations containsObject:d]) {
                        if ([self processCell:c destination:d])
                            [_destinationCells removeObject:c];
                        break;
                    }
                }
            }
            
        }
    });
}

- (BOOL) addDestination:(OADestination *)destination
{
    if (_destinations.count >= 3)
        return NO;
    
    [_destinations addObject:destination];
    destination.color = [self getFreeColor];

    OADestinationCell *cell = [[OADestinationCell alloc] initWithDestination:destination];
    cell.delegate = self;
    cell.contentView.alpha = 0.0;
    [_destinationCells addObject:cell];
    [self.view addSubview:cell.contentView];
    
    [UIView animateWithDuration:.2 animations:^{
        cell.contentView.alpha = 1.0;
    }];

    [self startLocationUpdate];
    
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
    dispatch_async(dispatch_get_main_queue(), ^{
        for (OADestinationCell *cell in _destinationCells)
            [cell updateDirections];
    });
}

- (void)startLocationUpdate
{
    if (_destinations.count == 0 || self.locationServicesUpdateObserver)
        return;
    
    OsmAndAppInstance app = [OsmAndApp instance];
    self.locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                    withHandler:@selector(doLocationUpdate)
                                                                     andObserve:app.locationServices.updateObserver];
}

- (void)stopLocationUpdate
{
    if (self.locationServicesUpdateObserver) {
        [self.locationServicesUpdateObserver detach];
        self.locationServicesUpdateObserver = nil;
    }
}

@end
