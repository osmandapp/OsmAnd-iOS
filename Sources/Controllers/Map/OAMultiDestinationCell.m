//
//  OAMultiDestinationCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 03/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAMultiDestinationCell.h"
#import "OADestination.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAUtilities.h"

@implementation OAMultiDestinationCell
{
    
    BOOL _editButtonActive;

    UIFont *_primaryFont;
    UIFont *_unitsFont;
    
    UIColor *_primaryColor;
    UIColor *_unitsColor;
}

@synthesize destinations = _destinations;
@synthesize contentView = _contentView;
@synthesize directionsView = _directionsView;
@synthesize btnClose = _btnClose;
@synthesize colorView = _colorView;
@synthesize markerView = _markerView;
@synthesize distanceLabel = _distanceLabel;
@synthesize descLabel = _descLabel;
@synthesize infoLabel = _infoLabel;
@synthesize compassImage = _compassImage;
@synthesize delegate = _delegate;

- (instancetype)initWithDestinations:(NSArray *)destinations
{
    self = [super init];
    if (self) {
        self.destinations = destinations;
    }
    return self;
}

- (OADestination *)destinationByPoint:(CGPoint)point
{
    if (_editModeActive)
        return nil;
    
    CGFloat width = _directionsView.bounds.size.width / _destinations.count;
    
    for (int i = 0; i < _destinations.count; i++) {
        CGRect clickableFrame = CGRectMake(width * i, 0.0, width, _directionsView.bounds.size.height);
        if (CGRectContainsPoint(clickableFrame, point))
            return _destinations[i];
    }
    
    return nil;
}

