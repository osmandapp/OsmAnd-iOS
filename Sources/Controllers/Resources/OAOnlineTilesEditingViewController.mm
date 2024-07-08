//
//  OAOnlineTilesEditingViewController.m
//  OsmAnd Maps
//
//  Created by igor on 23.01.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAOnlineTilesEditingViewController.h"
#import "Localization.h"
#import "OASQLiteTileSource.h"
#import "OAValueTableViewCell.h"
#import "OACustomPickerTableViewCell.h"
#import "OAInputTableViewCell.h"
#import "OATextMultilineTableViewCell.h"
#import "OAOnlineTilesSettingsViewController.h"
#import "OAResourcesBaseViewController.h"
#import "OAManageResourcesViewController.h"
#import "OAMapCreatorHelper.h"
#import "GeneratedAssetSymbols.h"
#import "OAMapSource.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>
#include <QXmlStreamAttributes>

#define kNameSection 0
#define kURLSection 1
#define kZoomSection 2
#define kExpireSection 3

#define kNameCellTag 100
#define kURLCellTag 101

#define kMaxExpireMin 10000000
#define kMinAllowedZoom 1
#define kMaxAllowedZoom 22
#define maxSaveButtonWidth 105

@interface OAOnlineTilesEditingViewController () <UITextViewDelegate, UITextFieldDelegate, OACustomPickerTableViewCellDelegate, OAOnlineTilesSettingsViewControllerDelegate>

@end

@implementation OAOnlineTilesEditingViewController
{
    std::shared_ptr<const OsmAnd::IOnlineTileSources::Source> _tileSource;
    OASQLiteTileSource *_sqliteSource;
    OsmAndAppInstance _app;
    OAResourcesBaseViewController *_baseController;
    OASqliteDbResourceItem *_sqliteDbItem;
    
    NSString *_itemName;
    NSString *_itemURL;
    NSString *_referer;
    NSString *_userAgent;
    int _minZoom;
    int _maxZoom;
    long _expireTimeMillis;
    BOOL _isEllipticYTile;
    EOASourceFormat _sourceFormat;
    
    NSString *_expireTimeMinutes;
    
    NSArray *_data;
    NSArray<NSDictionary *> *_zoomArray;
    NSArray<NSDictionary *> *_sectionHeaderFooterTitles;
    
    NSArray<NSString *> *_possibleZoomValues;
    NSIndexPath *_pickerIndexPath;
    
    BOOL _isNewItem;
}

#pragma mark - Initialization

- (instancetype)initWithLocalItem:(OALocalResourceItem *)item baseController:(OAResourcesBaseViewController *)baseController
{
    self = [super init];
    if (self)
    {
        _baseController = baseController;
        
        if ([item isKindOfClass:OAOnlineTilesResourceItem.class])
        {
            const auto& resource = _app.resourcesManager->getResource(QStringLiteral("online_tiles"));
            if (resource != nullptr)
            {
                const auto& onlineTileSources = std::static_pointer_cast<const OsmAnd::ResourcesManager::OnlineTileSourcesMetadata>(resource->metadata)->sources;
                for(const auto& onlineTileSource : onlineTileSources->getCollection())
                {
                    if (QString::compare(QString::fromNSString(item.title), onlineTileSource->name) == 0)
                    {
                        _tileSource = onlineTileSource;
                        break;
                    }
                }
            }
            [self setupParametersFromTileSource];
        }
        else if ([item isKindOfClass:OASqliteDbResourceItem.class])
        {
            _sqliteDbItem = (OASqliteDbResourceItem *) item;
            _sqliteSource = [[OASQLiteTileSource alloc] initWithFilePath:_sqliteDbItem.path];
            [self setupParametersFromSqlite];
        }
    }
    return self;
}

- (instancetype)initWithUrlParameters:(NSDictionary<NSString *, NSString *> *)params
{
    self = [super init];
    if (self)
    {
        _tileSource = OsmAnd::OnlineTileSources::createTileSourceTemplate([self attributesFromParams:params]);
        [self setupParametersFromTileSource];
    }
    return self;
}

- (instancetype)initWithEmptyItem
{
    self = [super init];
    if (self)
    {
        const auto& emptySource = std::shared_ptr<OsmAnd::IOnlineTileSources::Source>(new OsmAnd::OnlineTileSources::Source(QStringLiteral("")));
        emptySource->minZoom = OsmAnd::ZoomLevel4;
        emptySource->maxZoom = OsmAnd::ZoomLevel18;
        _tileSource = emptySource;
        [self setupParametersFromTileSource];
        _isNewItem = YES;
    }
    return self;
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
}

