//
//  OAPoiViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAPoiViewController.h"
#import "OAPOI.h"
#import "OAPOIHelper.h"
#import "OAOpeningHoursParser.h"
#import "OAUtilities.h"
#import "OAAppSettings.h"
#import "OAIconTextTableViewCell.h"

@interface OARowInfo : NSObject

@property (nonatomic) NSString *key;
@property (nonatomic) UIImage *icon;
@property (nonatomic) NSString *text;
@property (nonatomic) NSString *textPrefix;
@property (nonatomic) UIColor *textColor;
@property (nonatomic) BOOL isText;
@property (nonatomic) BOOL needLinks;
@property (nonatomic) BOOL isPhoneNumber;
@property (nonatomic) BOOL isUrl;
@property (nonatomic) int order;
@property (nonatomic) NSString *name;

- (instancetype)initWithKey:(NSString *)key icon:(UIImage *)icon textPrefix:(NSString *)textPrefix text:(NSString *)text textColor:(UIColor *)textColor isText:(BOOL)isText needLinks:(BOOL)needLinks order:(int)order name:(NSString *)name isPhoneNumber:(BOOL)isPhoneNumber isUrl:(BOOL)isUrl;

@end

@implementation OARowInfo

- (instancetype)initWithKey:(NSString *)key icon:(UIImage *)icon textPrefix:(NSString *)textPrefix text:(NSString *)text textColor:(UIColor *)textColor isText:(BOOL)isText needLinks:(BOOL)needLinks order:(int)order name:(NSString *)name isPhoneNumber:(BOOL)isPhoneNumber isUrl:(BOOL)isUrl
{
    self = [super init];
    if (self)
    {
        _key = key;
        _icon = icon;
        _textPrefix = textPrefix;
        _text = text;
        _textColor = textColor;
        _isText = isText;
        _needLinks = needLinks;
        _order = order;
        _name = name;
        _isPhoneNumber = isPhoneNumber;
        _isUrl = isUrl;
    }
    return self;
}

@end

@interface OAPOIViewController ()

@property (nonatomic) OAPOI *poi;

@end

@implementation OAPOIViewController
{
    NSMutableArray<OARowInfo *> *_rows;
    NSInteger _contentHeight;
    OAPOIHelper *_poiHelper;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _poiHelper = [OAPOIHelper sharedInstance];
    }
    return self;
}

- (id)initWithPOI:(OAPOI *)poi
{
    self = [self init];
    if (self)
    {
        self.poi = poi;
    }
    return self;
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

    if (img)
    {
        img = [OAUtilities tintImageWithColor:img color:UIColorFromRGB(0x727272)];
    }
    
    return img;
}

