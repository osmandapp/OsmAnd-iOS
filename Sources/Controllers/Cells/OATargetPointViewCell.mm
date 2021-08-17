//
//  OATargetPointViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 12/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATargetPointViewCell.h"
#import "OATargetPoint.h"
#import "OADestination.h"
#import "OADestinationCell.h"
#import "OAGPXRouter.h"
#import "OAGPXRouteDocument.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAFavoriteItem.h"
#import "OATransportStop.h"
#import "OAPlugin.h"
#import "OAParkingPositionPlugin.h"
#import "OAPOI.h"

@implementation OATargetPointViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)setTargetPoint:(OATargetPoint *)targetPoint
{
    _targetPoint = targetPoint;
    [self applyTargetPoint];
}

- (void)applyTargetPoint
{
    if (_targetPoint.type == OATargetParking)
    {
        _iconView.image = [UIImage imageNamed:@"map_parking_pin"];
        [_titleView setText:OALocalizedString(@"parking_marker")];
        [self updateDescriptionView];
        OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *)[OAPlugin getPlugin:OAParkingPositionPlugin.class];
        if (plugin && plugin.getParkingType)
            [OADestinationCell setParkingTimerStr:[NSDate dateWithTimeIntervalSince1970:plugin.getParkingTime / 1000] label:self.descriptionView shortText:NO];
    }
    else
    {
        if ([_targetPoint.targetObj isKindOfClass:OAFavoriteItem.class])
            _iconView.image = [((OAFavoriteItem *)_targetPoint.targetObj) getCompositeIcon];
        else if ([_targetPoint.targetObj isKindOfClass:OATransportStop.class])
            _iconView.image = ((OATransportStop *)_targetPoint.targetObj).poi.icon;
        else
            _iconView.image = _targetPoint.icon;
        
        NSString *t;
        if (_targetPoint.titleSecond)
        {
            t = [NSString stringWithFormat:@"%@ - %@", _targetPoint.title, _targetPoint.titleSecond];
            CGFloat h = [OAUtilities calculateTextBounds:t width:_titleView.bounds.size.width font:_titleView.font].height;
            if (h > 41.0)
            {
                t = _targetPoint.title;
            }
            else if (h > 21.0)
            {
                t = [NSString stringWithFormat:@"%@\n%@", _targetPoint.title, _targetPoint.titleSecond];
                h = [OAUtilities calculateTextBounds:t width:_titleView.bounds.size.width font:_titleView.font].height;
                if (h > 41.0)
                    t = _targetPoint.title;
            }
        }
        else
        {
            t = _targetPoint.title;
        }
        
        [_titleView setText:t];
        [self updateDescriptionView];
    }
}

- (void)updateDescriptionView
{
    NSString *addressStr = _targetPoint.titleAddress;
    if (_targetPoint.ctrlAttrTypeStr)
    {
        [_descriptionView setAttributedText:_targetPoint.ctrlAttrTypeStr];
        [_descriptionView setTextColor:UIColorFromRGB(0x969696)];
        return;
    }
    else if (_targetPoint.ctrlTypeStr)
    {
        NSString *typeStr = _targetPoint.ctrlTypeStr;
        if (_targetPoint.titleAddress.length > 0 && ![_targetPoint.title hasPrefix:_targetPoint.titleAddress])
        {
            typeStr = [NSString stringWithFormat:@"%@: %@", typeStr, _targetPoint.titleAddress];
        }
        addressStr = typeStr;
    }
    [_descriptionView setText:addressStr];
    [_descriptionView setTextColor:UIColorFromRGB(0x969696)];
}

@end