- (void)setupParametersFromTileSource
{
    _itemName = _tileSource->name.toNSString();
    _itemURL = _tileSource->urlToLoad.toNSString();
    _referer = _tileSource->referer.toNSString();
    _userAgent = _tileSource->userAgent.toNSString();
    _minZoom = _tileSource->minZoom;
    _maxZoom = _tileSource->maxZoom;
    _expireTimeMillis = _tileSource->expirationTimeMillis;
    _isEllipticYTile = _tileSource->ellipticYTile;
    _sourceFormat = EOASourceFormatOnline;
    _expireTimeMinutes = _expireTimeMillis == -1 ? @"" : [NSString stringWithFormat:@"%ld", (_expireTimeMillis / 1000 / 60)];
}

- (void)setupParametersFromSqlite
{
    _itemName = _sqliteSource.title;
    _itemURL = _sqliteSource.urlTemplate;
    _referer = _sqliteSource.referer;
    _userAgent = _sqliteSource.userAgent;
    _minZoom = _sqliteSource.minimumZoomSupported;
    _maxZoom = _sqliteSource.maximumZoomSupported;
    _expireTimeMillis = _sqliteSource.getExpirationTimeMillis;
    _isEllipticYTile = _sqliteSource.isEllipticYTile;
    _sourceFormat = EOASourceFormatSQLite;
    _expireTimeMinutes = _expireTimeMillis == -1 ? @"" : [NSString stringWithFormat:@"%ld", (_expireTimeMillis / 1000 / 60)];
}

- (QXmlStreamAttributes)attributesFromParams:(NSDictionary<NSString *, NSString *> *)params
{
    QXmlStreamAttributes attrs = QXmlStreamAttributes();
    for (NSString *key in params)
    {
        attrs.append(QString::fromNSString(key), QString::fromNSString(params[key]));
    }
    return attrs;
}

- (void)registerNotifications
{
    [self addNotification:UIKeyboardWillShowNotification selector:@selector(keyboardWillShow:)];
    [self addNotification:UIKeyboardWillHideNotification selector:@selector(keyboardWillHide:)];
}

#pragma mark - UIViewColontroller

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController.interactivePopGestureRecognizer addTarget:self
                                                                  action:@selector(swipeToCloseRecognized:)];
    
    _possibleZoomValues = @[@"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", @"12", @"13", @"14", @"15", @"16", @"17", @"18", @"19", @"20", @"21", @"22"];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _isNewItem ? OALocalizedString(@"add_online_source") : OALocalizedString(@"res_edit_map_source");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    return @[[self createRightNavbarButton:OALocalizedString(@"shared_string_save")
                                  iconName:nil
                                    action:@selector(onRightNavbarButtonPressed)
                                      menu:nil]];
}

- (UIImage *)getCustomIconForLeftNavbarButton
{
    return [UIImage templateImageNamed:@"ic_navbar_chevron"].imageFlippedForRightToLeftLayoutDirection;
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray *zoomArr = [NSMutableArray new];
    [zoomArr addObject:@{
        @"title": OALocalizedString(@"rec_interval_minimum"),
        @"key" : @"minZoom",
        @"type" : [OAValueTableViewCell getCellIdentifier],
    }];
    [zoomArr addObject:@{
        @"title": OALocalizedString(@"shared_string_maximum"),
        @"key" : @"maxZoom",
        @"type" : [OAValueTableViewCell getCellIdentifier],
    }];
    [zoomArr addObject:@{
        @"type" : [OACustomPickerTableViewCell getCellIdentifier],
    }];
    _zoomArray = [NSArray arrayWithArray: zoomArr];
    
    NSMutableArray *tableData = [NSMutableArray new];
    [tableData addObject:@{ @"type" : [OATextMultilineTableViewCell getCellIdentifier] }];
    [tableData addObject:@{ @"type" : [OATextMultilineTableViewCell getCellIdentifier] }];
    [tableData addObject: zoomArr];
    [tableData addObject:@{
        @"placeholder" : OALocalizedString(@"shared_string_not_set"),
        @"type" : [OAInputTableViewCell getCellIdentifier]
    }];
    
    [tableData addObject:@{
        @"title": OALocalizedString(@"res_mercator"),
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"key" : @"mercator_sett"
    }];
    
    [tableData addObject:@{
        @"title": OALocalizedString(@"res_source_format"),
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"key" : @"format_sett"
    }];
    _data = [NSArray arrayWithArray:tableData];
    
    NSMutableArray *sectionArr = [NSMutableArray new];
    [sectionArr addObject:@{
        @"header" : OALocalizedString(@"shared_string_name"),
        @"footer" : OALocalizedString(@"res_online_name_descr")
    }];
    [sectionArr addObject:@{
        @"header" : OALocalizedString(@"edit_tilesource_url_to_load"),
        @"footer" : OALocalizedString(@"res_online_url_descr")
    }];
    [sectionArr addObject:@{
        @"header" : OALocalizedString(@"shared_string_zoom_levels"),
        @"footer" : OALocalizedString(@"res_zoom_levels_desc")
    }];
    [sectionArr addObject:@{
        @"header" : OALocalizedString(@"res_expire_time"),
        @"footer" : OALocalizedString(@"res_expire_time_desc")
    }];
    _sectionHeaderFooterTitles = [NSArray arrayWithArray:sectionArr];
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    if (indexPath.section != kZoomSection)
        return [_data objectAtIndex:indexPath.section];
    else
    {
        NSArray *ar = [_data objectAtIndex:indexPath.section];
        if ([self pickerIsShown])
        {
            if ([indexPath isEqual:_pickerIndexPath])
                return ar[2];
            else if (indexPath.row == 0)
                return ar[0];
            else
                return ar[1];
        }
        else
        {
            if (indexPath.row == 0)
                return ar[0];
            else if (indexPath.row == 1)
                return ar[1];
        }
    }
    return [NSDictionary new];
}

