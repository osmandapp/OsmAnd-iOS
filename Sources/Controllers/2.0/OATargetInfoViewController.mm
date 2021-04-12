//
//  OATargetInfoViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"
#import "OsmAndApp.h"
#import "OAUtilities.h"
#import "OATargetInfoViewCell.h"
#import "OATargetInfoCollapsableViewCell.h"
#import "OATargetInfoCollapsableCoordinatesViewCell.h"
#import "OAWebViewCell.h"
#import "OAEditDescriptionViewController.h"
#import "Localization.h"
#import "OAPOIHelper.h"
#import "OAPOI.h"
#import "OACollapsableWikiView.h"
#import "OATransportStopRoute.h"
#import "OACollapsableTransportStopRoutesView.h"
#import "OAAppSettings.h"
#import "OAPointDescription.h"
#import "OACollapsableCoordinatesView.h"
#import "OAIAPHelper.h"
#import "OAPluginPopupViewController.h"
#import "OAWikiArticleHelper.h"
#import "OAColors.h"

#include <OsmAndCore/Utilities.h>

#define kWikiLink @".wikipedia.org/w"
#define kWhatsAppLink @"https://wa.me/%@"
#define kViberLink @"viber://contact?number=%@"
#define kSkypeLink @"skype:%@"
#define kMailLink @"mailto:%@"
#define kViewPortHtml @"<header><meta name='viewport' content='width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no'></header>"

@interface OATargetInfoViewController()

@end

@implementation OATargetInfoViewController
{
    OAImageCardsHelper *_cardsHelper;
    NSMutableArray<OARowInfo *> *_rows;
    CGFloat _contentHeight;
    UIColor *_contentColor;
    NSArray<OAPOI *> *_nearestWiki;
    BOOL _hasOsmWiki;
    CGFloat _calculatedWidth;
}

- (BOOL) needCoords
{
    return YES;
}

- (BOOL) supportMapInteraction
{
    return YES;
}

- (BOOL) supportsForceClose
{
    return YES;
}

- (BOOL)shouldEnterContextModeManually
{
    return YES;
}

+ (UIImage *) getIcon:(NSString *)fileName
{
    UIImage *img = nil;
    if ([fileName hasPrefix:@"mx_"])
    {
        img = [UIImage imageNamed:[OAUtilities drawablePath:fileName]];
        if (img)
        {
            img = [OAUtilities applyScaleFactorToImage:img];
        }
    }
    else
    {
        img = [UIImage imageNamed:fileName];
    }
    
    return img;
}

- (void) buildTopRows:(NSMutableArray<OARowInfo *> *)rows
{
    if (self.routes.count > 0)
    {
        NSArray<OATransportStopRoute *> *localTransportRoutes = [self getLocalTransportStopRoutes];
        NSArray<OATransportStopRoute *> *nearbyTransportRoutes = [self getNearbyTransportStopRoutes];
        if (localTransportRoutes.count > 0)
        {
            OARowInfo *rowInfo = [[OARowInfo alloc] initWithKey:nil icon:nil textPrefix:nil text:OALocalizedString(@"transport_routes") textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO];
            rowInfo.collapsable = YES;
            rowInfo.collapsed = NO;
            rowInfo.collapsableView = [[OACollapsableTransportStopRoutesView alloc] initWithFrame:CGRectMake([OAUtilities getLeftMargin], 0, 320, 100)];
            ((OACollapsableTransportStopRoutesView *)rowInfo.collapsableView).routes = localTransportRoutes;
            [_rows addObject:rowInfo];
        }
        if (nearbyTransportRoutes.count > 0)
        {
            OsmAndAppInstance app = [OsmAndApp instance];
            NSString *routesWithingDistance = [NSString stringWithFormat:@"%@ %@",  OALocalizedString(@"transport_nearby_routes_within"), [app getFormattedDistance:kShowStopsRadiusMeters]];
            OARowInfo *rowInfo = [[OARowInfo alloc] initWithKey:nil icon:nil textPrefix:nil text:routesWithingDistance textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO];
            rowInfo.collapsable = YES;
            rowInfo.collapsed = NO;
            rowInfo.collapsableView = [[OACollapsableTransportStopRoutesView alloc] initWithFrame:CGRectMake([OAUtilities getLeftMargin], 0, 320, 100)];
            ((OACollapsableTransportStopRoutesView *)rowInfo.collapsableView).routes = nearbyTransportRoutes;
            [_rows addObject:rowInfo];
        }
    }
}

