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
#import "OAPluginsHelper.h"
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
        OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *)[OAPluginsHelper getPlugin:OAParkingPositionPlugin.class];
        if (plugin && plugin.getParkingType)
            [OADestinationCell setParkingTimerStr:[NSDate dateWithTimeIntervalSince1970:plugin.getParkingTime / 1000] creationDate:[NSDate dateWithTimeIntervalSince1970:plugin.getStartParkingTime / 1000] label:self.descriptionView shortText:NO];
    }
    else
    {
        UIImage *image;
        if ([_targetPoint.targetObj isKindOfClass:OAFavoriteItem.class])
            image = [((OAFavoriteItem *)_targetPoint.targetObj) getCompositeIcon];
        else if ([_targetPoint.targetObj isKindOfClass:OATransportStop.class])
            image = ((OATransportStop *)_targetPoint.targetObj).poi.icon;
        else
            image = _targetPoint.icon;
        
        _iconView.image = image;
        
        if ([_targetPoint.targetObj isKindOfClass:OAMapObject.class])
            _iconView.tintColor = [UIColor colorNamed:ACColorNameIconColorSelected];
        
        NSString *title;
        if (_targetPoint.titleSecond)
        {
            title = [NSString stringWithFormat:@"%@ - %@", _targetPoint.title, _targetPoint.titleSecond];
            CGFloat h = [OAUtilities calculateTextBounds:title width:_titleView.bounds.size.width font:_titleView.font].height;
            if (h > 41.0)
            {
                title = _targetPoint.title;
            }
            else if (h > 21.0)
            {
                title = [NSString stringWithFormat:@"%@\n%@", _targetPoint.title, _targetPoint.titleSecond];
                h = [OAUtilities calculateTextBounds:title width:_titleView.bounds.size.width font:_titleView.font].height;
                if (h > 41.0)
                    title = _targetPoint.title;
            }
        }
        else if (_targetPoint.type == OATargetNetworkGPX)
        {
            OARouteKey *routeKey = (OARouteKey *)_targetPoint.targetObj;
            NSString *localizedTitle = routeKey ? routeKey.localizedTitle : @"";
            title = localizedTitle.length > 0 ? localizedTitle : _targetPoint.title;
        }
        else
        {
            title = _targetPoint.title;
        }
        
        [_titleView setText:title];
        [self updateDescriptionView];
    }
}

- (void)updateDescriptionView
{
    OATargetPoint *targetPoint = self.targetPoint;
    if (!targetPoint)
    {
        self.descriptionView.text = @"";
        return;
    }

    self.descriptionView.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];

    if (targetPoint.ctrlAttrTypeStr)
    {
        self.descriptionView.attributedText = targetPoint.ctrlAttrTypeStr;
        return;
    }

    if (targetPoint.ctrlTypeStr)
    {
        NSString *baseType = targetPoint.ctrlTypeStr;
        __weak __typeof(self) weakSelf = self;

        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), ^{
            [targetPoint initAddressIfNeeded];

            NSString *finalText = [weakSelf buildTypeDescriptionWithTarget:targetPoint
                                                                  baseType:baseType];

            dispatch_async(dispatch_get_main_queue(), ^{
                __strong __typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf || strongSelf.targetPoint != targetPoint)
                    return;
                
                strongSelf.descriptionView.text = finalText;
            });
        });
        return;
    }

    if (targetPoint.type == OATargetNetworkGPX)
    {
        OARouteKey *key = (OARouteKey *)targetPoint.targetObj;
        NSString *activityTitle = key.getActivityTypeTitle;
        
        NSString *text = activityTitle
            ? [NSString stringWithFormat:@"%@ - %@", OALocalizedString(@"layer_route"), activityTitle]
            : OALocalizedString(@"layer_route");
            
        self.descriptionView.text = text;
        return;
    }

    self.descriptionView.text = targetPoint.titleAddress ?: @"";
}

- (NSString *)buildTypeDescriptionWithTarget:(OATargetPoint *)targetPoint
                                    baseType:(NSString *)baseType
{
    NSString *typeStr = baseType;

    if (targetPoint.titleAddress.length > 0 && ![targetPoint.title hasPrefix:targetPoint.titleAddress])
    {
        if (typeStr.length > 0)
            typeStr = [NSString stringWithFormat:@"%@ • %@", typeStr, targetPoint.titleAddress];
        else
            typeStr = targetPoint.titleAddress;
    }

    return typeStr;
}

@end