- (void)updateLayout:(CGRect)frame
{
    CGFloat h = frame.size.height;
    CGFloat dirViewWidth = frame.size.width - (kOADestinationEditModeEnabled ? 41.0 : 0.0);
    if (_destinations.count == 3 && dirViewWidth / 3.0 < 140.0)
        h += 20.0;
        
    CGRect newFrame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, h);
    
    _contentView.frame = newFrame;
    _directionsView.frame = CGRectMake(0.0, 0.0, dirViewWidth, h - 0.0);
    
    if (kOADestinationEditModeEnabled)
        _btnClose.frame = CGRectMake(_directionsView.frame.size.width + 1, 0.0, 40.0, h - 0.0);
    
    switch (_destinations.count) {
        case 1:
        {
            BOOL isParking = ((OADestination *)self.destinations[0]).parking && ((OADestination *)self.destinations[0]).carPickupDateEnabled;
            
            _colorView.frame = CGRectMake(5.0, 5.0, 40.0, 40.0);
            _markerView.frame = CGRectMake(_colorView.frame.origin.x + 27.0, _colorView.frame.origin.y + 27.0, 14.0, 14.0);
            _distanceLabel.frame = CGRectMake(60.0, 7.0, _directionsView.frame.size.width - 68.0 - (isParking ? self.infoLabelWidth : 0.0), 21.0);
            _distanceLabel.textAlignment = NSTextAlignmentLeft;
            _infoLabel.frame = CGRectMake(60.0 + _distanceLabel.frame.size.width, 7.0, self.infoLabelWidth, 21.0);
            _infoLabel.textAlignment = NSTextAlignmentRight;
            _infoLabel.hidden = !isParking;
            _descLabel.frame = CGRectMake(60.0, 24.0, _directionsView.frame.size.width - 68.0, 21.0);
            _descLabel.hidden = NO;
            
            if (_colorView2)
                _colorView2.hidden = YES;
            if (_markerView2)
                _markerView2.hidden = YES;
            if (_distanceLabel2)
                _distanceLabel2.hidden = YES;
            if (_infoLabel2)
                _infoLabel2.hidden = YES;
            if (_descLabel2)
                _descLabel2.hidden = YES;
            
            if (_colorView3)
                _colorView3.hidden = YES;
            if (_markerView3)
                _markerView3.hidden = YES;
            if (_distanceLabel3)
                _distanceLabel3.hidden = YES;
            if (_infoLabel3)
                _infoLabel3.hidden = YES;
            if (_descLabel3)
                _descLabel3.hidden = YES;
            
            break;
        }
        case 2:
        {
            BOOL isParking = ((OADestination *)self.destinations[0]).parking && ((OADestination *)self.destinations[0]).carPickupDateEnabled;
            BOOL isParking2 = ((OADestination *)self.destinations[1]).parking && ((OADestination *)self.destinations[1]).carPickupDateEnabled;
            
            _colorView.frame = CGRectMake(5.0, 5.0, 40.0, 40.0);
            _markerView.frame = CGRectMake(_colorView.frame.origin.x + 27.0, _colorView.frame.origin.y + 27.0, 14.0, 14.0);
            CGFloat textWidth = dirViewWidth / 2.0 - 62.0;
            if (textWidth > 60.0 + self.infoLabelWidth && isParking)
            {
                _distanceLabel.frame = CGRectMake(55.0, 7.0, textWidth - self.infoLabelWidth, 21.0);
                _infoLabel.frame = CGRectMake(55.0 + _distanceLabel.frame.size.width, 7.0, self.infoLabelWidth, 21.0);
                _infoLabel.textAlignment = NSTextAlignmentRight;
                _infoLabel.hidden = NO;
                _descLabel.frame = CGRectMake(55.0, 24.0, textWidth, 21.0);
                _descLabel.hidden = NO;
            }
            else if (textWidth > 80.0)
            {
                _distanceLabel.frame = CGRectMake(55.0, 7.0, textWidth, 21.0);
                if (isParking)
                {
                    _infoLabel.frame = CGRectMake(55.0, 24.0, self.infoLabelWidth, 21.0);
                    _infoLabel.textAlignment = NSTextAlignmentLeft;
                    _infoLabel.hidden = NO;
                    _descLabel.hidden = YES;
                }
                else
                {
                    _descLabel.frame = CGRectMake(55.0, 24.0, textWidth, 21.0);
                    _infoLabel.hidden = YES;
                    _descLabel.hidden = NO;
                }
            }
            else
            {
                _distanceLabel.frame = CGRectMake(55.0, 15.0, textWidth, 21.0);
                _infoLabel.hidden = YES;
                _descLabel.hidden = YES;
            }
            _distanceLabel.textAlignment = NSTextAlignmentLeft;
            
            _colorView2.frame = CGRectMake(dirViewWidth / 2.0, 5.0, 40.0, 40.0);
            _colorView2.hidden = NO;
            _markerView2.frame = CGRectMake(_colorView2.frame.origin.x + 27.0, _colorView2.frame.origin.y + 27.0, 14.0, 14.0);
            _markerView2.hidden = NO;
            
            if (textWidth > 60.0 + self.infoLabelWidth && isParking2)
            {
                _distanceLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 7.0, textWidth - self.infoLabelWidth, 21.0);
                _distanceLabel2.hidden = NO;
                _infoLabel2.frame = CGRectMake(_distanceLabel2.frame.origin.x + _distanceLabel2.frame.size.width, 7.0, self.infoLabelWidth, 21.0);
                _infoLabel2.textAlignment = NSTextAlignmentRight;
                _infoLabel2.hidden = NO;
                _descLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 24.0, textWidth, 21.0);
                _descLabel2.hidden = NO;
            }
            else if (textWidth > 80.0)
            {
                _distanceLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 7.0, textWidth, 21.0);
                _distanceLabel2.hidden = NO;
                if (isParking2)
                {
                    _infoLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 24.0, self.infoLabelWidth, 21.0);
                    _infoLabel2.textAlignment = NSTextAlignmentLeft;
                    _infoLabel2.hidden = NO;
                    _descLabel2.hidden = YES;
                }
                else
                {
                    _descLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 24.0, textWidth, 21.0);
                    _infoLabel2.hidden = YES;
                    _descLabel2.hidden = NO;
                }
            }
            else
            {
                _distanceLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 15.0, textWidth, 21.0);
                _distanceLabel2.hidden = NO;
                _infoLabel2.hidden = YES;
                _descLabel2.hidden = YES;
            }
            _distanceLabel2.textAlignment = NSTextAlignmentLeft;
            
            if (_colorView3)
                _colorView3.hidden = YES;
            if (_markerView3)
                _markerView3.hidden = YES;
            if (_distanceLabel3)
                _distanceLabel3.hidden = YES;
            if (_infoLabel3)
                _infoLabel3.hidden = YES;
            if (_descLabel3)
                _descLabel3.hidden = YES;
            
            break;
        }
        case 3:
        {
            CGFloat width = _directionsView.bounds.size.width / 3.0;
            
            BOOL isParking = ((OADestination *)self.destinations[0]).parking && ((OADestination *)self.destinations[0]).carPickupDateEnabled && width > 260.0;
            BOOL isParking2 = ((OADestination *)self.destinations[1]).parking && ((OADestination *)self.destinations[1]).carPickupDateEnabled && width > 260.0;
            BOOL isParking3 = ((OADestination *)self.destinations[2]).parking && ((OADestination *)self.destinations[2]).carPickupDateEnabled && width > 260.0;
            
            if (width >= 160) {
                CGFloat textWidth = width - 60.0;
                _colorView.frame = CGRectMake(5.0, 5.0, 40.0, 40.0);
                _markerView.frame = CGRectMake(_colorView.frame.origin.x + 27.0, _colorView.frame.origin.y + 27.0, 14.0, 14.0);
                _distanceLabel.frame = CGRectMake(55.0, 7.0, textWidth - (isParking ? self.infoLabelWidth : 0.0), 21.0);
                _descLabel.frame = CGRectMake(55.0, 24.0, textWidth, 21.0);
                _distanceLabel.textAlignment = NSTextAlignmentLeft;
                _descLabel.hidden = NO;
                
                if (isParking) {
                    _infoLabel.frame = CGRectMake(55.0 + _distanceLabel.frame.size.width, 7.0, self.infoLabelWidth, 21.0);
                    _infoLabel.hidden = NO;
                } else {
                    _infoLabel.hidden = YES;
                }
                
                _colorView2.frame = CGRectMake(width, 5.0, 40.0, 40.0);
                _colorView2.hidden = NO;
                _markerView2.frame = CGRectMake(_colorView2.frame.origin.x + 27.0, _colorView2.frame.origin.y + 27.0, 14.0, 14.0);
                _markerView2.hidden = NO;
                _distanceLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 7.0, textWidth - (isParking2 ? self.infoLabelWidth : 0.0), 21.0);
                _distanceLabel2.textAlignment = NSTextAlignmentLeft;
                _distanceLabel2.hidden = NO;
                _descLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 24.0, textWidth, 21.0);
                _descLabel2.hidden = NO;
                
                if (isParking2) {
                    _infoLabel2.frame = CGRectMake(_distanceLabel2.frame.origin.x + _distanceLabel2.frame.size.width, 7.0, self.infoLabelWidth, 21.0);
                    _infoLabel2.hidden = NO;
                } else {
                    _infoLabel2.hidden = YES;
                }
                
                _colorView3.frame = CGRectMake(width * 2.0, 5.0, 40.0, 40.0);
                _colorView3.hidden = NO;
                _markerView3.frame = CGRectMake(_colorView3.frame.origin.x + 27.0, _colorView2.frame.origin.y + 27.0, 14.0, 14.0);
                _markerView3.hidden = NO;
                _distanceLabel3.frame = CGRectMake(_colorView3.frame.origin.x + 50.0, 7.0, textWidth - (isParking3 ? self.infoLabelWidth : 0.0), 21.0);
                _distanceLabel3.textAlignment = NSTextAlignmentLeft;
                _distanceLabel3.hidden = NO;
                _descLabel3.frame = CGRectMake(_colorView3.frame.origin.x + 50.0, 24.0, textWidth, 21.0);
                _descLabel3.hidden = NO;
                
                if (isParking3) {
                    _infoLabel3.frame = CGRectMake(_distanceLabel3.frame.origin.x + _distanceLabel3.frame.size.width, 7.0, self.infoLabelWidth, 21.0);
                    _infoLabel3.hidden = NO;
                } else {
                    _infoLabel3.hidden = YES;
                }
                
            }
            else if (width >= 140)
            {
                CGFloat textWidth = width - 60.0;
                _colorView.frame = CGRectMake(5.0, 5.0, 40.0, 40.0);
                _markerView.frame = CGRectMake(_colorView.frame.origin.x + 27.0, _colorView.frame.origin.y + 27.0, 14.0, 14.0);
                _distanceLabel.frame = CGRectMake(55.0, 15.0, textWidth, 21.0);
                _distanceLabel.textAlignment = NSTextAlignmentLeft;
                _descLabel.hidden = YES;
                _infoLabel.hidden = YES;
                
                _colorView2.frame = CGRectMake(width, 5.0, 40.0, 40.0);
                _colorView2.hidden = NO;
                _markerView2.frame = CGRectMake(_colorView2.frame.origin.x + 27.0, _colorView2.frame.origin.y + 27.0, 14.0, 14.0);
                _markerView2.hidden = NO;
                _distanceLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 15.0, textWidth, 21.0);
                _distanceLabel2.textAlignment = NSTextAlignmentLeft;
                _distanceLabel2.hidden = NO;
                _descLabel2.hidden = YES;
                _infoLabel2.hidden = YES;
                
                _colorView3.frame = CGRectMake(width * 2.0, 5.0, 40.0, 40.0);
                _colorView3.hidden = NO;
                _markerView3.frame = CGRectMake(_colorView3.frame.origin.x + 27.0, _colorView3.frame.origin.y + 27.0, 14.0, 14.0);
                _markerView3.hidden = NO;
                _distanceLabel3.frame = CGRectMake(_colorView3.frame.origin.x + 50.0, 15.0, textWidth, 21.0);
                _distanceLabel3.textAlignment = NSTextAlignmentLeft;
                _distanceLabel3.hidden = NO;
                _descLabel3.hidden = YES;
                _infoLabel3.hidden = YES;
                
            }
            else
            {
                CGFloat textWidth = 70.0;
                _colorView.frame = CGRectMake(width / 2.0 - 20.0, 5.0, 40.0, 40.0);
                _markerView.frame = CGRectMake(_colorView.frame.origin.x + 27.0, _colorView.frame.origin.y + 27.0, 14.0, 14.0);
                _distanceLabel.frame = CGRectMake(width / 2.0 - 35.0, 48.0, textWidth, 21.0);
                _distanceLabel.textAlignment = NSTextAlignmentCenter;
                _descLabel.hidden = YES;
                _infoLabel.hidden = YES;
                
                _colorView2.frame = CGRectMake(width + width / 2.0 - 20.0, 5.0, 40.0, 40.0);
                _colorView2.hidden = NO;
                _markerView2.frame = CGRectMake(_colorView2.frame.origin.x + 27.0, _colorView2.frame.origin.y + 27.0, 14.0, 14.0);
                _markerView2.hidden = NO;
                _distanceLabel2.frame = CGRectMake(width + width / 2.0 - 35.0, 48.0, textWidth, 21.0);
                _distanceLabel2.textAlignment = NSTextAlignmentCenter;
                _distanceLabel2.hidden = NO;
                _descLabel2.hidden = YES;
                _infoLabel2.hidden = YES;
                
                _colorView3.frame = CGRectMake(width * 2.0 + width / 2.0 - 20.0, 5.0, 40.0, 40.0);
                _colorView3.hidden = NO;
                _markerView3.frame = CGRectMake(_colorView3.frame.origin.x + 27.0, _colorView3.frame.origin.y + 27.0, 14.0, 14.0);
                _markerView3.hidden = NO;
                _distanceLabel3.frame = CGRectMake(width * 2.0 + width / 2.0 - 35.0, 48.0, textWidth, 21.0);
                _distanceLabel3.textAlignment = NSTextAlignmentCenter;
                _distanceLabel3.hidden = NO;
                _descLabel3.hidden = YES;
                _infoLabel3.hidden = YES;
            }
            
            break;
        }
        default:
            break;
    }
    
}


