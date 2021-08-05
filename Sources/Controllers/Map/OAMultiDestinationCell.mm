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
#import "OAAppSettings.h"
#import "OAColors.h"

#import <OsmAndCore.h>
#import <OsmAndCore/Utilities.h>

@implementation OAMultiDestinationCell
{
    UIFont *_primaryFont;
    UIFont *_unitsFont;
    
    UIColor *_primaryColor;
    UIColor *_unitsColor;
    OAAppSettings *_settings;
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
@synthesize btnOK = _btnOK;

- (instancetype)initWithDestinations:(NSArray *)destinations
{
    self = [super init];
    if (self)
    {
        self.destinations = destinations;
        _settings = [OAAppSettings sharedManager];
    }
    return self;
}

- (OADestination *)destinationByPoint:(CGPoint)point
{
    CGFloat width = _directionsView.bounds.size.width / [self destinationsCount];
    
    for (int i = 0; i < [self destinationsCount]; i++) {
        CGRect clickableFrame = CGRectMake(width * i, 0.0, width, _directionsView.bounds.size.height);
        if (CGRectContainsPoint(clickableFrame, point))
            return _destinations[i];
    }
    
    return nil;
}

- (NSInteger)destinationsCount
{
   return MIN([_settings.activeMarkers get] == TWO_ACTIVE_MARKERS ? 2 : 1, _destinations.count);
}

- (void)updateLayout:(CGRect)frame
{
    CGFloat h = frame.size.height;
    CGFloat closeBtnWidth = 48;
    CGFloat dirViewWidth;

    _btnClose.hidden = NO;
    _closeBtnSeparator.hidden = NO;
    dirViewWidth = frame.size.width - closeBtnWidth;
    _contentView.frame = CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, h);
    
    if (![self.contentView isDirectionRTL])
    {
        _directionsView.frame = CGRectMake(0.0, 0.0, dirViewWidth, h);
        _btnClose.frame = CGRectMake(dirViewWidth, 0.0, closeBtnWidth , h);
        _closeBtnSeparator.frame = CGRectMake(dirViewWidth - 1, 17, 1, 16);
    }
    else
    {
        _directionsView.frame = CGRectMake(closeBtnWidth, 0.0, dirViewWidth, h);
        _btnClose.frame = CGRectMake(0, 0.0, closeBtnWidth , h);
        _closeBtnSeparator.frame = CGRectMake(closeBtnWidth + 1, 17, 1, 16);
    }
    
    switch ([self destinationsCount])
    {
        case 1:
        {
            _backgroundView2.hidden = YES;

            CGFloat textWidth = _directionsView.frame.size.width - 68.0 - (self.buttonOkVisible ? 40.0 : 0.0);
            CGFloat iconLeftOffset = [self.contentView isDirectionRTL] ? dirViewWidth - 50 : 5.0;
            CGFloat textLeftOffset = [self.contentView isDirectionRTL] ? 10.0 : 60.0;
            
            _colorView.frame = CGRectMake(iconLeftOffset, 5.0, 40.0, 40.0);
            _markerView.frame = CGRectMake(_colorView.frame.origin.x + 27.0, _colorView.frame.origin.y + 27.0, 14.0, 14.0);
            _distanceLabel.frame = CGRectMake(textLeftOffset, 7.0, textWidth, 21.0);
            _distanceLabel.textAlignment = NSTextAlignmentNatural;
            _infoLabel.frame = CGRectMake(textLeftOffset + _distanceLabel.frame.size.width, 7.0, self.infoLabelWidth, 21.0);
            _infoLabel.textAlignment = [self.contentView isDirectionRTL] ? NSTextAlignmentLeft : NSTextAlignmentRight;
            _infoLabel.hidden = YES;
            _descLabel.frame = CGRectMake(textLeftOffset, 24.0, textWidth, 21.0);
            _descLabel.hidden = NO;
            _descLabel.textAlignment = NSTextAlignmentNatural;
            
            if (self.buttonOkVisible)
            {
                self.btnOK.frame = CGRectMake(dirViewWidth - 40.0, 0.0, 40.0, h);
                self.btnOK.hidden = NO;
            }
            else
            {
                self.btnOK.hidden = YES;
            }

            if (_btnOK2)
                _btnOK2.hidden = YES;
            if (_btnOK3)
                _btnOK3.hidden = YES;
            
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
            CGFloat icon1LeftOffset = [self.contentView isDirectionRTL] ? dirViewWidth / 2 - 45 : 5;
            CGFloat text1LeftOffset = [self.contentView isDirectionRTL] ? 10 : 55.;
            CGFloat icon2LeftOffset = [self.contentView isDirectionRTL] ? dirViewWidth - 45 : (dirViewWidth / 2) + 5;
            CGFloat text2LeftOffset = [self.contentView isDirectionRTL] ? (dirViewWidth / 2) + 10 : (dirViewWidth / 2) + 50;
            CGFloat backgroundView2LeftOffset = dirViewWidth / 2;
            
            CGFloat buttonViewWidth = closeBtnWidth;
            _backgroundView2.frame = CGRectMake(backgroundView2LeftOffset, 0.0, dirViewWidth / 2 + buttonViewWidth, h);
            _backgroundView2.hidden = NO;
            
            _colorView.frame = CGRectMake(icon1LeftOffset, 5.0, 40.0, 40.0);
            _markerView.frame = CGRectMake(_colorView.frame.origin.x + 27.0, _colorView.frame.origin.y + 27.0, 14.0, 14.0);
            CGFloat textWidth = dirViewWidth / 2.0 - 62.0 - (self.buttonOkVisible ? 40.0 : 0.0);
            if (textWidth > 60.0 + self.infoLabelWidth)
            {
                _distanceLabel.frame = CGRectMake(text1LeftOffset, 7.0, textWidth - self.infoLabelWidth, 21.0);
                _infoLabel.frame = CGRectMake(text1LeftOffset + _distanceLabel.frame.size.width, 7.0, self.infoLabelWidth, 21.0);
                _infoLabel.textAlignment = [self.contentView isDirectionRTL] ? NSTextAlignmentLeft : NSTextAlignmentRight;
                _infoLabel.hidden = NO;
                _descLabel.frame = CGRectMake(text1LeftOffset, 24.0, textWidth, 21.0);
                _descLabel.hidden = NO;
            }
            else if (textWidth > 80.0)
            {
                _distanceLabel.frame = CGRectMake(text1LeftOffset, 7.0, textWidth, 21.0);
                _descLabel.frame = CGRectMake(text1LeftOffset, 24.0, textWidth, 21.0);
                _infoLabel.hidden = YES;
                _descLabel.hidden = NO;
            }
            else
            {
                _distanceLabel.frame = CGRectMake(text1LeftOffset, 15.0, textWidth, 21.0);
                _infoLabel.hidden = YES;
                _descLabel.hidden = YES;
            }
            _distanceLabel.textAlignment = NSTextAlignmentNatural;
            
            if (self.buttonOkVisible)
            {
                self.btnOK.frame = CGRectMake(text1LeftOffset + textWidth, 0.0, 40.0, h);
                self.btnOK.hidden = NO;
            }
            else
            {
                self.btnOK.hidden = YES;
            }
            
            textWidth = dirViewWidth / 2.0 - 62.0 - (self.buttonOkVisible2 ? 40.0 : 0.0);

            _colorView2.frame = CGRectMake(icon2LeftOffset, 5.0, 40.0, 40.0);
            _colorView2.hidden = NO;
            _markerView2.frame = CGRectMake(_colorView2.frame.origin.x + 27.0, _colorView2.frame.origin.y + 27.0, 14.0, 14.0);
            _markerView2.hidden = NO;
            
            if (textWidth > 60.0 + self.infoLabelWidth)
            {
                _distanceLabel2.frame = CGRectMake(text2LeftOffset, 7.0, textWidth - self.infoLabelWidth, 21.0);
                _distanceLabel2.hidden = NO;
                _infoLabel2.frame = CGRectMake(_distanceLabel2.frame.origin.x + _distanceLabel2.frame.size.width, 7.0, self.infoLabelWidth, 21.0);
                _infoLabel2.textAlignment = [self.contentView isDirectionRTL] ? NSTextAlignmentLeft : NSTextAlignmentRight;;
                _infoLabel2.hidden = NO;
                _descLabel2.frame = CGRectMake(text2LeftOffset, 24.0, textWidth, 21.0);
                _descLabel2.hidden = NO;
            }
            else if (textWidth > 80.0)
            {
                _distanceLabel2.frame = CGRectMake(text2LeftOffset, 7.0, textWidth, 21.0);
                _distanceLabel2.hidden = NO;
                _descLabel2.frame = CGRectMake(text2LeftOffset, 24.0, textWidth, 21.0);
                _infoLabel2.hidden = YES;
                _descLabel2.hidden = NO;
            }
            else
            {
                _distanceLabel2.frame = CGRectMake(text2LeftOffset, 15.0, textWidth, 21.0);
                _distanceLabel2.hidden = NO;
                _infoLabel2.hidden = YES;
                _descLabel2.hidden = YES;
            }
            _distanceLabel2.textAlignment = NSTextAlignmentNatural;
            
            if (self.buttonOkVisible2)
            {
                self.btnOK2.frame = CGRectMake(_colorView2.frame.origin.x + 62.0 + textWidth, 0.0, 40.0, h);
                self.btnOK2.hidden = NO;
            }
            else
            {
                self.btnOK2.hidden = YES;
            }
            
            if (_btnOK3)
                _btnOK3.hidden = YES;
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
            
            _backgroundView2.frame = CGRectMake(dirViewWidth / 3, 0.0, dirViewWidth / 3, h);
            _backgroundView2.hidden = NO;
            
            if (width >= 160) {
                CGFloat textWidth = width - 60.0;
                _colorView.frame = CGRectMake(5.0, 5.0, 40.0, 40.0);
                _markerView.frame = CGRectMake(_colorView.frame.origin.x + 27.0, _colorView.frame.origin.y + 27.0, 14.0, 14.0);
                _distanceLabel.frame = CGRectMake(55.0, 7.0, textWidth, 21.0);
                _descLabel.frame = CGRectMake(55.0, 24.0, textWidth, 21.0);
                _distanceLabel.textAlignment = NSTextAlignmentNatural;
                _descLabel.hidden = NO;
                _infoLabel.hidden = YES;
                
                _colorView2.frame = CGRectMake(width, 5.0, 40.0, 40.0);
                _colorView2.hidden = NO;
                _markerView2.frame = CGRectMake(_colorView2.frame.origin.x + 27.0, _colorView2.frame.origin.y + 27.0, 14.0, 14.0);
                _markerView2.hidden = NO;
                _distanceLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 7.0, textWidth, 21.0);
                _distanceLabel2.textAlignment = NSTextAlignmentNatural;
                _distanceLabel2.hidden = NO;
                _descLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 24.0, textWidth, 21.0);
                _descLabel2.hidden = NO;
                _infoLabel2.hidden = YES;
                
                _colorView3.frame = CGRectMake(width * 2.0, 5.0, 40.0, 40.0);
                _colorView3.hidden = NO;
                _markerView3.frame = CGRectMake(_colorView3.frame.origin.x + 27.0, _colorView2.frame.origin.y + 27.0, 14.0, 14.0);
                _markerView3.hidden = NO;
                _distanceLabel3.frame = CGRectMake(_colorView3.frame.origin.x + 50.0, 7.0, textWidth, 21.0);
                _distanceLabel3.textAlignment = NSTextAlignmentNatural;
                _distanceLabel3.hidden = NO;
                _descLabel3.frame = CGRectMake(_colorView3.frame.origin.x + 50.0, 24.0, textWidth, 21.0);
                _descLabel3.hidden = NO;
                _infoLabel3.hidden = YES;
            }
            else if (width >= 140)
            {
                CGFloat textWidth = width - 60.0;
                _colorView.frame = CGRectMake(5.0, 5.0, 40.0, 40.0);
                _markerView.frame = CGRectMake(_colorView.frame.origin.x + 27.0, _colorView.frame.origin.y + 27.0, 14.0, 14.0);
                _distanceLabel.frame = CGRectMake(55.0, 15.0, textWidth, 21.0);
                _distanceLabel.textAlignment = NSTextAlignmentNatural;
                _descLabel.hidden = YES;
                _infoLabel.hidden = YES;
                
                _colorView2.frame = CGRectMake(width, 5.0, 40.0, 40.0);
                _colorView2.hidden = NO;
                _markerView2.frame = CGRectMake(_colorView2.frame.origin.x + 27.0, _colorView2.frame.origin.y + 27.0, 14.0, 14.0);
                _markerView2.hidden = NO;
                _distanceLabel2.frame = CGRectMake(_colorView2.frame.origin.x + 50.0, 15.0, textWidth, 21.0);
                _distanceLabel2.textAlignment = NSTextAlignmentNatural;
                _distanceLabel2.hidden = NO;
                _descLabel2.hidden = YES;
                _infoLabel2.hidden = YES;
                
                _colorView3.frame = CGRectMake(width * 2.0, 5.0, 40.0, 40.0);
                _colorView3.hidden = NO;
                _markerView3.frame = CGRectMake(_colorView3.frame.origin.x + 27.0, _colorView3.frame.origin.y + 27.0, 14.0, 14.0);
                _markerView3.hidden = NO;
                _distanceLabel3.frame = CGRectMake(_colorView3.frame.origin.x + 50.0, 15.0, textWidth, 21.0);
                _distanceLabel3.textAlignment = NSTextAlignmentNatural;
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
        self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, 50.0)];
        _contentView.backgroundColor = UIColorFromRGB(markers_header_light_blue);
        _contentView.opaque = YES;
    }
    
    if (!self.directionsView)
    {
        self.directionsView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth - 41.0, 50.0)];
        _directionsView.backgroundColor = UIColorFromRGB(markers_header_light_blue);
        _directionsView.opaque = YES;
        [_contentView addSubview:self.directionsView];
    }
    
    if (!self.btnClose)
    {
        self.btnClose = [UIButton buttonWithType:UIButtonTypeSystem];
        _btnClose.frame = CGRectMake(280.0, 0.0, 40.0, 50.0);
        _btnClose.backgroundColor = UIColor.clearColor;
        _btnClose.opaque = YES;
        _btnClose.tintColor = UIColorFromRGB(0x5081a6);
        [_btnClose setTitle:@"" forState:UIControlStateNormal];
        [_btnClose setImage:[UIImage imageNamed:@"ic_arrow_open"] forState:UIControlStateNormal];
        [_btnClose addTarget:self action:@selector(openHideDestinationsView:) forControlEvents:UIControlEventTouchUpInside];
        
        [_contentView addSubview:self.btnClose];
    }
    
    if (!self.closeBtnSeparator)
    {
        self.closeBtnSeparator = [[UIView alloc] initWithFrame:CGRectMake(280.0, 0.0, 1, 50.0)];
        _closeBtnSeparator.backgroundColor = UIColorFromRGB(0x5081a6);
        _closeBtnSeparator.opaque = YES;
        [_contentView addSubview:self.closeBtnSeparator];
    }
    
    if (!self.btnOK)
    {
        self.btnOK = [UIButton buttonWithType:UIButtonTypeSystem];
        _btnOK.frame = CGRectMake(DeviceScreenWidth - 40.0, 0.0, 40.0, 50.0);
        _btnOK.backgroundColor = UIColorFromRGB(markers_header_light_blue);
        _btnOK.opaque = YES;
        _btnOK.tintColor = UIColorFromRGB(0xffffff);
        [_btnOK setTitle:@"" forState:UIControlStateNormal];
        [_btnOK setImage:[UIImage imageNamed:@"ic_trip_visitedpoint"] forState:UIControlStateNormal];
        [_btnOK addTarget:self action:@selector(buttonOkClicked:) forControlEvents:UIControlEventTouchUpInside];
        _btnOK.tag = 0;
        _btnOK.hidden = YES;
        [_contentView addSubview:self.btnOK];
    }
    
    if (!self.colorView)
    {
        self.colorView = [[UIView alloc] initWithFrame:CGRectMake(5.0, 5.0, 40.0, 40.0)];
        _colorView.backgroundColor = [UIColor clearColor];
        self.compassImage = [[UIImageView alloc] initWithFrame:_colorView.bounds];
        _compassImage.contentMode = UIViewContentModeCenter;
        [_colorView addSubview:self.compassImage];
        [_directionsView addSubview:self.colorView];
    }
    
    if (!self.markerView)
    {
        self.markerView = [[UIView alloc] initWithFrame:CGRectMake(32.0, 32.0, 14.0, 14.0)];
        self.markerView.backgroundColor = [UIColor clearColor];
        self.markerImage = [[UIImageView alloc] initWithFrame:self.markerView.bounds];
        self.markerImage.contentMode = UIViewContentModeCenter;
        [self.markerView addSubview:self.markerImage];
    }
    
    if (!self.distanceLabel)
    {
        self.distanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 7.0, 211.0, 21.0)];
        _distanceLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
        _distanceLabel.textAlignment = NSTextAlignmentLeft;
        _distanceLabel.textColor = UIColorFromRGB(0xffffff);
        _distanceLabel.minimumScaleFactor = 0.7;
        [_directionsView addSubview:_distanceLabel];
    }
    
    if (!self.infoLabel)
    {
        self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0 + _distanceLabel.frame.size.width, 7.0, self.infoLabelWidth, 21.0)];
        _infoLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
        _infoLabel.textAlignment = NSTextAlignmentRight;
        _infoLabel.textColor = UIColorFromRGB(0x8ea2b9);
        _infoLabel.minimumScaleFactor = 0.7;
        [_directionsView addSubview:_infoLabel];
    }
    
    if (!self.descLabel)
    {
        self.descLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 24.0, 211.0, 21.0)];
        _descLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
        _descLabel.textAlignment = NSTextAlignmentLeft;
        _descLabel.textColor = UIColorFromRGB(0x8ea2b9);
        [_directionsView addSubview:_descLabel];
    }
    
    if ([self destinationsCount] > 1)
    {
        if (!self.backgroundView2)
        {
            CGFloat halfWidth = (DeviceScreenWidth - 40) / 2;
            self.backgroundView2 = [[UIView alloc] initWithFrame:CGRectMake(halfWidth, 0.0, halfWidth, 50.0)];
            _backgroundView2.backgroundColor = UIColorFromRGB(markers_header_dark_blue);
            _backgroundView2.opaque = YES;
            _backgroundView2.hidden = NO;
            [_directionsView addSubview:self.backgroundView2];
        }
    
        if (!self.btnOK2)
        {
            self.btnOK2 = [UIButton buttonWithType:UIButtonTypeSystem];
            _btnOK2.frame = CGRectMake(DeviceScreenWidth - 40.0, 0.0, 40.0, 50.0);
            _btnOK2.backgroundColor = UIColorFromRGB(markers_header_light_blue);
            _btnOK2.opaque = YES;
            _btnOK2.tintColor = UIColorFromRGB(0xffffff);
            [_btnOK2 setTitle:@"" forState:UIControlStateNormal];
            [_btnOK2 setImage:[UIImage imageNamed:@"ic_trip_visitedpoint"] forState:UIControlStateNormal];
            [_btnOK2 addTarget:self action:@selector(buttonOkClicked:) forControlEvents:UIControlEventTouchUpInside];
            _btnOK2.tag = 1;
            _btnOK2.hidden = YES;
            [_contentView addSubview:self.btnOK2];
        }
        
        if (!self.colorView2)
        {
            self.colorView2 = [[UIView alloc] initWithFrame:CGRectMake(5.0, 5.0, 40.0, 40.0)];
            _colorView2.backgroundColor = [UIColor clearColor];
            self.compassImage2 = [[UIImageView alloc] initWithFrame:_colorView.bounds];
            _compassImage2.contentMode = UIViewContentModeCenter;
            [_colorView2 addSubview:self.compassImage2];
            [_directionsView addSubview:self.colorView2];
        }
        
        if (!self.markerView2)
        {
            self.markerView2 = [[UIView alloc] initWithFrame:CGRectMake(32.0, 32.0, 14.0, 14.0)];
            self.markerView2.backgroundColor = [UIColor clearColor];
            self.markerImage2 = [[UIImageView alloc] initWithFrame:self.markerView2.bounds];
            self.markerImage2.contentMode = UIViewContentModeCenter;
            [self.markerView2 addSubview:self.markerImage2];
        }
        
        if (!self.distanceLabel2)
        {
            self.distanceLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 7.0, 211.0, 21.0)];
            _distanceLabel2.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
            _distanceLabel2.textAlignment = NSTextAlignmentLeft;
            _distanceLabel2.textColor = UIColorFromRGB(0xffffff);
            _distanceLabel2.minimumScaleFactor = 0.7;
            [_directionsView addSubview:_distanceLabel2];
        }
        
        if (!self.infoLabel2)
        {
            self.infoLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(60.0 + _distanceLabel2.frame.size.width, 7.0, self.infoLabelWidth, 21.0)];
            _infoLabel2.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
            _infoLabel2.textAlignment = NSTextAlignmentRight;
            _infoLabel2.textColor = UIColorFromRGB(0x8ea2b9);
            _infoLabel2.minimumScaleFactor = 0.7;
            [_directionsView addSubview:_infoLabel2];
        }
        
        if (!self.descLabel2)
        {
            self.descLabel2 = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 24.0, 211.0, 21.0)];
            _descLabel2.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
            _descLabel2.textAlignment = NSTextAlignmentLeft;
            _descLabel2.textColor = UIColorFromRGB(0x8ea2b9);
            [_directionsView addSubview:_descLabel2];
        }
    }
    
    if ([self destinationsCount] > 2)
    {
        if (!self.btnOK3)
        {
            self.btnOK3 = [UIButton buttonWithType:UIButtonTypeSystem];
            _btnOK3.frame = CGRectMake(DeviceScreenWidth - 40.0, 0.0, 40.0, 50.0);
            _btnOK3.backgroundColor = UIColorFromRGB(markers_header_light_blue);
            _btnOK3.opaque = YES;
            _btnOK3.tintColor = UIColorFromRGB(0xffffff);
            [_btnOK3 setTitle:@"" forState:UIControlStateNormal];
            [_btnOK3 setImage:[UIImage imageNamed:@"ic_trip_visitedpoint"] forState:UIControlStateNormal];
            [_btnOK3 addTarget:self action:@selector(buttonOkClicked:) forControlEvents:UIControlEventTouchUpInside];
            _btnOK3.tag = 2;
            _btnOK3.hidden = YES;
            [_contentView addSubview:self.btnOK3];
        }
        
        if (!self.colorView3) {
            self.colorView3 = [[UIView alloc] initWithFrame:CGRectMake(5.0, 5.0, 40.0, 40.0)];
            _colorView3.backgroundColor = [UIColor clearColor];
            self.compassImage3 = [[UIImageView alloc] initWithFrame:_colorView.bounds];
            _compassImage3.contentMode = UIViewContentModeCenter;
            [_colorView3 addSubview:self.compassImage3];
            [_directionsView addSubview:self.colorView3];
        }
        
        if (!self.markerView3)
        {
            self.markerView3 = [[UIView alloc] initWithFrame:CGRectMake(32.0, 32.0, 14.0, 14.0)];
            self.markerView3.backgroundColor = [UIColor clearColor];
            self.markerImage3 = [[UIImageView alloc] initWithFrame:self.markerView3.bounds];
            self.markerImage3.contentMode = UIViewContentModeCenter;
            [self.markerView3 addSubview:self.markerImage3];
        }
        
        if (!self.distanceLabel3)
        {
            self.distanceLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 7.0, 211.0, 21.0)];
            _distanceLabel3.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
            _distanceLabel3.textAlignment = NSTextAlignmentLeft;
            _distanceLabel3.textColor = UIColorFromRGB(0xffffff);
            _distanceLabel3.minimumScaleFactor = 0.7;
            [_directionsView addSubview:_distanceLabel3];
        }
        
        if (!self.infoLabel3)
        {
            self.infoLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(60.0 + _distanceLabel3.frame.size.width, 7.0, self.infoLabelWidth, 21.0)];
            _infoLabel3.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
            _infoLabel3.textAlignment = NSTextAlignmentRight;
            _infoLabel3.textColor = UIColorFromRGB(0x8ea2b9);
            _infoLabel3.minimumScaleFactor = 0.7;
            [_directionsView addSubview:_infoLabel3];
        }
        
        if (!self.descLabel3)
        {
            self.descLabel3 = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 24.0, 211.0, 21.0)];
            _descLabel3.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
            _descLabel3.textAlignment = NSTextAlignmentLeft;
            _descLabel3.textColor = UIColorFromRGB(0x8ea2b9);
            [_directionsView addSubview:_descLabel3];
        }
    }
}