- (NSString *)getFormatString:(EOASourceFormat)sourceFormat
{
    if (sourceFormat == EOASourceFormatOnline)
        return OALocalizedString(@"one_image_per_tile");
    else if (sourceFormat == EOASourceFormatSQLite)
        return OALocalizedString(@"sqlite_db_file");
    
    return @"";
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return section < _sectionHeaderFooterTitles.count ? _sectionHeaderFooterTitles[section][@"header"] : @"";
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return section < _sectionHeaderFooterTitles.count ? _sectionHeaderFooterTitles[section][@"footer"] : @"";
}

- (NSInteger)rowsCount:(NSInteger)section
{
    if (section == kZoomSection)
    {
        if ([self pickerIsShown])
            return 3;
        return 2;
    }
    return 1;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item =  [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OATextMultilineTableViewCell getCellIdentifier]])
    {
        OATextMultilineTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OATextMultilineTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextMultilineTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextMultilineTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            cell.textView.userInteractionEnabled = YES;
            cell.textView.editable = YES;
            cell.textView.delegate = self;
            cell.textView.textContainer.lineBreakMode = NSLineBreakByCharWrapping;
        }
        if (cell)
        {
            BOOL isURL = indexPath.section == kURLSection;
            cell.textView.tag = isURL ? kURLCellTag : kNameCellTag;
            cell.clearButton.tag = cell.textView.tag;
            [cell.clearButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
            [cell.clearButton addTarget:self action:@selector(clearButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            if ([self isOfflineSQLiteDB] && isURL)
            {
                cell.userInteractionEnabled = NO;
                cell.textView.text = OALocalizedString(@"res_offlineSQL_URL_warning");
                cell.textView.textColor = [UIColor lightGrayColor];
                [cell clearButtonVisibility:NO];
            }
            else
            {
                cell.userInteractionEnabled = YES;
                cell.textView.text = isURL ? _itemURL : _itemName;
                cell.textView.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
                [cell clearButtonVisibility:YES];
            }
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAInputTableViewCell getCellIdentifier]])
    {
        OAInputTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAInputTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAInputTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAInputTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell titleVisibility:NO];
            [cell clearButtonVisibility:NO];
            [cell.inputField removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
            [cell.inputField addTarget:self action:@selector(textChanged:) forControlEvents:UIControlEventEditingChanged];
            cell.inputField.keyboardType = UIKeyboardTypeNumberPad;
            cell.inputField.textAlignment = NSTextAlignmentNatural;
        }
        if (cell)
        {
            cell.inputField.text = _expireTimeMinutes;
            cell.inputField.delegate = self;
            
            BOOL isOfflineSQLiteDB = [self isOfflineSQLiteDB];
            cell.userInteractionEnabled = !isOfflineSQLiteDB;
            cell.inputField.placeholder = isOfflineSQLiteDB ? OALocalizedString(@"res_offlineSQL_URL_warning") : item[@"placeholder"];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        NSString *key = item[@"key"];
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            
            if ([key isEqualToString:@"minZoom"] || [key isEqualToString:@"maxZoom"])
            {
                if ([key isEqualToString:@"minZoom"])
                    cell.valueLabel.text = [NSString stringWithFormat:@"%d", _minZoom];
                else if ([key isEqualToString:@"maxZoom"])
                    cell.valueLabel.text = [NSString stringWithFormat:@"%d", _maxZoom];
                else
                    cell.valueLabel.text = @"";
                
                cell.valueLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            else if ([key isEqualToString:@"mercator_sett"] || [key isEqualToString:@"format_sett"])
            {
                if ([key isEqualToString:@"mercator_sett"])
                {
                    cell.valueLabel.text = _isEllipticYTile ? OALocalizedString(@"edit_tilesource_elliptic_tile") : OALocalizedString(@"pseudo_mercator_projection");
                }
                else if ([key isEqualToString:@"format_sett"])
                {
                    cell.valueLabel.text = [self getFormatString:_sourceFormat];
                    if ([self isOfflineSQLiteDB])
                    {
                        cell.userInteractionEnabled = NO;
                        cell.titleLabel.textColor = [UIColor lightGrayColor];
                    }
                    else
                    {
                        cell.userInteractionEnabled = YES;
                        cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
                    }
                }
                cell.valueLabel.textColor = UIColor.lightGrayColor;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OACustomPickerTableViewCell getCellIdentifier]])
    {
        OACustomPickerTableViewCell* cell;
        cell = (OACustomPickerTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[OACustomPickerTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACustomPickerTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OACustomPickerTableViewCell *)[nib objectAtIndex:0];
        }
        cell.dataArray = _possibleZoomValues;
        int minZoom = _minZoom >= kMinAllowedZoom && _minZoom <= kMaxAllowedZoom ? _minZoom : 1;
        int maxZoom = _maxZoom >= kMinAllowedZoom && _maxZoom <= kMaxAllowedZoom ? _maxZoom : 1;
        [cell.picker selectRow:indexPath.row == 1 ? minZoom - 1 : maxZoom - 1 inComponent:0 animated:NO];
        cell.picker.tag = indexPath.row;
        cell.delegate = self;
        return cell;
    }
    else
        return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item =  [self getItem:indexPath];
    NSString *key = item[@"key"];
    if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        if ([key isEqualToString:@"mercator_sett"] || [key isEqualToString:@"format_sett"])
        {
            OAOnlineTilesSettingsViewController *settingsViewController;
            if ([key isEqualToString:@"mercator_sett"])
                settingsViewController = [[OAOnlineTilesSettingsViewController alloc] initWithEllipticYTile:_isEllipticYTile];
            else if ([key isEqualToString:@"format_sett"])
                settingsViewController = [[OAOnlineTilesSettingsViewController alloc] initWithSourceFormat:_sourceFormat];
            
            settingsViewController.delegate = self;
            [self hidePicker];
            [self.navigationController pushViewController:settingsViewController animated:YES];
        }
        else
        {
            [self.tableView beginUpdates];
            
            if ([self pickerIsShown] && (_pickerIndexPath.row - 1 == indexPath.row))
                [self hideExistingPicker];
            else
            {
                NSIndexPath *newPickerIndexPath = [self calculateIndexPathForNewPicker:indexPath];
                if ([self pickerIsShown])
                    [self hideExistingPicker];
                
                [self showNewPickerAtIndex:newPickerIndexPath];
                _pickerIndexPath = [NSIndexPath indexPathForRow:newPickerIndexPath.row + 1 inSection:indexPath.section];
            }
            
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            [self.tableView endUpdates];
            [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
    }
    else if ([item[@"type"] isEqualToString:[OAInputTableViewCell getCellIdentifier]])
    {
        OAInputTableViewCell *cell = (OAInputTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
        [cell.inputField becomeFirstResponder];
    }
    else if ([item[@"type"] isEqualToString:[OATextMultilineTableViewCell getCellIdentifier]])
    {
        OATextMultilineTableViewCell *cell = (OATextMultilineTableViewCell *) [self.tableView cellForRowAtIndexPath:indexPath];
        [cell.textView becomeFirstResponder];
    }
}

#pragma mark - Additions

- (std::shared_ptr<OsmAnd::IOnlineTileSources::Source>)createEditedTileSource
{
    const auto result = std::shared_ptr<OsmAnd::IOnlineTileSources::Source>(new OsmAnd::OnlineTileSources::Source(QString::fromNSString(_itemName)));

    result->urlToLoad = QString::fromNSString(_itemURL);
    result->minZoom = OsmAnd::ZoomLevel(_minZoom);
    result->maxZoom = OsmAnd::ZoomLevel(_maxZoom);
    result->expirationTimeMillis = _expireTimeMillis;
    result->ellipticYTile = _isEllipticYTile;
    result->referer = QString::fromNSString(_referer);
    result->userAgent = QString::fromNSString(_userAgent);
    
    if (_tileSource != nullptr)
    {
        result->priority = _tileSource->priority;
        result->tileSize = _tileSource->tileSize;
        result->ext = _tileSource->ext;
        result->avgSize = _tileSource->avgSize;
        result->bitDensity = _tileSource->bitDensity;
        result->invertedYTile = _tileSource->invertedYTile;
        result->randoms = _tileSource->randoms;
        result->randomsArray = _tileSource->randomsArray;
        result->rule = _tileSource->rule;
    }
    else if (_sqliteSource != nil)
    {
        result->tileSize = _sqliteSource.tileSize;
        result->ext = QString::fromNSString(_sqliteSource.tileFormat);
        result->bitDensity = _sqliteSource.bitDensity;
        result->invertedYTile = _sqliteSource.isInvertedYTile;
        result->randoms = QString::fromNSString(_sqliteSource.randoms);
        result->randomsArray = _sqliteSource.randomsArray;
        result->rule = QString::fromNSString(_sqliteSource.rule);
    }
    return result;
}

- (NSMutableDictionary *)generateSqlParams
{
    NSMutableDictionary *params = [NSMutableDictionary new];
    params[@"minzoom"] = [NSString stringWithFormat:@"%d", _minZoom];
    params[@"maxzoom"] = [NSString stringWithFormat:@"%d", _maxZoom];
    params[@"url"] = _itemURL;
    params[@"title"] = _itemName;
    params[@"ellipsoid"] = _isEllipticYTile ? @(1) : @(0);
    params[@"timeSupported"] = _expireTimeMillis != -1 ? @"yes" : @"no";
    params[@"expireminutes"] = _expireTimeMillis != -1 ? [NSString stringWithFormat:@"%ld", _expireTimeMillis / 60000] : @"";
    params[@"timecolumn"] = _expireTimeMillis != -1 ? @"yes" : @"no";
    params[@"referer"] = _referer ? _referer : @"";
    params[@"userAgent"] = _userAgent ? _userAgent : @"";
    
    if (_tileSource != nullptr)
    {
        params[@"rule"] = _tileSource->rule.toNSString();
        params[@"randoms"] = _tileSource->randoms.toNSString();
    }
    else if (_sqliteSource != nil)
    {
        params[@"rule"] = _sqliteSource.rule;
        params[@"randoms"] = _sqliteSource.randoms;
    }
    return params;
}

- (void)clearAndUpdateSource
{
    if (_tileSource != nullptr)
    {
        [[NSFileManager defaultManager] removeItemAtPath:[_app.cachePath stringByAppendingPathComponent:_tileSource->name.toNSString()] error:nil];
        if (!_isNewItem)
            _app.resourcesManager->uninstallTilesResource(_tileSource->name);
    }
    else if (_sqliteSource != nil)
    {
        [[OAMapCreatorHelper sharedInstance] removeFile:[_sqliteSource.name stringByAppendingPathExtension:@"sqlitedb"]];
    }
    
    if (_sourceFormat == EOASourceFormatOnline)
    {
        const auto item = [self createEditedTileSource];
        
        OsmAnd::OnlineTileSources::installTileSource(item, QString::fromNSString(_app.cachePath));
        _app.resourcesManager->installTilesResource(item);
        
        OAOnlineTilesResourceItem *res = [[OAOnlineTilesResourceItem alloc] init];
        res.path = [_app.cachePath stringByAppendingPathComponent:_itemName];
        res.title = _itemName;
        
        if (self.delegate)
            [self.delegate onTileSourceSaved:res];
    }
    else if (_sourceFormat == EOASourceFormatSQLite)
    {
        NSMutableDictionary *params = [self generateSqlParams];
        NSString *fileName = [_itemName sanitizeFileName];
        NSString *path = [[NSTemporaryDirectory() stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"sqlitedb"];
        if ([OASQLiteTileSource createNewTileSourceDbAtPath:path parameters:params])
        {
            [[OAMapCreatorHelper sharedInstance] installFile:path newFileName:nil];
            OASqliteDbResourceItem *item = [[OASqliteDbResourceItem alloc] init];
            item.path = [[[OAMapCreatorHelper sharedInstance].filesDir stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"sqlitedb"];
            item.title = _itemName;
            item.fileName = fileName;
            item.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:item.path error:nil] fileSize];
            
            if (self.delegate)
                [self.delegate onTileSourceSaved:item];
        }
    }
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateTileSource
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager moveItemAtURL:[NSURL fileURLWithPath:[_app.cachePath stringByAppendingPathComponent:_tileSource->name.toNSString()]] toURL:[NSURL fileURLWithPath:[_app.cachePath stringByAppendingPathComponent:_itemName]] error:nil];
    
    _app.resourcesManager->uninstallTilesResource(_tileSource->name);
    const auto& item = [self createEditedTileSource];
    OsmAnd::OnlineTileSources::installTileSource(item, QString::fromNSString(_app.cachePath));
    _app.resourcesManager->installTilesResource(item);
    [_app.localResourcesChangedObservable notifyEvent];
    
    OAOnlineTilesResourceItem *res = [[OAOnlineTilesResourceItem alloc] init];
    res.path = [_app.cachePath stringByAppendingPathComponent:_itemName];
    res.title = _itemName;
    
    if (self.delegate)
        [self.delegate onTileSourceSaved:res];
}

- (void)refreshLoadedLayersIfNeeded
{
    NSString *currentFile;
    NSString *overlayFile;
    NSString *underlayFile;
    
    if (_sourceFormat == EOASourceFormatOnline && _tileSource)
    {
        currentFile = [_tileSource->name.toNSString() lastPathComponent];
        if (_app.data.overlayMapSource)
            overlayFile = [_app.data.overlayMapSource.name lastPathComponent];
        if (_app.data.underlayMapSource)
            underlayFile = [_app.data.underlayMapSource.name lastPathComponent];
    }
    else if (_sourceFormat == EOASourceFormatSQLite && _sqliteSource)
    {
        currentFile = [[_sqliteSource getFilePath] lastPathComponent];
        if (_app.data.overlayMapSource)
            overlayFile = [_app.data.overlayMapSource.resourceId lastPathComponent];
        if (_app.data.overlayMapSource)
            underlayFile = [_app.data.underlayMapSource.resourceId lastPathComponent];
    }
    
    if (currentFile)
    {
        if (overlayFile && [overlayFile isEqualToString:currentFile])
            _app.data.overlayMapSource = _app.data.overlayMapSource;
        if (underlayFile && [underlayFile isEqualToString:currentFile])
            _app.data.underlayMapSource = _app.data.underlayMapSource;
    }
}

- (void)updateSqliteSource
{
    if ([_itemName isEqualToString:_sqliteSource.title])
    {
        [_sqliteSource updateInfo:_expireTimeMillis url:_itemURL minZoom:_minZoom maxZoom:_maxZoom isEllipticYTile:_isEllipticYTile title:_itemName];
        
        if (self.delegate && _sqliteDbItem)
            [self.delegate onTileSourceSaved:_sqliteDbItem];
    }
    else
    {
        OAMapCreatorHelper *helper = [OAMapCreatorHelper sharedInstance];
        NSString *fileName = [_itemName sanitizeFileName];
        NSString *path = [[helper.filesDir stringByAppendingPathComponent:fileName] stringByAppendingPathExtension:@"sqlitedb"];
        [helper renameFile:[_sqliteSource.name stringByAppendingPathExtension:@"sqlitedb"] toName:path.lastPathComponent];
        OASQLiteTileSource *newSource = [[OASQLiteTileSource alloc] initWithFilePath:path];
        [newSource updateInfo:_expireTimeMillis url:_itemURL minZoom:_minZoom maxZoom:_maxZoom isEllipticYTile:_isEllipticYTile title:_itemName];
        
        OASqliteDbResourceItem *item = [[OASqliteDbResourceItem alloc] init];
        item.path = path;
        item.title = _itemName;
        item.fileName = fileName;
        item.size = [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
        
        if (self.delegate)
            [self.delegate onTileSourceSaved:item];
    }
}

- (BOOL)isOnlineSource
{
    return _sqliteSource != nil ? [_sqliteSource supportsTileDownload] : YES;
}

- (BOOL)isOfflineSQLiteDB
{
    return _sqliteSource != nil && ![_sqliteSource supportsTileDownload];
}

- (BOOL)needsClearCache
{
    long expireTimeMillis = [self getExpireTimeMillis];
    
    if (_tileSource != nullptr)
    {
        if ((![_itemName isEqualToString:_tileSource->name.toNSString()] ||
             ![_itemURL isEqualToString:_tileSource->urlToLoad.toNSString()] || expireTimeMillis != _tileSource->expirationTimeMillis) &&
            _minZoom == _tileSource->minZoom &&
            _maxZoom == _tileSource->maxZoom &&
            _isEllipticYTile == _tileSource->ellipticYTile &&
            _sourceFormat == EOASourceFormatOnline)
        {
            return NO;
        }
    }
    else if (_sqliteSource != nil)
    {
        if ((![_itemName isEqualToString:_sqliteSource.name] ||
             ![_itemURL isEqualToString:_sqliteSource.urlTemplate] || expireTimeMillis != _sqliteSource.getExpirationTimeMillis) &&
            _minZoom == _sqliteSource.minimumZoomSupported &&
            _maxZoom == _sqliteSource.maximumZoomSupported &&
            _isEllipticYTile == _sqliteSource.isEllipticYTile &&
            _sourceFormat == EOASourceFormatSQLite)
        {
            return NO;
        }
    }
    return YES;
}

- (BOOL)hasChangesBeenMade
{
    long expireTimeMillis = [self getExpireTimeMillis];
    
    if (_tileSource != nullptr)
    {
        return (![_itemName isEqualToString:_tileSource->name.toNSString()] ||
                ![_itemURL isEqualToString:_tileSource->urlToLoad.toNSString()] ||
                _minZoom != _tileSource->minZoom ||
                _maxZoom != _tileSource->maxZoom ||
                expireTimeMillis != _tileSource->expirationTimeMillis ||
                _isEllipticYTile != _tileSource->ellipticYTile ||
                _sourceFormat != EOASourceFormatOnline);
    }
    else if (_sqliteSource != nil)
    {
        if ([_sqliteSource supportsTileDownload])
        {
            return (![_itemName isEqualToString:_sqliteSource.title] ||
                    ![_itemURL isEqualToString:_sqliteSource.urlTemplate] ||
                    _minZoom != _sqliteSource.minimumZoomSupported ||
                    _maxZoom != _sqliteSource.maximumZoomSupported ||
                    expireTimeMillis != _sqliteSource.getExpirationTimeMillis ||
                    _isEllipticYTile != _sqliteSource.isEllipticYTile ||
                    _sourceFormat != EOASourceFormatSQLite);
        }
        else
        {
            return (![_itemName isEqualToString:_sqliteSource.name] ||
                    _minZoom != _sqliteSource.minimumZoomSupported ||
                    _maxZoom != _sqliteSource.maximumZoomSupported ||
                    _isEllipticYTile != _sqliteSource.isEllipticYTile);
        }
    }
    return NO;
}

- (BOOL)pickerIsShown
{
    return _pickerIndexPath != nil;
}

- (void)hidePicker
{
    [self.tableView beginUpdates];
    if ([self pickerIsShown])
        [self hideExistingPicker];
    [self.tableView endUpdates];
}

- (void)hideExistingPicker
{
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row inSection:_pickerIndexPath.section]]
                          withRowAnimation:UITableViewRowAnimationFade];
    _pickerIndexPath = nil;
}