- (void)buildRows
{
    NSString *prefLang = [[OAAppSettings sharedManager] settingPrefMapLanguage];
    if (!prefLang)
        prefLang = [OAUtilities currentLang];
    
    _rows = [NSMutableArray array];
    NSMutableArray<OARowInfo *> *descriptions = [NSMutableArray array];
    
    [self.poi.values enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value, BOOL * _Nonnull stop) {
        BOOL cont = NO;
        NSString *iconId = nil;
        UIImage *icon = nil;
        UIColor *textColor = nil;
        NSString *textPrefix = nil;
        BOOL isText = NO;
        BOOL isDescription = NO;
        BOOL needLinks = ![@"population" isEqualToString:key];
        BOOL isPhoneNumber = NO;
        BOOL isUrl = NO;
        int poiTypeOrder = 0;
        NSString *poiTypeKeyName = @"";
        
        OAPOIBaseType *pt = [_poiHelper getAnyPoiAdditionalTypeByKey:key];
        OAPOIType *pType = nil;
        if (pt)
        {
            pType = (OAPOIType *) pt;
            poiTypeOrder = pType.order;
            poiTypeKeyName = pType.name;
        }
        
        if ([key hasPrefix:@"name:"])
        {
            cont = YES;
        }
        else if ([key isEqualToString:@"opening_hours"])
        {
            iconId = @"ic_action_time.png";
            
            OAOpeningHoursParser *parser = [[OAOpeningHoursParser alloc] initWithOpeningHours:value];
            BOOL isOpened = [parser isOpenedForTime:[NSDate date]];
            textColor = isOpened ? UIColorFromRGB(0x2BBE31) : UIColorFromRGB(0xDA3A3A);
        }
        else if ([key isEqualToString:@"phone"])
        {
            iconId = @"ic_action_call_dark.png";
            isPhoneNumber = YES;
        }
        else if ([key isEqualToString:@"website"])
        {
            iconId = @"ic_world_globe_dark.png";
            isUrl = YES;
        }
        else
        {
            if ([key rangeOfString:@"description"].length != 0)
            {
                iconId = @"ic_action_note_dark.png";
            }
            else
            {
                iconId = @"ic_action_info_dark.png";
            }
            if (pType)
            {
                poiTypeOrder = pType.order;
                poiTypeKeyName = pType.name;
                if (pType.parentType && [pType.parentType isKindOfClass:[OAPOIType class]])
                {
                    icon = [self getIcon:[NSString stringWithFormat:@"mx_%@_%@_%@.png", ((OAPOIType *) pType.parentType).tag, [pType.tag stringByReplacingOccurrencesOfString:@":" withString:@"_"], pType.value]];
                }
                if (!pType.isText)
                {
                    value = pType.nameLocalized;
                }
                else
                {
                    isText = YES;
                    isDescription = [iconId isEqualToString:@"ic_action_note_dark.png"];
                    textPrefix = pType.nameLocalized;
                }
                if (!isDescription && !icon)
                {
                    icon = [self getIcon:[NSString stringWithFormat:@"mx_%@", [pType.name stringByReplacingOccurrencesOfString:@":" withString:@"_"]]];
                    if (isText && icon)
                    {
                        textPrefix = @"";
                    }
                }
                if (!icon && isText)
                {
                    iconId = @"ic_action_note_dark.png";
                }
            }
            else
            {
                textPrefix = [key capitalizedStringWithLocale:[NSLocale currentLocale]];
            }
        }
        
        if (!cont)
        {
            if (isDescription)
            {
                [descriptions addObject:[[OARowInfo alloc] initWithKey:key icon:[self getIcon:@"ic_action_note_dark.png"] textPrefix:textPrefix text:value textColor:nil isText:YES needLinks:YES order:0 name:@"" isPhoneNumber:NO isUrl:NO]];
            }
            else
            {
                [_rows addObject:[[OARowInfo alloc] initWithKey:key icon:(icon ? icon : [self getIcon:iconId]) textPrefix:textPrefix text:value textColor:textColor isText:isText needLinks:needLinks order:poiTypeOrder name:poiTypeKeyName isPhoneNumber:isPhoneNumber isUrl:isUrl]];
            }
        }
        
        [descriptions sortUsingComparator:^NSComparisonResult(OARowInfo *row1, OARowInfo *row2) {
            if (row1.order < row2.order)
            {
                return NSOrderedAscending;
            }
            else if (row1.order == row2.order)
            {
                return [row1.name localizedCompare:row2.name];
            }
            else
            {
                return NSOrderedDescending;
            }
        }];
        
        NSString *langSuffix = [NSString stringWithFormat:@":%@", prefLang];
        OARowInfo *descInPrefLang = nil;
        for (OARowInfo *desc in descriptions)
        {
            if (desc.key.length > langSuffix.length
                && [[desc.key substringFromIndex:desc.key.length - langSuffix.length] isEqualToString:langSuffix])
            {
                descInPrefLang = desc;
                break;
            }
        }
        if (descInPrefLang)
        {
            [descriptions removeObject:descInPrefLang];
            [descriptions insertObject:descInPrefLang atIndex:0];
        }

        for (OARowInfo *desc in descriptions)
        {
            [_rows addObject:desc];
        }
        
    }];

    if (self.showCoords)
    {
        [_rows addObject:[[OARowInfo alloc] initWithKey:nil icon:[self getIcon:@"ic_action_get_my_location.png"] textPrefix:nil text:self.formattedCoords textColor:nil isText:NO needLinks:NO order:0 name:@"" isPhoneNumber:NO isUrl:NO]];
    }
    
    _contentHeight = _rows.count * 44.0;
}

- (CGFloat)contentHeight
{
    return _contentHeight;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self buildRows];
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
    _tableView.backgroundColor = color;
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _rows.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString* const reusableIdentifierText = @"OAIconTextTableViewCell";
    
    OARowInfo *info = _rows[indexPath.row];
    
    OAIconTextTableViewCell* cell;
    cell = (OAIconTextTableViewCell *)[tableView dequeueReusableCellWithIdentifier:reusableIdentifierText];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTextCell" owner:self options:nil];
        cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.arrowIconView.hidden = YES;
        [cell showImage:YES];
    }
    cell.iconView.image = info.icon;
    cell.textView.text = info.textPrefix.length == 0 ? info.text : [NSString stringWithFormat:@"%@: %@", info.textPrefix, info.text];
    cell.textView.textColor = info.textColor;
    
    return cell;
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
    return 44.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