- (void) buildRows:(NSMutableArray<OARowInfo *> *)rows
{
    // implement in subclasses
}

- (void) buildRowsInternal
{    
    _rows = [NSMutableArray array];

    [self buildTopRows:_rows];
    
    [self buildRows:_rows];

    if (self.additionalRows)
    {
        [_rows addObjectsFromArray:self.additionalRows];
    }
    
    [_rows sortUsingComparator:^NSComparisonResult(OARowInfo *row1, OARowInfo *row2) {
        if (row1.order < row2.order)
        {
            return NSOrderedAscending;
        }
        else if (row1.order == row2.order)
        {
            return [row1.typeName localizedCompare:row2.typeName];
        }
        else
        {
            return NSOrderedDescending;
        }
    }];
    
    if ([self showNearestWiki])
    {
        [self processNearestWiki];
        if (_nearestWiki.count > 0)
        {
            UIImage *icon = [UIImage imageNamed:[OAUtilities drawablePath:@"mx_wiki_place"]];
            OARowInfo *wikiRowInfo = [[OARowInfo alloc] initWithKey:nil icon:icon textPrefix:nil text:[NSString stringWithFormat:@"%@ (%d)", OALocalizedString(@"wiki_around"), (int)_nearestWiki.count] textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO];
            wikiRowInfo.collapsable = YES;
            wikiRowInfo.collapsed = YES;
            wikiRowInfo.collapsableView = [[OACollapsableWikiView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
            [((OACollapsableWikiView *)wikiRowInfo.collapsableView) setWikiArray:_nearestWiki hasOsmWiki:_hasOsmWiki latitude:self.location.latitude longitude:self.location.longitude];
            [_rows addObject:wikiRowInfo];
        }
    }
    
    if ([self needCoords])
    {
        OARowInfo *coordinatesRow = [[OARowInfo alloc] initWithKey:nil icon:nil textPrefix:nil text:@"" textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO];
        coordinatesRow.collapsed = YES;
        coordinatesRow.collapsable = YES;
        OACollapsableCoordinatesView *collapsableView = [[OACollapsableCoordinatesView alloc] initWithFrame:CGRectMake(0, 0, 320, 100) lat:self.location.latitude lon:self.location.longitude];
        coordinatesRow.collapsableView = collapsableView;
        [_rows addObject:coordinatesRow];
    }
    
    [_rows addObject:[_cardsHelper addNearbyImagesIfNeeded]];

    _calculatedWidth = 0;
    [self contentHeight:self.tableView.bounds.size.width];
}

- (void) calculateRowsHeight:(CGFloat)width
{
    CGFloat regularTextWidth = width - kMarginLeft - kMarginRight;
    CGFloat collapsableTitleWidth = width - kMarginLeft - kCollapsableTitleMarginRight;
    for (OARowInfo *row in _rows)
    {
        CGFloat textWidth = row.collapsable ? collapsableTitleWidth : regularTextWidth;
        CGFloat rowHeight;
        if (row.isHtml)
        {
            rowHeight = 230.0;
            row.height = rowHeight;
            row.moreText = YES;
        }
        else
        {
            NSString *text = row.textPrefix.length == 0 ? row.text : [NSString stringWithFormat:@"%@: %@", row.textPrefix, row.text];
            CGSize fullBounds = [OAUtilities calculateTextBounds:text width:textWidth font:[row getFont]];
            CGSize bounds = [OAUtilities calculateTextBounds:text width:textWidth height:150.0 font:[row getFont]];
            
            rowHeight = MAX(bounds.height, 28.0) + 11.0 + 11.0;
            row.height = rowHeight;
            row.moreText = fullBounds.height > bounds.height;
        }
        if (row.collapsable)
            [row.collapsableView adjustHeightForWidth:width];
    }
}

- (CGFloat) contentHeight
{
    return _contentHeight;
}

- (CGFloat) contentHeight:(CGFloat)width
{
    if (_calculatedWidth != width)
    {
        [self calculateRowsHeight:width];
        [self calculateContentHeight];
        _calculatedWidth = width;
    }
    return _contentHeight;
}

- (void) calculateContentHeight
{
    CGFloat h = 0;
    for (OARowInfo *row in _rows)
        h += row.height;

    _contentHeight = h;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 60, 0, 0);
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
    UIView *view = [[UIView alloc] init];
    view.backgroundColor = UIColorFromRGB(0xffffff);
    self.tableView.backgroundView = view;
    self.tableView.scrollEnabled = NO;
    _calculatedWidth = 0;
    
    _cardsHelper = [[OAImageCardsHelper alloc] init];
    _cardsHelper.targetObj = self.getTargetObj;
    _cardsHelper.location = self.location;
    [self buildRowsInternal];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void) setContentBackgroundColor:(UIColor *)color
{
    [super setContentBackgroundColor:color];
    self.tableView.backgroundColor = color;
    _contentColor = color;
}

- (void) rebuildRows
{
    [self buildRowsInternal];
}

- (void) processNearestWiki
{
    OsmAnd::PointI locI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(self.location.latitude, self.location.longitude));
    NSMutableArray<OAPOI *> *wiki = [NSMutableArray arrayWithArray:[OAPOIHelper findPOIsByTagName:@"wikipedia" name:nil location:locI categoryName:nil poiTypeName:nil radius:250]];
    NSArray<OAPOI *> *osmwiki = [OAPOIHelper findPOIsByTagName:nil name:nil location:locI categoryName:@"osmwiki" poiTypeName:nil radius:250];
    [wiki addObjectsFromArray:osmwiki];
    
    [wiki sortUsingComparator:^NSComparisonResult(OAPOI *obj1, OAPOI *obj2)
     {
         double distance1 = obj1.distanceMeters;
         double distance2 = obj2.distanceMeters;
         
         return distance1 > distance2 ? NSOrderedDescending : distance1 < distance2 ? NSOrderedAscending : NSOrderedSame;
     }];
    
    id targetObj = [self getTargetObj];
    if (targetObj && [targetObj isKindOfClass:[OAPOI class]])
    {
        OAPOI *poi = targetObj;
        for (OAPOI *w in wiki)
        {
            if (poi.obfId != 0 && w.obfId == poi.obfId)
            {
                [wiki removeObject:w];
                break;
            }
        }
    }
    _hasOsmWiki = osmwiki.count > 0;
    _nearestWiki = [NSArray arrayWithArray:wiki];
}

