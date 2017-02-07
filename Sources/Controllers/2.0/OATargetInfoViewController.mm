//
//  OATargetInfoViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"
#import "OAUtilities.h"
#import "OATargetInfoViewCell.h"
#import "OATargetInfoCollapsableViewCell.h"
#import "OAWebViewCell.h"
#import "OAEditDescriptionViewController.h"
#import "Localization.h"
#import "OAPOIHelper.h"
#import "OAPOI.h"
#import "OACollapsableWikiView.h"

#include <OsmAndCore/Utilities.h>

@implementation OARowInfo

- (instancetype)initWithKey:(NSString *)key icon:(UIImage *)icon textPrefix:(NSString *)textPrefix text:(NSString *)text textColor:(UIColor *)textColor isText:(BOOL)isText needLinks:(BOOL)needLinks order:(int)order typeName:(NSString *)typeName isPhoneNumber:(BOOL)isPhoneNumber isUrl:(BOOL)isUrl
{
    self = [super init];
    if (self)
    {
        _key = key;
        _icon = icon;
        _icon = [_icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        _textPrefix = textPrefix;
        _text = text;
        _textColor = textColor;
        _isText = isText;
        _needLinks = needLinks;
        _order = order;
        _typeName = typeName;
        _isPhoneNumber = isPhoneNumber;
        _isUrl = isUrl;
    }
    return self;
}

-(int)height
{
    if (_collapsable && _collapsableView && !_collapsed)
        return _height + _collapsableView.frame.size.height;
    else
        return _height;
}

- (int)getRawHeight
{
    return _height;
}

@end


@implementation OATargetInfoViewController
{
    NSMutableArray<OARowInfo *> *_rows;
    CGFloat _contentHeight;
    UIColor *_contentColor;
    NSArray<OAPOI *> *_nearestWiki;
    BOOL _hasOsmWiki;
}

- (BOOL)needCoords
{
    return YES;
}

- (UIImage *) getIcon:(NSString *)fileName
{
    UIImage *img = nil;
    if ([fileName hasPrefix:@"mx_"])
    {
        img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-%@/%@", [OAUtilities drawablePostfix], fileName]];
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

- (void)buildRows:(NSMutableArray<OARowInfo *> *)rows
{
    // implement in subclasses
}

- (void)buildRowsInternal
{    
    _rows = [NSMutableArray array];

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
            UIImage *icon = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-%@/mx_wiki_place", [OAUtilities drawablePostfix]]];
            OARowInfo *wikiRowInfo = [[OARowInfo alloc] initWithKey:nil icon:icon textPrefix:nil text:[NSString stringWithFormat:@"%@ (%d)", OALocalizedString(@"wiki_around"), (int)_nearestWiki.count] textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO];
            wikiRowInfo.collapsable = YES;
            wikiRowInfo.collapsed = YES;
            wikiRowInfo.collapsableView = [[OACollapsableWikiView alloc] initWithFrame:CGRectMake(0, 0, 320, 100)];
            [((OACollapsableWikiView *)wikiRowInfo.collapsableView) setWikiArray:_nearestWiki hasOsmWiki:_hasOsmWiki];
            [_rows addObject:wikiRowInfo];
        }
    }
    
    if ([self needCoords])
    {
        [_rows addObject:[[OARowInfo alloc] initWithKey:nil icon:[self getIcon:@"ic_coordinates_location.png"] textPrefix:nil text:self.formattedCoords textColor:nil isText:NO needLinks:NO order:0 typeName:@"" isPhoneNumber:NO isUrl:NO]];
    }
    
    CGFloat h = 0;
    CGFloat textWidth = self.tableView.bounds.size.width - 60.0;
    for (OARowInfo *row in _rows)
    {
        CGFloat rowHeight;
        if (row.isHtml)
        {
            rowHeight = 200.0 + 12.0 + 11.0;
            row.height = rowHeight;
            row.moreText = YES;
        }
        else
        {
            NSString *text = row.textPrefix.length == 0 ? row.text : [NSString stringWithFormat:@"%@: %@", row.textPrefix, row.text];
            CGSize fullBounds = [OAUtilities calculateTextBounds:text width:textWidth font:[UIFont fontWithName:@"AvenirNext-Regular" size:15.0]];
            CGSize bounds = [OAUtilities calculateTextBounds:text width:textWidth height:150.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:15.0]];
            
            rowHeight = MAX(bounds.height, 21.0) + 12.0 + 11.0;
            row.height = rowHeight;
            row.moreText = fullBounds.height > bounds.height;
            
        }
        h += rowHeight;
    }
    
    _contentHeight = h;
}

- (CGFloat)contentHeight
{
    return _contentHeight;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 50, 0, 0);
    [self buildRowsInternal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)setContentBackgroundColor:(UIColor *)color
{
    [super setContentBackgroundColor:color];
    self.tableView.backgroundColor = color;
    _contentColor = color;
}

- (void)processNearestWiki
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

-(BOOL)showNearestWiki
{
    return YES;
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString* const reusableIdentifierText = @"OATargetInfoViewCell";
    static NSString* const reusableIdentifierCollapsable = @"OATargetInfoCollapsableViewCell";
    static NSString* const reusableIdentifierWeb = @"OAWebViewCell";
    
    OARowInfo *info = _rows[indexPath.row];
    
    if (!info.isHtml)
    {
        if (info.collapsable)
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
            cell.iconView.image = info.icon;
            cell.textView.text = info.textPrefix.length == 0 ? info.text : [NSString stringWithFormat:@"%@: %@", info.textPrefix, info.text];
            cell.textView.textColor = info.textColor;
            cell.textView.numberOfLines = info.height > 44.0 ? 20 : 1;

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
            cell.textView.numberOfLines = info.height > 44.0 ? 20 : 1;

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
        [cell.webView loadHTMLString:info.text  baseURL:nil];
        
        return cell;
    }
}



#pragma mark - UITableViewDelegate

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OARowInfo *info = _rows[indexPath.row];
    return info.height;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OARowInfo *info = _rows[indexPath.row];
    if (info.collapsable)
        [info.collapsableView adjustHeightForWidth:tableView.frame.size.width];
    return info.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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
    }
    else if (info.isPhoneNumber)
    {
        [OAUtilities callPhone:info.text];
    }
    else if (info.isUrl)
    {
        [OAUtilities callUrl:info.text];
    }
    else if (info.isText && info.moreText)
    {
        OAEditDescriptionViewController *_editDescController = [[OAEditDescriptionViewController alloc] initWithDescription:info.text isNew:NO readOnly:YES];
        [self.navController pushViewController:_editDescController animated:YES];
    }
}

@end
