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
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAFavoriteItem.h"
#import "OATransportStop.h"
#import "OAPlugin.h"
#import "OAParkingPositionPlugin.h"
#import "OAPOI.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"
#import "OARouteKey.h"

@implementation OATargetPointViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
    self.descriptionView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
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
        [_titleView setText:OALocalizedString(@"map_widget_parking")];
        [self updateDescriptionView];
        OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *)[OAPlugin getPlugin:OAParkingPositionPlugin.class];
        if (plugin && plugin.getParkingType)
            [OADestinationCell setParkingTimerStr:[NSDate dateWithTimeIntervalSince1970:plugin.getParkingTime / 1000] creationDate:[NSDate dateWithTimeIntervalSince1970:plugin.getStartParkingTime / 1000] label:self.descriptionView shortText:NO];
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
    NSString *descriptionStr = _targetPoint.titleAddress;
    if (_targetPoint.ctrlAttrTypeStr)
    {
        [_descriptionView setAttributedText:_targetPoint.ctrlAttrTypeStr];
        [_descriptionView setTextColor:[UIColor colorNamed:ACColorNameTextColorSecondary]];
        return;
    }
    else if (_targetPoint.ctrlTypeStr)
    {
        NSString *typeStr = _targetPoint.ctrlTypeStr;
        if (_targetPoint.titleAddress.length > 0 && ![_targetPoint.title hasPrefix:_targetPoint.titleAddress])
        {
            typeStr = [NSString stringWithFormat:@"%@: %@", typeStr, _targetPoint.titleAddress];
        }
        descriptionStr = typeStr;
    }
    else if (_targetPoint.type == OATargetNetworkGPX)
    {
        OARouteKey *key = (OARouteKey *)_targetPoint.targetObj;
        if (key)
        {
            descriptionStr = [NSString stringWithFormat:@"%@ - %@", OALocalizedString(@"layer_route"), OALocalizedString([self tagToActivity:key.routeKey.getTag().toNSString()])];
        }
    }
    [_descriptionView setText:descriptionStr];
    [_descriptionView setTextColor:[UIColor colorNamed:ACColorNameTextColorSecondary]];
}

- (NSString *)tagToActivity:(NSString *)tag
{
    if ([tag isEqualToString:@"bicycle"])
        return @"activity_type_cycling_name";
    else if ([tag isEqualToString:@"mtb"])
        return @"activity_type_mountainbike_name";
    else if ([tag isEqualToString:@"horse"])
        return @"activity_type_riding_name";
    return @"activity_type_hiking_name";
}

@end