- (NSIndexPath *)calculateIndexPathForNewPicker:(NSIndexPath *)selectedIndexPath
{
    NSIndexPath *newIndexPath;
    if (([self pickerIsShown]) && (_pickerIndexPath.row < selectedIndexPath.row))
        newIndexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row - 1 inSection:kZoomSection];
    else
        newIndexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row  inSection:kZoomSection];
    
    return newIndexPath;
}

- (void)showNewPickerAtIndex:(NSIndexPath *)indexPath
{
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:kZoomSection]];
    [self.tableView insertRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationFade];
}

- (long)getExpireTimeMillis
{
    if (!_expireTimeMinutes)
        _expireTimeMinutes = @"";
    
    long expireTimeMillis = -1;
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([_expireTimeMinutes rangeOfCharacterFromSet:notDigits].location == NSNotFound
        && [_expireTimeMinutes integerValue] <= kMaxExpireMin
        && [_expireTimeMinutes integerValue] >= 0)
    {
        if ([_expireTimeMinutes isEqualToString:@""])
            expireTimeMillis = -1;
        else
            expireTimeMillis = [_expireTimeMinutes integerValue] * 60 * 1000;
    }
    return expireTimeMillis;
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    NSMutableArray *errorArray = [NSMutableArray new];
    
    if ([_itemName isEqualToString:(@"")])
        [errorArray addObject:OALocalizedString(@"res_name_warning")];
    
    if ([_itemURL isEqualToString:(@"")])
    {
        if ([self isOnlineSource])
            [errorArray addObject:OALocalizedString(@"res_url_warning")];
    }
    
    if (_minZoom >= _maxZoom)
        [errorArray addObject:OALocalizedString(@"res_zoom_warning")];
    
    if (_minZoom < kMinAllowedZoom || _minZoom > kMaxAllowedZoom || _maxZoom < kMinAllowedZoom || _maxZoom > kMaxAllowedZoom)
        [errorArray addObject:OALocalizedString(@"res_zoom_invalid_value")];
    
    NSCharacterSet* notDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([_expireTimeMinutes rangeOfCharacterFromSet:notDigits].location == NSNotFound
        && [_expireTimeMinutes integerValue] <= kMaxExpireMin
        && [_expireTimeMinutes integerValue] >= 0)
    {
        if ([_expireTimeMinutes isEqualToString:@""] || [_expireTimeMinutes integerValue] == 0)
            _expireTimeMillis = -1;
        else
            _expireTimeMillis = [_expireTimeMinutes integerValue] * 60 * 1000;
    }
    else
    {
        [errorArray addObject:OALocalizedString(@"res_expire_warning")];
    }
    
    if (errorArray.count > 0)
    {
        NSString *title = [errorArray componentsJoinedByString: @"\n\n"];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:title preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil];
        [alert addAction: cancelAction];
        [alert setPreferredAction:cancelAction];
        [self presentViewController: alert animated: YES completion: nil];
    }
    else
    {
        if ([self needsClearCache] && [self isOnlineSource])
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"osmand_parking_warning") message:OALocalizedString(@"clear_tiles_warning") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleDefault handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self clearAndUpdateSource];
                [self refreshLoadedLayersIfNeeded];
            }]];
            [self presentViewController:alert animated:YES completion:nil];
        }
        else
        {
            if (_tileSource != nullptr && _sourceFormat == EOASourceFormatOnline)
            {
                [self updateTileSource];
            }
            else if (_sqliteSource != nil && _sourceFormat == EOASourceFormatSQLite)
            {
                [self updateSqliteSource];
            }
            [self refreshLoadedLayersIfNeeded];
        }
        
        _baseController.dataInvalidated = YES;
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)onLeftNavbarButtonPressed
{
    if ([self hasChangesBeenMade])
        [self showExitWithoutChangesDialog];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)textChanged:(UITextView *)textView
{
    _expireTimeMinutes = textView.text;
}