- (BOOL) showNearestWiki
{
    return YES;
}

- (NSArray<OATransportStopRoute *> *) getSubTransportStopRoutes:(BOOL)nearby
{
    NSMutableArray<OATransportStopRoute *> *res = [NSMutableArray array];
    for (OATransportStopRoute *route in self.routes)
    {
        BOOL isCurrentRouteNearby = route.refStop && route.refStop->getName("", false) != route.stop->getName("", false);
        if ((nearby && isCurrentRouteNearby) || (!nearby && !isCurrentRouteNearby))
            [res addObject:route];
    }
    return res;
}
	
#pragma mark - UITableViewDataSource

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _rows.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString* const reusableIdentifierText = @"OATargetInfoViewCell";
    static NSString* const reusableIdentifierCollapsable = @"OATargetInfoCollapsableViewCell";
    static NSString* const reusableIdentifierWeb = @"OAWebViewCell";
    static NSString* const reusableIdentifierCollapsableСoordinates = @"OATargetInfoCollapsableCoordinatesViewCell";
    
    OARowInfo *info = _rows[indexPath.row];
    
    if (!info.isHtml)
    {
        if ([info.collapsableView isKindOfClass:OACollapsableCoordinatesView.class])
        {
            OATargetInfoCollapsableCoordinatesViewCell *cell;
            cell = (OATargetInfoCollapsableCoordinatesViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierCollapsableСoordinates];
            
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:reusableIdentifierCollapsableСoordinates owner:self options:nil];
                cell = (OATargetInfoCollapsableCoordinatesViewCell *)[nib objectAtIndex:0];
            }
            
            OACollapsableCoordinatesView *coordinateView = (OACollapsableCoordinatesView *) info.collapsableView;
            [cell setupCellWithLat:coordinateView.lat lon:coordinateView.lon];
            
            cell.collapsableView = coordinateView;
            [cell setCollapsed:info.collapsed rawHeight:[info getRawHeight]];
            
            return cell;
        }
        else if (info.collapsable)
        {
            OATargetInfoCollapsableViewCell* cell;
            cell = (OATargetInfoCollapsableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierCollapsable];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATargetInfoCollapsableViewCell" owner:self options:nil];
                cell = (OATargetInfoCollapsableViewCell *)[nib objectAtIndex:0];
            }
            if (info.icon.size.width < cell.iconView.frame.size.width && info.icon.size.height < cell.iconView.frame.size.height)
                cell.iconView.contentMode = UIViewContentModeCenter;
            else
                cell.iconView.contentMode = UIViewContentModeScaleAspectFit;
            
            cell.backgroundColor = _contentColor;
            [cell setImage:info.icon];
            cell.textView.text = info.textPrefix.length == 0 ? info.text : [NSString stringWithFormat:@"%@: %@", info.textPrefix, info.text];
            cell.textView.textColor = info.textColor;
            cell.textView.numberOfLines = info.height > 50.0 ? 20 : 1;

            cell.collapsableView = info.collapsableView;
            [cell setCollapsed:info.collapsed rawHeight:[info getRawHeight]];
            
            return cell;
        }
        else
        {
            OATargetInfoViewCell* cell;
            cell = (OATargetInfoViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierText];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATargetInfoViewCell" owner:self options:nil];
                cell = (OATargetInfoViewCell *)[nib objectAtIndex:0];
            }
            if (info.icon.size.width < cell.iconView.frame.size.width && info.icon.size.height < cell.iconView.frame.size.height)
                cell.iconView.contentMode = UIViewContentModeCenter;
            else
                cell.iconView.contentMode = UIViewContentModeScaleAspectFit;
            
            cell.backgroundColor = _contentColor;
            cell.iconView.image = info.icon;
            
            cell.textView.text = info.textPrefix.length == 0 ? info.text : [NSString stringWithFormat:@"%@: %@", info.textPrefix, info.text];
            cell.textView.textColor = info.textColor;
            cell.textView.font = [info getFont];
            cell.textView.numberOfLines = info.height > 50.0 ? 20 : 1;

            return cell;
        }
    }
    else
    {
        OAWebViewCell* cell;
        cell = (OAWebViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierWeb];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAWebViewCell" owner:self options:nil];
            cell = (OAWebViewCell *)[nib objectAtIndex:0];
        }
        if (info.icon.size.width < cell.iconView.frame.size.width && info.icon.size.height < cell.iconView.frame.size.height)
        {
            cell.iconView.contentMode = UIViewContentModeCenter;
        }
        else
        {
            cell.iconView.contentMode = UIViewContentModeScaleAspectFit;
        }
        cell.backgroundColor = _contentColor;
        cell.webView.backgroundColor = _contentColor;
        cell.iconView.image = info.icon;
        [cell.webView loadHTMLString:[kViewPortHtml stringByAppendingString:info.text]  baseURL:nil];
        
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OARowInfo *info = _rows[indexPath.row];
    return info.height;
}