- (void)buildUI
{
    if (!self.contentView)
    {
        self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 50.0)];
        _contentView.backgroundColor = UIColorFromRGB(0x044b7f);
        _contentView.opaque = YES;
    }
    
    if (!self.directionsView)
    {
        self.directionsView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 279.0, 50.0)];
        _directionsView.backgroundColor = UIColorFromRGB(0x044b7f);
        _directionsView.opaque = YES;
        [_contentView addSubview:self.directionsView];
    }
    
    if (!self.btnClose && kOADestinationEditModeEnabled)
    {
        if (kOADestinationEditModeGlobal && self.destinationIndex == 0)
        {
            self.btnClose = [UIButton buttonWithType:UIButtonTypeSystem];
            _btnClose.frame = CGRectMake(280.0, 0.0, 40.0, 50.0);
            _btnClose.backgroundColor = UIColorFromRGB(0x044b7f);
            _btnClose.opaque = YES;
            _btnClose.tintColor = UIColorFromRGB(0x5081a6);
            [_btnClose setTitle:@"" forState:UIControlStateNormal];
            [_btnClose setImage:[UIImage imageNamed:@"three_dots"] forState:UIControlStateNormal];
            [_btnClose addTarget:self action:@selector(openDestinationsView:) forControlEvents:UIControlEventTouchUpInside];
        }
        else if (!kOADestinationEditModeGlobal)
        {
            self.btnClose = [[UIButton alloc] initWithFrame:CGRectMake(280.0, 0.0, 40.0, 50.0)];
            _btnClose.backgroundColor = UIColorFromRGB(0x044b7f);
            _btnClose.opaque = YES;
            [_btnClose setTitle:@"" forState:UIControlStateNormal];
            [_btnClose setImage:[UIImage imageNamed:@"ic_close"] forState:UIControlStateNormal];
            [_btnClose addTarget:self action:@selector(closeDestination:) forControlEvents:UIControlEventTouchUpInside];
        }
        
        if (self.btnClose)
            [_contentView addSubview:self.btnClose];
    }
    
    if (!self.colorView)
    {
        self.colorView = [[UIView alloc] initWithFrame:CGRectMake(5.0, 5.0, 40.0, 40.0)];
        _colorView.backgroundColor = [UIColor clearColor];
        self.compassImage = [[UIImageView alloc] initWithFrame:_colorView.bounds];
        _compassImage.contentMode = UIViewContentModeCenter;
        [_colorView addSubview:self.compassImage];
        [_directionsView addSubview:self.colorView];
        
        self.editButton1 = [UIButton buttonWithType:UIButtonTypeSystem];
        _editButton1.frame = _colorView.bounds;
        [_editButton1 addTarget:self action:@selector(closeDestinationEdit:) forControlEvents:UIControlEventTouchUpInside];
        [_editButton1 setImage:[UIImage imageNamed:@"ic_close"] forState:UIControlStateNormal];
        _editButton1.tintColor = [UIColor whiteColor];
        _editButton1.tag = 0;
    }
    
    if (!self.markerView)
    {
        self.markerView = [[UIView alloc] initWithFrame:CGRectMake(32.0, 32.0, 14.0, 14.0)];
        self.markerView.backgroundColor = [UIColor clearColor];
        //self.markerView.layer.cornerRadius = self.markerView.bounds.size.width / 2.0;
        //self.markerView.layer.masksToBounds = YES;
        self.markerImage = [[UIImageView alloc] initWithFrame:self.markerView.bounds];
        self.markerImage.contentMode = UIViewContentModeCenter;
        [self.markerView addSubview:self.markerImage];
    }
    
    if (!self.distanceLabel)
    {
        self.distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 7.0, 211.0, 21.0)];
        _distanceLabel.font = [UIFont fontWithName:@"AvenirNext-Bold" size:18.0];
        _distanceLabel.textAlignment = NSTextAlignmentLeft;
        _distanceLabel.textColor = UIColorFromRGB(0xffffff);
        _distanceLabel.minimumScaleFactor = 0.7;
        [_directionsView addSubview:_distanceLabel];
    }
    
    if (!self.infoLabel)
    {
        self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0 + _distanceLabel.frame.size.width, 7.0, self.infoLabelWidth, 21.0)];
        _infoLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:15.0];
        _infoLabel.textAlignment = NSTextAlignmentRight;
        _infoLabel.textColor = UIColorFromRGB(0x8ea2b9);
        _infoLabel.minimumScaleFactor = 0.7;
        [_directionsView addSubview:_infoLabel];
    }
    
    if (!self.descLabel)
    {
        self.descLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 24.0, 211.0, 21.0)];
        _descLabel.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:15.0];
        _descLabel.textAlignment = NSTextAlignmentLeft;
        _descLabel.textColor = UIColorFromRGB(0x8ea2b9);
        //_descLabel.minimumScaleFactor = 0.7;
        [_directionsView addSubview:_descLabel];
    }
    
    if (_destinations.count > 1)
    {
        if (!self.colorView2)
        {
            self.colorView2 = [[UIView alloc] initWithFrame:CGRectMake(5.0, 5.0, 40.0, 40.0)];
            _colorView2.backgroundColor = [UIColor clearColor];
            self.compassImage2 = [[UIImageView alloc] initWithFrame:_colorView.bounds];
            _compassImage2.contentMode = UIViewContentModeCenter;
            [_colorView2 addSubview:self.compassImage2];
            [_directionsView addSubview:self.colorView2];

            self.editButton2 = [UIButton buttonWithType:UIButtonTypeSystem];
            _editButton2.frame = _colorView2.bounds;
            [_editButton2 addTarget:self action:@selector(closeDestinationEdit:) forControlEvents:UIControlEventTouchUpInside];
            [_editButton2 setImage:[UIImage imageNamed:@"ic_close"] forState:UIControlStateNormal];
            _editButton2.tintColor = [UIColor whiteColor];
            _editButton2.tag = 1;
        }
        
        if (!self.markerView2)
        {
            self.markerView2 = [[UIView alloc] initWithFrame:CGRectMake(32.0, 32.0, 14.0, 14.0)];
            self.markerView2.backgroundColor = [UIColor clearColor];
            //self.markerView2.layer.cornerRadius = self.markerView2.bounds.size.width / 2.0;
            //self.markerView2.layer.masksToBounds = YES;
            self.markerImage2 = [[UIImageView alloc] initWithFrame:self.markerView2.bounds];
            self.markerImage2.contentMode = UIViewContentModeCenter;
            [self.markerView2 addSubview:self.markerImage2];
        }
        
        if (!self.distanceLabel2)
        {
            self.distanceLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 7.0, 211.0, 21.0)];
            _distanceLabel2.font = [UIFont fontWithName:@"AvenirNext-Bold" size:18.0];
            _distanceLabel2.textAlignment = NSTextAlignmentLeft;
            _distanceLabel2.textColor = UIColorFromRGB(0xffffff);
            _distanceLabel2.minimumScaleFactor = 0.7;
            [_directionsView addSubview:_distanceLabel2];
        }
        
        if (!self.infoLabel2)
        {
            self.infoLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(60.0 + _distanceLabel2.frame.size.width, 7.0, self.infoLabelWidth, 21.0)];
            _infoLabel2.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:15.0];
            _infoLabel2.textAlignment = NSTextAlignmentRight;
            _infoLabel2.textColor = UIColorFromRGB(0x8ea2b9);
            _infoLabel2.minimumScaleFactor = 0.7;
            [_directionsView addSubview:_infoLabel2];
        }
        
        if (!self.descLabel2)
        {
            self.descLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 24.0, 211.0, 21.0)];
            _descLabel2.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:15.0];
            _descLabel2.textAlignment = NSTextAlignmentLeft;
            _descLabel2.textColor = UIColorFromRGB(0x8ea2b9);
            //_descLabel2.minimumScaleFactor = 0.7;
            [_directionsView addSubview:_descLabel2];
        }
    }
    
    if (_destinations.count > 2)
    {
        if (!self.colorView3) {
            self.colorView3 = [[UIView alloc] initWithFrame:CGRectMake(5.0, 5.0, 40.0, 40.0)];
            _colorView3.backgroundColor = [UIColor clearColor];
            self.compassImage3 = [[UIImageView alloc] initWithFrame:_colorView.bounds];
            _compassImage3.contentMode = UIViewContentModeCenter;
            [_colorView3 addSubview:self.compassImage3];
            [_directionsView addSubview:self.colorView3];

            self.editButton3 = [UIButton buttonWithType:UIButtonTypeSystem];
            _editButton3.frame = _colorView3.bounds;
            [_editButton3 addTarget:self action:@selector(closeDestinationEdit:) forControlEvents:UIControlEventTouchUpInside];
            [_editButton3 setImage:[UIImage imageNamed:@"ic_close"] forState:UIControlStateNormal];
            _editButton3.tintColor = [UIColor whiteColor];
            _editButton3.tag = 2;
        }
        
        if (!self.markerView3)
        {
            self.markerView3 = [[UIView alloc] initWithFrame:CGRectMake(32.0, 32.0, 14.0, 14.0)];
            self.markerView3.backgroundColor = [UIColor clearColor];
            //self.markerView3.layer.cornerRadius = self.markerView3.bounds.size.width / 2.0;
            //self.markerView3.layer.masksToBounds = YES;
            self.markerImage3 = [[UIImageView alloc] initWithFrame:self.markerView3.bounds];
            self.markerImage3.contentMode = UIViewContentModeCenter;
            [self.markerView3 addSubview:self.markerImage3];
        }

        if (!self.distanceLabel3)
        {
            self.distanceLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 7.0, 211.0, 21.0)];
            _distanceLabel3.font = [UIFont fontWithName:@"AvenirNext-Bold" size:18.0];
            _distanceLabel3.textAlignment = NSTextAlignmentLeft;
            _distanceLabel3.textColor = UIColorFromRGB(0xffffff);
            _distanceLabel3.minimumScaleFactor = 0.7;
            [_directionsView addSubview:_distanceLabel3];
        }
        
        if (!self.infoLabel3)
        {
            self.infoLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(60.0 + _distanceLabel3.frame.size.width, 7.0, self.infoLabelWidth, 21.0)];
            _infoLabel3.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:15.0];
            _infoLabel3.textAlignment = NSTextAlignmentRight;
            _infoLabel3.textColor = UIColorFromRGB(0x8ea2b9);
            _infoLabel3.minimumScaleFactor = 0.7;
            [_directionsView addSubview:_infoLabel3];
        }
        
        if (!self.descLabel3)
        {
            self.descLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 24.0, 211.0, 21.0)];
            _descLabel3.font = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:15.0];
            _descLabel3.textAlignment = NSTextAlignmentLeft;
            _descLabel3.textColor = UIColorFromRGB(0x8ea2b9);
            //_descLabel3.minimumScaleFactor = 0.7;
            [_directionsView addSubview:_descLabel3];
        }
    }
}