- (void)clearButtonPressed:(UIButton *)sender
{
    if (sender.tag == kNameCellTag)
        _itemName = @"";
    else if (sender.tag == kURLCellTag)
        _itemURL = @"";
    
    [self.tableView beginUpdates];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:sender.tag == kNameCellTag ? kNameSection : kURLSection]];
    if ([cell isKindOfClass:OATextMultilineTableViewCell.class])
        ((OATextMultilineTableViewCell *) cell).textView.text = @"";
    [self.tableView endUpdates];
}

- (void)swipeToCloseRecognized:(UIGestureRecognizer *)recognizer
{
    if ([self hasChangesBeenMade])
    {
        recognizer.enabled = NO;
        recognizer.enabled = YES;
        [self showExitWithoutChangesDialog];
    }
}

- (void)showExitWithoutChangesDialog
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"exit_without_saving") message:OALocalizedString(@"unsaved_changes_will_be_lost") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.navigationController popViewControllerAnimated:YES];
    }]];
    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self hidePicker];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - OACustomPickerTableViewCellDelegate

- (void)customPickerValueChanged:(NSString *)value tag: (NSInteger)pickerTag
{
    if (pickerTag == 1)
        _minZoom = [value intValue];
    else if (pickerTag == 2)
        _maxZoom = [value intValue];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_pickerIndexPath.row - 1 inSection:_pickerIndexPath.section]] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - OAOnlineTilesSettingsViewControllerDelegate

- (void)onMercatorChanged:(BOOL)isEllipticYTile
{
    _isEllipticYTile = isEllipticYTile;
    [self.tableView reloadData];
}

- (void)onStorageFormatChanged:(EOASourceFormat)sourceFormat
{
    _sourceFormat = sourceFormat;
    [self.tableView reloadData];
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    CGRect keyboardBounds;
    [[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        UIEdgeInsets insets = [self.tableView contentInset];
        [self.tableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardBounds.size.height, insets.right)];
        [self.tableView setScrollIndicatorInsets:self.tableView.contentInset];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        UIEdgeInsets insets = [self.tableView contentInset];
        [self.tableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0.0, insets.right)];
        [self.tableView setScrollIndicatorInsets:self.tableView.contentInset];
    } completion:nil];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    [self hidePicker];
}

- (void)textViewDidChange:(UITextView *)textView
{
    if (textView.tag == kNameCellTag)
        _itemName = textView.text;
    else if (textView.tag == kURLCellTag)
        _itemURL = textView.text;
    
    [textView sizeToFit];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

@end