- (CGFloat) tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OARowInfo *info = _rows[indexPath.row];
    if (info.collapsable)
        [info.collapsableView adjustHeightForWidth:tableView.frame.size.width];
    return info.height;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OARowInfo *info = _rows[indexPath.row];
    if (info.delegate)
    {
        [info.delegate onRowClick:self rowInfo:info];
    }
    else if (info.collapsable)
    {
        info.collapsed = !info.collapsed;
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self calculateContentHeight];
        if (self.delegate)
            [self.delegate contentHeightChanged:0];
    }
    else if (info.isPhoneNumber)
    {
        if ([info.key isEqual:@"phone"] || [info.key isEqual:@"mobile"])
            [OAUtilities callPhone:info.text];
        else
        {
            NSString *url;
            if ([info.key isEqual:@"whatsapp"])
            {
                NSString *phoneNumber = [[info.text componentsSeparatedByCharactersInSet:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]] componentsJoinedByString:@""];
                url = [NSString stringWithFormat:kWhatsAppLink, phoneNumber];
            }
            else if ([info.key isEqual:@"viber"])
            {
                url = [NSString stringWithFormat:kViberLink, info.text];
            }
            [OAUtilities callUrl:url];
        }
    }
    else if (info.isUrl)
    {
        if ([info.text containsString:kWikiLink])
        {
            OAIAPHelper *helper = [OAIAPHelper sharedInstance];
            if ([helper.wiki isPurchased])
            {
                [OAWikiArticleHelper showWikiArticle:self.location url:info.text];
            }
            else
            {
                [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Wiki];
            }
        }
        else if ([info.key isEqual:@"skype"])
        {
            [OAUtilities callUrl:[NSString stringWithFormat:kSkypeLink, info.text]];
        }
        else if ([info.text isValidEmail])
        {
            [OAUtilities callUrl:[NSString stringWithFormat:kMailLink, info.text]];
        }
        else
        {
            [OAUtilities callUrl:info.text];
        }
    }
    else if (info.isText && info.moreText)
    {
        OAEditDescriptionViewController *_editDescController = [[OAEditDescriptionViewController alloc] initWithDescription:info.text isNew:NO readOnly:YES];
        [self.navController pushViewController:_editDescController animated:YES];
    }
}

@end