- (void)setDestinations:(NSArray *)destinations
{
    _destinations = destinations;

    if (_destinations.count == 0 && _editModeActive)
        [self exitEditMode];

    if (_destinations) {
        [self buildUI];
        [self reloadData];
        [self updateLayout:_contentView.frame];
    }
}

- (void)updateMapCenterArrow:(BOOL)arrow
{
    for (int i = 0; i < _destinations.count; i++) {
        OADestination *destination = _destinations[i];
        switch (i) {
            case 0:
                if (arrow)
                {
                    [self.markerImage setImage:[UIImage imageNamed:@"destination_map_center"]];
                    if (!self.markerView.superview)
                        [self.directionsView addSubview:self.markerView];
                }
                else if (destination.parking)
                {
                    [self.markerImage setImage:[UIImage imageNamed:@"destination_parking_place"]];
                    if (!self.markerView.superview)
                        [self.directionsView addSubview:self.markerView];
                }
                else
                {
                    [self.markerView removeFromSuperview];
                }
                break;
            case 1:
                if (arrow)
                {
                    [self.markerImage2 setImage:[UIImage imageNamed:@"destination_map_center"]];
                    if (!self.markerView2.superview)
                        [self.directionsView addSubview:self.markerView2];
                }
                else if (destination.parking)
                {
                    [self.markerImage2 setImage:[UIImage imageNamed:@"destination_parking_place"]];
                    if (!self.markerView2.superview)
                        [self.directionsView addSubview:self.markerView2];
                }
                else
                {
                    [self.markerView2 removeFromSuperview];
                }
                break;
            case 2:
                if (arrow)
                {
                    [self.markerImage3 setImage:[UIImage imageNamed:@"destination_map_center"]];
                    if (!self.markerView3.superview)
                        [self.directionsView addSubview:self.markerView3];
                }
                else if (destination.parking)
                {
                    [self.markerImage3 setImage:[UIImage imageNamed:@"destination_parking_place"]];
                    if (!self.markerView3.superview)
                        [self.directionsView addSubview:self.markerView3];
                }
                else
                {
                    [self.markerView3 removeFromSuperview];
                }
                break;
                
            default:
                break;
        }
    }

}