- (void)setDestinations:(NSArray *)destinations
{
    _destinations = destinations;

    if (_destinations) {
        [self buildUI];
        [self reloadData];
        [self updateLayout:_contentView.frame];
    }
}

- (void)updateMapCenterArrow:(BOOL)arrow
{
    for (int i = 0; i < [self destinationsCount]; i++) {
        OADestination *destination = _destinations[i];
        switch (i) {
            case 0:
                if (arrow)
                {
                    [self.markerImage setImage:[UIImage imageNamed:@"destination_map_center"]];
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
    for (int i = 0; i < [self destinationsCount]; i++)
    {
        OADestination *destination = _destinations[i];
        switch (i)
        {
            case 0:
                self.compassImage.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_destination_arrow"] color:destination.color];
                _compassImage.alpha = 1.0;
                [self updateDirection:destination imageView:self.compassImage];
                
                [self.markerView removeFromSuperview];
                self.infoLabel.hidden = YES;
                self.descLabel.lineBreakMode = NSLineBreakByTruncatingTail;
                self.descLabel.text = destination.desc;
                
                [self updateDistanceLabel:self.distanceLabel destination:destination];

                break;
                
            case 1:
                self.compassImage2.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_destination_arrow"] color:destination.color];

                _compassImage2.alpha = 1.0;
                [self updateDirection:destination imageView:self.compassImage2];
                [self.markerView2 removeFromSuperview];
                self.infoLabel2.hidden = YES;
                self.descLabel2.lineBreakMode = NSLineBreakByTruncatingTail;
                self.descLabel2.text = destination.desc;
                [self updateDistanceLabel:self.distanceLabel2 destination:destination];

                break;
                
            case 2:
                self.compassImage3.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_destination_arrow"] color:destination.color];

                _compassImage3.alpha = 1.0;
                [self updateDirection:destination imageView:self.compassImage3];
                
                [self.markerView3 removeFromSuperview];
                self.infoLabel3.hidden = YES;
                self.descLabel3.lineBreakMode = NSLineBreakByTruncatingTail;
                self.descLabel3.text = destination.desc;
                
                [self updateDistanceLabel:self.distanceLabel3 destination:destination];

                break;
                
            default:
                break;
        }
    }
}

- (void)updateDirections:(CLLocationCoordinate2D)myLocation direction:(CLLocationDirection)direction
{
    if (!isnan(myLocation.latitude))
    {
        self.currentLocation = myLocation;
        self.currentDirection = direction;
    }

    for (int i = 0; i < [self destinationsCount]; i++)
    {
        OADestination *destination = _destinations[i];
        switch (i)
        {
            case 0:
                [self updateDirection:destination imageView:self.compassImage];
                [self updateDistanceLabel:self.distanceLabel destination:destination];
                [self updateOkButton:destination];
                break;
            case 1:
                [self updateDirection:destination imageView:self.compassImage2];
                [self updateDistanceLabel:self.distanceLabel2 destination:destination];
                [self updateOkButton2:destination];
                break;
            case 2:
                [self updateDirection:destination imageView:self.compassImage3];
                [self updateDistanceLabel:self.distanceLabel3 destination:destination];
                [self updateOkButton3:destination];
                break;
                
            default:
                break;
        }
    }
}

-(void)setButtonOkVisible2:(BOOL)buttonOkVisible
{
    if (_buttonOkVisible2 == buttonOkVisible)
        return;
    
    _buttonOkVisible2 = buttonOkVisible;
    [self updateLayout:_contentView.frame];
}

-(void)setButtonOkVisible3:(BOOL)buttonOkVisible
{
    if (_buttonOkVisible3 == buttonOkVisible)
        return;
    
    _buttonOkVisible3 = buttonOkVisible;
    [self updateLayout:_contentView.frame];
}

- (void)updateOkButton2:(OADestination *)destination
{
    if (!self.mapCenterArrow)
    {
        double distance = OsmAnd::Utilities::distance(self.currentLocation.longitude, self.currentLocation.latitude, destination.longitude, destination.latitude);
        self.buttonOkVisible2 = distance < 20.0;
    }
}

- (void)updateOkButton3:(OADestination *)destination
{
    if (!self.mapCenterArrow)
    {
        double distance = OsmAnd::Utilities::distance(self.currentLocation.longitude, self.currentLocation.latitude, destination.longitude, destination.latitude);
        self.buttonOkVisible3 = distance < 20.0;
    }
}

- (void)buttonOkClicked:(id)sender
{
    UIButton *btn = sender;
    
    if (self.delegate)
        [self.delegate markAsVisited:_destinations[btn.tag]];
}

- (void)closeDestination:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_delegate)
            [_delegate removeDestination:_destinations[0]];
    });
}


- (void)openHideDestinationsView:(id)sender
{
    if (self.delegate)
        [_delegate openHideDestinationCardsView:sender];
}

@end

