//
//  OAPOISearchHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 17/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAPOISearchHelper.h"
#import "OAUtilities.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAPOIHelper.h"
#import "OAPOI.h"
#import "OAPOIType.h"
#import "OAPOICategory.h"
#import "OAPOIFilter.h"
#import "OAHistoryItem.h"

#import "OAIconTextTableViewCell.h"
#import "OAIconTextExTableViewCell.h"
#import "OASearchMoreCell.h"
#import "OAPointDescCell.h"
#import "OAIconTextDescCell.h"
#import "OAIconButtonCell.h"


@implementation OAPOISearchHelper

+ (NSInteger)getNumberOfRows:(NSArray *)dataArray dataPoiArray:(NSArray *)dataPoiArray currentScope:(EPOIScope)currentScope showCoordinates:(BOOL)showCoordinates showTopList:(BOOL)showTopList poiInList:(BOOL)poiInList searchRadiusIndex:(int)searchRadiusIndex searchRadiusIndexMax:(int)searchRadiusIndexMax
{
    return dataArray.count +
        dataPoiArray.count +
        (currentScope != EPOIScopeUndefined && searchRadiusIndex <= searchRadiusIndexMax ? 1 : 0) +
        (currentScope == EPOIScopeUndefined && showTopList ? 2 : 0) +
        (showCoordinates ? 1 : 0);
}

+ (CGFloat)getHeightForHeader
{
    return 16;
}

+ (CGFloat)getHeightForFooter
{
    return 16;
}

+ (CGFloat)getHeightForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView dataArray:(NSArray *)dataArray dataPoiArray:(NSArray *)dataPoiArray showCoordinates:(BOOL)showCoordinates
{
    NSInteger row = indexPath.row;
    
    if (showCoordinates)
    {
        if (row == 0)
            return 50.0;
        else
            row--;
    }
    
    NSInteger index = row - dataArray.count;
    if (index >= 0 && index < dataPoiArray.count)
    {
        OAPOI* item = dataPoiArray[index];
        
        CGSize size = [OAUtilities calculateTextBounds:item.nameLocalized width:tableView.bounds.size.width - 59.0 font:[UIFont fontWithName:@"AvenirNext-Regular" size:14.0]];
        
        return 30.0 + size.height;
    }
    else
    {
        return 50.0;
    }
}