- (void)updateDistanceLabel:(UILabel *)label destination:(OADestination *)destination
{
    NSString *text = [destination distanceStr:self.currentLocation.latitude longitude:self.currentLocation.longitude];
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:text];
    
    NSUInteger spaceIndex = 0;
    for (NSUInteger i = text.length - 1; i > 0; i--)
        if ([text characterAtIndex:i] == ' ')
        {
            spaceIndex = i;
            break;
        }
    
    NSRange valueRange = NSMakeRange(0, spaceIndex);
    NSRange unitRange = NSMakeRange(spaceIndex, text.length - spaceIndex);
    
    [string addAttribute:NSForegroundColorAttributeName value:self.primaryColor range:valueRange];
    [string addAttribute:NSFontAttributeName value:self.primaryFont range:valueRange];
    [string addAttribute:NSForegroundColorAttributeName value:self.unitsColor range:unitRange];
    [string addAttribute:NSFontAttributeName value:self.unitsFont range:unitRange];
    
    label.attributedText = string;
}

- (void)reloadData
{
    for (int i = 0; i < _destinations.count; i++)
    {
        OADestination *destination = _destinations[i];
        switch (i)
        {
            case 0:
                self.compassImage.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_destination_arrow"] color:destination.color];
                if (_editModeActive) {
                    _compassImage.alpha = 0.0;
                    [_colorView addSubview:self.editButton1];
                } else {
                    _compassImage.alpha = 1.0;
                    [self updateDirection:destination imageView:self.compassImage];
                }
                if (destination.parking)
                {
                    [self.markerImage setImage:[UIImage imageNamed:@"destination_parking_place"]];
                    if (!self.markerView.superview)
                        [self.directionsView addSubview:self.markerView];

                    if (destination.carPickupDate)
                        [OADestinationCell setParkingTimerStr:destination label:self.infoLabel shortText:YES];
                    else
                        self.infoLabel.hidden = YES;

                    self.descLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                    self.descLabel.text = destination.desc;
                }
                else
                {
                    [self.markerView removeFromSuperview];
                    self.infoLabel.hidden = YES;
                    self.descLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                    self.descLabel.text = destination.desc;
                }
                
                [self updateDistanceLabel:self.distanceLabel destination:destination];

                break;
                
            case 1:
                self.compassImage2.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_destination_arrow"] color:destination.color];
                if (_editModeActive) {
                    _compassImage2.alpha = 0.0;
                    [_colorView2 addSubview:self.editButton2];
                } else {
                    _compassImage2.alpha = 1.0;
                    [self updateDirection:destination imageView:self.compassImage2];
                }
                if (destination.parking)
                {
                    [self.markerImage2 setImage:[UIImage imageNamed:@"destination_parking_place"]];
                    if (!self.markerView2.superview)
                        [self.directionsView addSubview:self.markerView2];

                    if (destination.carPickupDate)
                        [OADestinationCell setParkingTimerStr:destination label:self.infoLabel2 shortText:YES];
                    else
                        self.infoLabel2.hidden = YES;

                    self.descLabel2.lineBreakMode = NSLineBreakByTruncatingTail;
                    self.descLabel2.text = destination.desc;
                }
                else
                {
                    [self.markerView2 removeFromSuperview];
                    self.infoLabel2.hidden = YES;
                    self.descLabel2.lineBreakMode = NSLineBreakByTruncatingTail;
                    self.descLabel2.text = destination.desc;
                }
                [self updateDistanceLabel:self.distanceLabel2 destination:destination];

                break;
                
            case 2:
                self.compassImage3.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_destination_arrow"] color:destination.color];
                if (_editModeActive) {
                    _compassImage3.alpha = 0.0;
                    [_colorView3 addSubview:self.editButton3];
                } else {
                    _compassImage3.alpha = 1.0;
                    [self updateDirection:destination imageView:self.compassImage3];
                }
                if (destination.parking)
                {
                    [self.markerImage3 setImage:[UIImage imageNamed:@"destination_parking_place"]];
                    if (!self.markerView3.superview)
                        [self.directionsView addSubview:self.markerView3];
                    
                    if (destination.carPickupDate)
                        [OADestinationCell setParkingTimerStr:destination label:self.infoLabel3 shortText:YES];
                    else
                        self.infoLabel3.hidden = YES;

                    self.descLabel3.lineBreakMode = NSLineBreakByTruncatingTail;
                    self.descLabel3.text = destination.desc;
                }
                else
                {
                    [self.markerView3 removeFromSuperview];
                    self.infoLabel3.hidden = YES;
                    self.descLabel3.lineBreakMode = NSLineBreakByTruncatingTail;
                    self.descLabel3.text = destination.desc;
                }
                [self updateDistanceLabel:self.distanceLabel3 destination:destination];

                break;
                
            default:
                break;
        }
    }
    
    if (!_editModeActive) {
        if (_destinations.count > 1 || kOADestinationEditModeGlobal) {
            [_btnClose setImage:[UIImage imageNamed:@"three_dots"] forState:UIControlStateNormal];
            _editButtonActive = YES;
            
        } else {
            [_btnClose setImage:[UIImage imageNamed:@"ic_close"] forState:UIControlStateNormal];
            _editButtonActive = NO;
        }
    }

}

