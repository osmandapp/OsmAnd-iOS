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
#import "OAMultiDestinationCell.h"

@interface OADestinationViewController ()

@property (nonatomic) NSMutableArray *destinations;
@property (nonatomic) NSMutableArray *destinationCells;
@property (nonatomic) OAMultiDestinationCell *multiCell;

@property (nonatomic) NSArray *colors;
@property (nonatomic) NSMutableArray *usedColors;

@property (nonatomic) OAAutoObserverProxy* locationServicesUpdateObserver;

@end

@implementation OADestinationViewController {
    
    BOOL _singleLineMode;
}

- (NSArray *)allDestinations
{
    return [NSArray arrayWithArray:self.destinations];
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
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) && _singleLineOnly)
        big = small;
    
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation) && !_singleLineOnly) {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
        } else {
           
            _singleLineMode = NO;
            CGFloat h = 50.0 * _destinations.count + _destinations.count - 1.0;
            if (h < 0.0)
                h = 0.0;
            frame = CGRectMake(0.0, _top, small, h);

            if (_multiCell) {
                _multiCell.contentView.hidden = YES;
                if (_multiCell.editModeActive)
                    [_multiCell exitEditMode];
            }
            for (OADestinationCell *cell in _destinationCells)
                cell.contentView.hidden = NO;
        }
        
    } else {
        
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            
        } else {
            
            _singleLineMode = YES;
            CGFloat h = 50.0;
            if (_destinations.count == 0)
                h = 0.0;
            
            frame = CGRectMake(0.0, _top, big, h);
            
            if (_multiCell)
                _multiCell.contentView.hidden = NO;
            for (OADestinationCell *cell in _destinationCells)
                cell.contentView.hidden = YES;
        }
    }
    
    self.view.frame = frame;
    
    if (_delegate)
        [_delegate destinationViewLayoutDidChange];
}

- (void)updateLayout
{
    CGFloat width = self.view.bounds.size.width;
    
    if (_singleLineMode) {
        if (_multiCell) {
            CGRect frame = CGRectMake(0.0, 0.0, width, 50.0);
            [_multiCell updateLayout:frame];
            //_multiCell.contentView.hidden = NO;
        }
    } else {
        int i = 0;
        for (OADestinationCell *cell in _destinationCells) {
            cell.drawSplitLine = i > 0;
            CGRect frame = CGRectMake(0.0, 50.0 * i + i - (cell.drawSplitLine ? 1 : 0), width, 50.0 + (cell.drawSplitLine ? 1 : 0));
            [cell updateLayout:frame];
            //cell.contentView.hidden = NO;
            i++;
        }
    }
}


- (void)btnCloseClicked:(id)sender destination:(OADestination *)destination
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([_destinations containsObject:destination]) {
            
            [_usedColors removeObject:destination.color];
            [_destinations removeObject:destination];
            
            // process single cells
            OADestinationCell *cell;
            for (OADestinationCell *c in _destinationCells)
                if ([c.destinations containsObject:destination]) {
                    cell = c;
                    break;
                }
            
            if (cell) {
                
                [_destinationCells removeObject:cell];
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
            
            // process multi cell
            BOOL isCellEmpty = NO;
            
            if (_multiCell.destinations.count > 1) {
                NSMutableArray *arr = [NSMutableArray arrayWithArray:_multiCell.destinations];
                [arr removeObject:destination];
                [UIView animateWithDuration:.2 animations:^{
                    _multiCell.destinations = [NSArray arrayWithArray:arr];
                }];
            } else {
                isCellEmpty = YES;
                _multiCell.destinations = nil;
            }
            
            if (isCellEmpty) {
                [UIView animateWithDuration:.2 animations:^{
                    _multiCell.contentView.alpha = 0.0;
                    
                } completion:^(BOOL finished) {
                    
                    if (_multiCell.editModeActive)
                        [_multiCell exitEditMode];

                    [self updateFrame];
                    [_multiCell.contentView removeFromSuperview];
                    _multiCell = nil;
                    if (_destinations.count == 0) {
                        [self.view removeFromSuperview];
                        [self stopLocationUpdate];
                    }
                }];
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

    if (!_multiCell) {
        self.multiCell = [[OAMultiDestinationCell alloc] initWithDestinations:@[destination]];
        _multiCell.delegate = self;
        if (_singleLineMode)
            _multiCell.contentView.alpha = 0.0;
        [self.view addSubview:_multiCell.contentView];
    } else {
        [UIView animateWithDuration:.2 animations:^{
            _multiCell.destinations = [NSArray arrayWithArray:_destinations];
        }];
    }
    
    OADestinationCell *cell = [[OADestinationCell alloc] initWithDestination:destination];
    cell.delegate = self;
    if (!_singleLineMode)
        cell.contentView.alpha = 0.0;
    else
        cell.contentView.hidden = YES;
    
    [_destinationCells addObject:cell];
    [self.view addSubview:cell.contentView];
    
    if (!_singleLineMode)
        [UIView animateWithDuration:.2 animations:^{
            cell.contentView.alpha = 1.0;
        }];
    else  if (_multiCell.contentView.alpha == 0.0)
        [UIView animateWithDuration:.2 animations:^{
            _multiCell.contentView.alpha = 1.0;
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
        if (_multiCell)
            [_multiCell updateDirections];
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