+ (UITableViewCell *)getCellForRowAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView dataArray:(NSArray *)dataArray dataPoiArray:(NSArray *)dataPoiArray currentScope:(EPOIScope)currentScope poiInList:(BOOL)poiInList showCoordinates:(BOOL)showCoordinates foundCoords:(NSArray *)foundCoords showTopList:(BOOL)showTopList searchRadiusIndex:(int)searchRadiusIndex searchRadiusIndexMax:(int)searchRadiusIndexMax searchNearMapCenter:(BOOL)searchNearMapCenter
{
    NSInteger row = indexPath.row;
    
    if (showCoordinates)
    {
        if (row == 0)
        {
            OAIconTextExTableViewCell* cell;
            cell = (OAIconTextExTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconTextExTableViewCell"];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextExCell" owner:self options:nil];
                cell = (OAIconTextExTableViewCell *)[nib objectAtIndex:0];
            }
            
            if (cell)
            {
                NSUInteger coordsCount = foundCoords.count;
                
                CGRect f = cell.textView.frame;
                CGFloat oldX = f.origin.x;
                f.origin.x = 12.0;
                f.origin.y = 14.0;
                
                if (coordsCount == 1)
                    f.size.width = tableView.frame.size.width - 24.0;
                else
                    f.size.width += (oldX - f.origin.x);
                
                cell.textView.frame = f;
                
                NSString *text = @"";
                if (coordsCount == 1)
                {
                    NSString *coord1 = [OAUtilities floatToStrTrimZeros:[foundCoords[0] doubleValue]];
                    
                    text = [NSString stringWithFormat:@"%@ %@ %@ #.## %@ ##’##’##.#", OALocalizedString(@"latitude"), coord1, OALocalizedString(@"longitude"), OALocalizedString(@"shared_string_or")];
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    cell.arrowIconView.hidden = YES;
                }
                else if (coordsCount > 1)
                {
                    NSString *coord1 = [OAUtilities floatToStrTrimZeros:[foundCoords[0] doubleValue]];
                    NSString *coord2 = [OAUtilities floatToStrTrimZeros:[foundCoords[1] doubleValue]];
                    
                    text = [NSString stringWithFormat:@"%@: %@, %@", OALocalizedString(@"sett_arr_loc"), coord1, coord2];
                    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                    cell.arrowIconView.hidden = NO;
                }
                
                [cell.textView setText:text];
                [cell.iconView setImage: nil];
            }
            return cell;
        }
        else
        {
            row--;
        }
    }
    
    if (row >= dataArray.count + dataPoiArray.count)
    {
        if (currentScope == EPOIScopeUndefined && showTopList)
        {
            if (row >= dataArray.count + dataPoiArray.count + 1)
            {
                OAIconButtonCell* cell;
                cell = (OAIconButtonCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconButtonCell"];
                if (cell == nil)
                {
                    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconButtonCell" owner:self options:nil];
                    cell = (OAIconButtonCell *)[nib objectAtIndex:0];
                }
                
                if (cell)
                {
                    cell.contentView.backgroundColor = [UIColor whiteColor];
                    [cell setImage:[UIImage imageNamed:@"search_icon.png"] tint:YES];
                    [cell.textView setText:OALocalizedString(@"custom_search")];
                    [cell.iconView setImage: nil];
                }
                return cell;
            }
            else
            {
                OAIconTextTableViewCell* cell;
                cell = (OAIconTextTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconTextTableViewCell"];
                if (cell == nil)
                {
                    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
                    cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
                }
                
                if (cell)
                {
                    cell.contentView.backgroundColor = [UIColor whiteColor];
                    cell.arrowIconView.image = [UIImage imageNamed:@"menu_cell_pointer.png"];
                    [cell.textView setTextColor:[UIColor blackColor]];
                    
                    CGRect f = cell.textView.frame;
                    f.origin.y = 14.0;
                    cell.textView.frame = f;
                    
                    [cell.textView setText:OALocalizedString(@"all_categories")];
                    [cell.iconView setImage: nil];
                }
                return cell;
            }
        }
        else
        {
            OASearchMoreCell* cell;
            cell = (OASearchMoreCell *)[tableView dequeueReusableCellWithIdentifier:@"OASearchMoreCell"];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASearchMoreCell" owner:self options:nil];
                cell = (OASearchMoreCell *)[nib objectAtIndex:0];
            }
            if (searchRadiusIndex < searchRadiusIndexMax)
            {
                cell.textView.text = OALocalizedString(@"poi_insrease_radius %@", [[OsmAndApp instance] getFormattedDistance:kSearchRadiusKm[searchRadiusIndex + 1] * 1000.0]);
            }
            else
            {
                cell.textView.text = OALocalizedString(@"poi_max_radius_reached");
            }
            return cell;
        }
    }
    
    id obj;
    if (row >= dataArray.count)
        obj = dataPoiArray[row - dataArray.count];
    else
        obj = dataArray[row];
    
    
    if ([obj isKindOfClass:[OAPOI class]])
    {
        static NSString* const reusableIdentifierPoint = @"OAPointDescCell";
        
        OAPointDescCell* cell;
        cell = (OAPointDescCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPointDescCell" owner:self options:nil];
            cell = (OAPointDescCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            OAPOI* item = obj;
            [cell.titleView setText:item.nameLocalized];
            cell.titleIcon.image = [item icon];
            [cell.descView setText:item.type.nameLocalized];
            [cell updateDescVisibility];
            if (item.hasOpeningHours)
            {
                [cell.openingHoursView setText:item.openingHours];
                cell.timeIcon.hidden = NO;
                [cell updateOpeningTimeInfo];
            }
            else
            {
                cell.openingHoursView.hidden = YES;
                cell.timeIcon.hidden = YES;
            }
            
            [cell.distanceView setText:item.distance];
            if (searchNearMapCenter)
            {
                cell.directionImageView.hidden = YES;
                CGRect frame = cell.distanceView.frame;
                frame.origin.x = 51.0;
                cell.distanceView.frame = frame;
            }
            else
            {
                cell.directionImageView.hidden = NO;
                CGRect frame = cell.distanceView.frame;
                frame.origin.x = 69.0;
                cell.distanceView.frame = frame;
                cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
            }
        }
        return cell;
    }
    else if ([obj isKindOfClass:[OAHistoryItem class]])
    {
        static NSString* const reusableIdentifierPoint = @"OAPointDescCell";
        
        OAPointDescCell* cell;
        cell = (OAPointDescCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierPoint];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAPointDescCell" owner:self options:nil];
            cell = (OAPointDescCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            OAHistoryItem* item = obj;
            [cell.titleView setText:item.name];
            cell.titleIcon.image = item.icon;
            [cell.descView setText:item.typeName.length > 0 ? item.typeName : OALocalizedString(@"history")];
            [cell updateDescVisibility];
            cell.openingHoursView.hidden = YES;
            cell.timeIcon.hidden = YES;
            
            [cell.distanceView setText:item.distance];
            if (searchNearMapCenter)
            {
                cell.directionImageView.hidden = YES;
                CGRect frame = cell.distanceView.frame;
                frame.origin.x = 51.0;
                cell.distanceView.frame = frame;
            }
            else
            {
                cell.directionImageView.hidden = NO;
                CGRect frame = cell.distanceView.frame;
                frame.origin.x = 69.0;
                cell.distanceView.frame = frame;
                cell.directionImageView.transform = CGAffineTransformMakeRotation(item.direction);
            }
        }
        return cell;
    }
    else if ([obj isKindOfClass:[OAPOIType class]])
    {
        OAIconTextDescCell* cell;
        cell = (OAIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconTextDescCell"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextDescCell" owner:self options:nil];
            cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            OAPOIType* item = obj;
            
            CGRect f = cell.textView.frame;
            if (item.category.nameLocalized.length == 0)
                f.origin.y = 14.0;
            else
                f.origin.y = 8.0;
            cell.textView.frame = f;
            
            [cell.textView setText:item.nameLocalized];
            [cell.descView setText:item.category.nameLocalized];
            [cell.iconView setImage: [item icon]];
        }
        return cell;
    }
    else if ([obj isKindOfClass:[OAPOIFilter class]])
    {
        OAIconTextDescCell* cell;
        cell = (OAIconTextDescCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconTextDescCell"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextDescCell" owner:self options:nil];
            cell = (OAIconTextDescCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            OAPOIFilter* item = obj;
            
            CGRect f = cell.textView.frame;
            if (item.category.nameLocalized.length == 0)
                f.origin.y = 14.0;
            else
                f.origin.y = 8.0;
            cell.textView.frame = f;
            
            [cell.textView setText:item.nameLocalized];
            [cell.descView setText:item.category.nameLocalized];
            [cell.iconView setImage: [item icon]];
        }
        return cell;
    }
    else if ([obj isKindOfClass:[OAPOICategory class]])
    {
        OAIconTextTableViewCell* cell;
        cell = (OAIconTextTableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"OAIconTextTableViewCell"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
            cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.contentView.backgroundColor = [UIColor whiteColor];
            cell.arrowIconView.image = [UIImage imageNamed:@"menu_cell_pointer.png"];
            [cell.textView setTextColor:[UIColor blackColor]];
            
            OAPOICategory* item = obj;
            
            CGRect f = cell.textView.frame;
            f.origin.y = 14.0;
            cell.textView.frame = f;
            
            [cell.textView setText:item.nameLocalized];
            [cell.iconView setImage: [item icon]];
        }
        return cell;
    }
    else
    {
        return nil;
    }
}

@end