-(void)exitEditMode
{
    _editModeActive = NO;
    [self hideEditButtons];

    _compassImage.alpha = 1.0;
    _compassImage2.alpha = 1.0;
    _compassImage3.alpha = 1.0;
}

-(void)hideEditButtons
{
    if (_editButton1)
        [_editButton1 removeFromSuperview];
    if (_editButton2)
        [_editButton2 removeFromSuperview];
    if (_editButton3)
        [_editButton3 removeFromSuperview];
}

- (void)updateDirections:(CLLocationCoordinate2D)myLocation direction:(CLLocationDirection)direction
{
    self.currentLocation = myLocation;
    self.currentDirection = direction;

    for (int i = 0; i < _destinations.count; i++)
    {
        OADestination *destination = _destinations[i];
        switch (i)
        {
            case 0:
                [self updateDirection:destination imageView:self.compassImage];
                [self updateDistanceLabel:self.distanceLabel destination:destination];
                [OADestinationCell setParkingTimerStr:destination label:self.infoLabel shortText:YES];
                break;
            case 1:
                [self updateDirection:destination imageView:self.compassImage2];
                [self updateDistanceLabel:self.distanceLabel2 destination:destination];
                [OADestinationCell setParkingTimerStr:destination label:self.infoLabel2 shortText:YES];
                break;
            case 2:
                [self updateDirection:destination imageView:self.compassImage3];
                [self updateDistanceLabel:self.distanceLabel3 destination:destination];
                [OADestinationCell setParkingTimerStr:destination label:self.infoLabel3 shortText:YES];
                break;
                
            default:
                break;
        }
    }
}


- (void)closeDestination:(id)sender
{
    if (_editModeActive)
    {
        _editModeActive = NO;
        [UIView animateWithDuration:.2 animations:^{
            [self hideEditButtons];
            [self reloadData];
        }];
        return;
    }
    
    if (_editButtonActive)
    {
        _editModeActive = YES;
        [UIView animateWithDuration:.2 animations:^{
            [self reloadData];
        }];
        
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (_delegate)
                [_delegate removeDestination:_destinations[0]];
        });
    }
}

- (void)closeDestinationEdit:(id)sender
{
    UIButton *btn = (UIButton *)sender;
    if (_delegate && _destinations.count > btn.tag)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_delegate removeDestination:_destinations[btn.tag]];
        });
    }
}


@end

