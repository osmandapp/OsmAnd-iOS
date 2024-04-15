//
//  OATrackMenuAppearanceHudViewController.mm
//  OsmAnd
//
//  Created by Skalii on 25.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATrackMenuAppearanceHudViewController.h"
#import "OATrackColoringTypeViewController.h"
#import "OAColorCollectionViewController.h"
#import "OATableViewCustomFooterView.h"
#import "OAFoldersCollectionView.h"
#import "OASlider.h"
#import "OASimpleTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OACollectionSingleLineTableViewCell.h"
#import "OAColorCollectionHandler.h"
#import "OATextLineViewCell.h"
#import "OASegmentSliderTableViewCell.h"
#import "OASegmentedControlCell.h"
#import "OADividerCell.h"
#import "OAImageTextViewCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAOsmAndFormatter.h"
#import "OAGPXDatabase.h"
#import "OAGpxMutableDocument.h"
#import "OAGPXTrackAnalysis.h"
#import "OAGPXAppearanceCollection.h"
#import "OsmAndApp.h"
#import "OAMapPanelViewController.h"
#import "OAIAPHelper.h"
#import "OAPluginPopupViewController.h"
#import "OASegmentedSlider.h"
#import "OARouteStatisticsHelper.h"
#import "OASizes.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"
#import "OAMapSettingsTerrainParametersViewController.h"

#define kColorsSection 1

#define kColorGridOrDescriptionCell 1

@interface OABackupGpx : NSObject

@property (nonatomic) NSInteger color;
@property (nonatomic) BOOL showStartFinish;
@property (nonatomic, assign) BOOL raiseRoutesAboveRelief;
@property (nonatomic) BOOL joinSegments;
@property (nonatomic) BOOL showArrows;
@property (nonatomic) NSString *width;
@property (nonatomic) NSString *coloringType;
@property (nonatomic) EOAGpxSplitType splitType;
@property (nonatomic) EOAGPX3DLineVisualizationByType visualization3dByType;
@property (nonatomic) EOAGPX3DLineVisualizationWallColorType visualization3dWallColorType;
@property (nonatomic) EOAGPX3DLineVisualizationPositionType visualization3dPositionType;

@property (nonatomic) double splitInterval;

@end

@implementation OABackupGpx

@end


@implementation OATrackAppearanceItem

- (instancetype)initWithColoringType:(OAColoringType *)coloringType
                               title:(NSString *)title
                            attrName:(NSString *)attrName
                         isAvailable:(BOOL)isAvailable
                           isEnabled:(BOOL)isEnabled
{
    self = [super init];
    if (self)
    {
        _coloringType = coloringType;
        _title = title;
        _attrName = attrName;
        _isAvailable = isAvailable;
        _isEnabled = isEnabled;
    }
    return self;
}

@end

@interface OATrackMenuAppearanceHudViewController() <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate, UIColorPickerViewControllerDelegate, OATrackColoringTypeDelegate, OAColorsCollectionCellDelegate, OAColorCollectionDelegate, OACollectionTableViewCellDelegate, OATerrainParametersDelegate>

@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIImageView *titleIconView;

@property (weak, nonatomic) IBOutlet UIView *doneButtonContainerView;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *doneButtonTrailingConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomSeparatorHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomSeparatorTopConstraint;

@end

@implementation OATrackMenuAppearanceHudViewController
{
    OAGPXAppearanceCollection *_appearanceCollection;
    NSArray<OAGPXTableSectionData *> *_tableData;

    OATrackAppearanceItem *_selectedItem;
    NSArray<OATrackAppearanceItem *> *_availableColoringTypes;

    NSMutableArray<OAColorItem *> *_sortedColorItems;
    OAColorItem *_selectedColorItem;
    NSIndexPath *_editColorIndexPath;
    BOOL _isNewColorSelected;

    OAGPXTrackWidth *_selectedWidth;
    NSArray<NSString *> *_customWidthValues;

    OAGPXTrackSplitInterval *_selectedSplit;

    OABackupGpx *_backupGpxItem;
    NSMutableArray<OABackupGpx *> *_backupGpxItems;

    OATrackMenuViewControllerState *_reopeningTrackMenuState;
    
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    NSInteger _widthDataSectionIndex;
    NSInteger _splitDataSectionIndex;
    
    NSArray<OAGPX *> *_wholeFolderTracks;
    LeftIconRightStackTitleDescriptionButtonView *_trackView3DEmptyView;
}

- (instancetype)initWithGpx:(OAGPX *)gpx state:(OATrackMenuViewControllerState *)state
{
    self = [super initWithGpx:gpx];
    if (self)
    {
        _reopeningTrackMenuState = state;
    }
    return self;
}

- (instancetype)initWithGpx:(OAGPX *)gpx tracks:(NSArray<OAGPX *> *)tracks state:(OATrackMenuViewControllerState *)state
{
    self = [super initWithGpx:gpx];
    if (self)
    {
        _wholeFolderTracks = tracks;
        _reopeningTrackMenuState = state;
        [self setOldValues];
    }
    return self;
}

- (NSString *)getNibName
{
    return @"OATrackMenuAppearanceHudViewController";
}

- (void)commonInit
{
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];
    _appearanceCollection = [OAGPXAppearanceCollection sharedInstance];

    [self setOldValues];
    [self updateAllValues];
}

- (void)setOldValues
{
    _backupGpxItem = [[OABackupGpx alloc] init];
    _backupGpxItem.showArrows = self.gpx.showArrows;
    _backupGpxItem.showStartFinish = self.gpx.showStartFinish;
    _backupGpxItem.raiseRoutesAboveRelief = self.gpx.raiseRoutesAboveRelief;
    _backupGpxItem.visualization3dByType = self.gpx.visualization3dByType;
    _backupGpxItem.visualization3dWallColorType = self.gpx.visualization3dWallColorType;
    _backupGpxItem.visualization3dPositionType = self.gpx.visualization3dPositionType;
    _backupGpxItem.coloringType = self.gpx.coloringType;
    _backupGpxItem.color = self.gpx.color;
    _backupGpxItem.width = self.gpx.width;
    _backupGpxItem.splitType = self.gpx.splitType;
    _backupGpxItem.splitInterval = self.gpx.splitInterval;
    _backupGpxItem.joinSegments = self.gpx.joinSegments;
    
    if (_wholeFolderTracks)
    {
        _backupGpxItems = [NSMutableArray array];
        for (OAGPX *track in _wholeFolderTracks)
        {
            OABackupGpx *backupItem = [[OABackupGpx alloc] init];
            backupItem.showArrows = track.showArrows;
            backupItem.showStartFinish = track.showStartFinish;
            backupItem.raiseRoutesAboveRelief = track.raiseRoutesAboveRelief;
            backupItem.visualization3dByType = track.visualization3dByType;
            backupItem.visualization3dWallColorType = track.visualization3dWallColorType;
            backupItem.visualization3dPositionType = track.visualization3dPositionType;
            backupItem.coloringType = track.coloringType;
            backupItem.color = track.color;
            backupItem.width = track.width;
            backupItem.splitType = track.splitType;
            backupItem.splitInterval = track.splitInterval;
            backupItem.joinSegments = track.joinSegments;
            [_backupGpxItems addObject:backupItem];
        }
    }
}

- (void) restoreOldValues
{
    self.gpx.showArrows = _backupGpxItem.showArrows;
    self.gpx.showStartFinish = _backupGpxItem.showStartFinish;
    self.gpx.raiseRoutesAboveRelief = _backupGpxItem.raiseRoutesAboveRelief;
    self.gpx.visualization3dByType = _backupGpxItem.visualization3dByType;
    self.gpx.visualization3dWallColorType = _backupGpxItem.visualization3dWallColorType;
    self.gpx.visualization3dPositionType = _backupGpxItem.visualization3dPositionType;
    
    self.gpx.coloringType = _backupGpxItem.coloringType;
    self.gpx.color = _backupGpxItem.color;
    self.gpx.width = _backupGpxItem.width;
    self.gpx.splitType = _backupGpxItem.splitType;
    self.gpx.splitInterval = _backupGpxItem.splitInterval;
    self.gpx.joinSegments = _backupGpxItem.joinSegments;
    
    if (self.isCurrentTrack)
    {
        [self.settings.currentTrackWidth set:_backupGpxItem.width];
        [self.settings.currentTrackShowArrows set:_backupGpxItem.showArrows];
        [self.settings.currentTrackShowStartFinish set:_backupGpxItem.showStartFinish];
        [self.settings.currentTrackRaiseRoutesAboveRelief set:_backupGpxItem.raiseRoutesAboveRelief];
        [self.settings.currentTrackVisualization3dByType set:(int)_backupGpxItem.visualization3dByType];
        [self.settings.currentTrackVisualization3dWallColorType set:(int)_backupGpxItem.visualization3dWallColorType];
        [self.settings.currentTrackVisualization3dPositionType set:(int)_backupGpxItem.visualization3dPositionType];
        
        [self.settings.currentTrackColoringType set:_backupGpxItem.coloringType.length > 0
                ? [OAColoringType getNonNullTrackColoringTypeByName:_backupGpxItem.coloringType]
                : OAColoringType.TRACK_SOLID];
        [self.settings.currentTrackColor set:_backupGpxItem.color];

        [self.doc setWidth:_backupGpxItem.width];
        [self.doc setShowArrows:_backupGpxItem.showArrows];
        [self.doc setShowStartFinish:_backupGpxItem.showStartFinish];
        [self.doc setRaiseRoutesAboveRelief:_backupGpxItem.raiseRoutesAboveRelief];
        [self.doc setVisualization3dByType:_backupGpxItem.visualization3dByType];
        [self.doc setVisualization3dWallColorType:_backupGpxItem.visualization3dWallColorType];
        [self.doc setVisualization3dPositionType:_backupGpxItem.visualization3dPositionType];
        
        [self.doc setColoringType:_backupGpxItem.coloringType];
        [self.doc setColor:_backupGpxItem.color];
    }
    
    if (_wholeFolderTracks)
    {
        for (int i = 0; i < _wholeFolderTracks.count; i++)
        {
            OAGPX *track = _wholeFolderTracks[i];
            OABackupGpx *bakupItem = _backupGpxItems[i];
            track.showArrows = bakupItem.showArrows;
            track.showStartFinish = bakupItem.showStartFinish;
            track.raiseRoutesAboveRelief = bakupItem.raiseRoutesAboveRelief;
            track.visualization3dByType = bakupItem.visualization3dByType;
            track.visualization3dWallColorType = bakupItem.visualization3dWallColorType;
            track.visualization3dPositionType = bakupItem.visualization3dPositionType;
            track.coloringType = bakupItem.coloringType;
            track.color = bakupItem.color;
            track.width = bakupItem.width;
            track.splitType = bakupItem.splitType;
            track.splitInterval = bakupItem.splitInterval;
            track.joinSegments = bakupItem.joinSegments;
        }
    }
}

- (void)updateAllValues
{
    _selectedColorItem = [_appearanceCollection getColorItemWithValue:self.gpx.color];
    if (!_selectedColorItem)
        _selectedColorItem = [_appearanceCollection getDefaultLineColorItem];
    _sortedColorItems = [NSMutableArray arrayWithArray:[_appearanceCollection getAvailableColorsSortingByLastUsed]];

    _selectedWidth = [_appearanceCollection getWidthForValue:self.gpx.width];
    if (!_selectedWidth)
        _selectedWidth = [OAGPXTrackWidth getDefault];

    _selectedSplit = [_appearanceCollection getSplitIntervalForType:self.gpx.splitType];
    if (self.gpx.splitInterval > 0 && self.gpx.splitType != EOAGpxSplitTypeNone)
        _selectedSplit.customValue = _selectedSplit.titles[[_selectedSplit.values indexOfObject:@(self.gpx.splitInterval)]];

    OAColoringType *currentType = [OAColoringType getNonNullTrackColoringTypeByName:self.gpx.coloringType];

    NSMutableArray<OATrackAppearanceItem *> *items = [NSMutableArray array];
    for (OAColoringType *coloringType in [OAColoringType getTrackColoringTypes])
    {
        if ([coloringType isRouteInfoAttribute])
            continue;

        BOOL isAvailable = [coloringType isAvailableInSubscription];
        BOOL isEnabled = [coloringType isAvailableForDrawingTrack:self.doc attributeName:nil];
        OATrackAppearanceItem *item = [[OATrackAppearanceItem alloc] initWithColoringType:coloringType
                                                                                    title:coloringType.title
                                                                                 attrName:nil
                                                                                 isAvailable:isAvailable
                                                                                 isEnabled:isEnabled];
        [items addObject:item];

        if (currentType == coloringType)
            _selectedItem = item;
    }

    NSArray<NSString *> *attributes = [OARouteStatisticsHelper getRouteStatisticAttrsNames:YES];
    for (NSString *attribute in attributes)
    {
        BOOL isAvailable = [OAColoringType.ATTRIBUTE isAvailableInSubscription];
        BOOL isEnabled = [OAColoringType.ATTRIBUTE isAvailableForDrawingTrack:self.doc attributeName:attribute];
        OATrackAppearanceItem *item = [[OATrackAppearanceItem alloc] initWithColoringType:OAColoringType.ATTRIBUTE
                                                                                    title:OALocalizedString([NSString stringWithFormat:@"%@_name", attribute])
                                                                                 attrName:attribute
                                                                              isAvailable:isAvailable
                                                                                isEnabled:isEnabled];
        [items addObject:item];

        if (currentType == OAColoringType.ATTRIBUTE && [self.gpx.coloringType isEqualToString:attribute])
            _selectedItem = item;
    }

    _availableColoringTypes = items;

    NSMutableArray *customWidthValues = [NSMutableArray array];
    for (NSInteger i = [OAGPXTrackWidth getCustomTrackWidthMin]; i <= [OAGPXTrackWidth getCustomTrackWidthMax]; i++)
    {
        [customWidthValues addObject:[NSString stringWithFormat:@"%li", i]];
    }
    _customWidthValues = customWidthValues;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.sectionHeaderHeight = 36.;
    self.tableView.sectionFooterHeight = 0.001;
    [self.tableView registerClass:OATableViewCustomFooterView.class
        forHeaderFooterViewReuseIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    [self.tableView registerNib:[UINib nibWithNibName:[OAButtonTableViewCell getCellIdentifier] bundle:nil] forCellReuseIdentifier:[OAButtonTableViewCell getCellIdentifier]];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:[UITableViewCell getCellIdentifier]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([_selectedItem.coloringType isTrackSolid])
    {
        if (_tableData.count > kColorsSection)
        {
            OAGPXTableSectionData *colorSection = _tableData[kColorsSection];
            if (colorSection.subjects.count - 1 >= kColorGridOrDescriptionCell)
            {
                NSIndexPath *colorIndexPath = [NSIndexPath indexPathForRow:kColorGridOrDescriptionCell inSection:kColorsSection];
                [self.tableView reloadRowsAtIndexPaths:@[colorIndexPath] withRowAnimation:UITableViewRowAnimationNone];

                OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:colorIndexPath];
                NSIndexPath *selectedIndexPath = [[colorCell getCollectionHandler] getSelectedIndexPath];
                if (selectedIndexPath.row != NSNotFound && ![colorCell.collectionView.indexPathsForVisibleItems containsObject:selectedIndexPath])
                {
                    [colorCell.collectionView scrollToItemAtIndexPath:selectedIndexPath
                                                     atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally
                                                             animated:YES];
                }
            }
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self checkColoringAvailability];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
        [self.doneButton addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:12. padding:0.];
}

- (void)applyLocalization
{
    [self.titleView setText:OALocalizedString(@"shared_string_appearance")];
}

- (OAGPXTableCellData *) generateDescriptionCellData:(NSString *)key description:(NSString *)description
{
    return [OAGPXTableCellData withData:@{
            kTableKey: key,
            kCellType: [OATextLineViewCell getCellIdentifier],
            kCellTitle: description
    }];
}

- (void)setupView
{
    self.titleIconView.image = [UIImage templateImageNamed:@"ic_custom_appearance"];
    self.titleIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorSecondary];

    [self.doneButton addBlurEffect:[ThemeManager shared].isLightTheme cornerRadius:12. padding:0.];
    [self.doneButton setAttributedTitle:
                    [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_done")
                                                    attributes:@{ NSFontAttributeName:[UIFont scaledBoldSystemFontOfSize:17.] }]
                               forState:UIControlStateNormal];
}

- (OAGPXTableCellData *) generateGridOrDescriptionCellData
{
    OAGPXTableCellData *gridOrDescriptionCellData;
    if ([_selectedItem.coloringType isTrackSolid])
    {
        gridOrDescriptionCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"color_grid",
            kCellType: [OACollectionSingleLineTableViewCell getCellIdentifier]
        }];
    }
    else if ([_selectedItem.coloringType isGradient])
    {
        gridOrDescriptionCellData = [self generateDescriptionCellData:@"color_elevation_description" description:OALocalizedString(@"route_line_color_elevation_description")];
    }
    else if ([_selectedItem.coloringType isRouteInfoAttribute])
    {
        gridOrDescriptionCellData = [self generateDescriptionCellData:@"color_attribute_description" description: OALocalizedString(@"white_color_undefined")];
    }
    return gridOrDescriptionCellData;
}

- (OAGPXTableCellData *) generateAllColorsCellData
{
    return [OAGPXTableCellData withData:@{
        kTableKey: @"all_colors",
        kCellType: [OASimpleTableViewCell getCellIdentifier],
        kCellTitle: OALocalizedString(@"shared_string_all_colors"),
        kCellTintColor: [UIColor colorNamed:ACColorNameIconColorActive]
    }];
}

- (UIMenu *)createMenuForKey:(NSString *)key button:(UIButton *)button
{
    if ([key isEqualToString:@"visualization_3d_visualized_by"])
    {
        return [self createVisualizedByMenuForCellButton:button];
    }
    else if ([key isEqualToString:@"visualization_3d_wall_color"])
    {
        return [self createWallColorMenuForCellButton:button];
    }
    else if ([key isEqualToString:@"visualization_3d_track_line"])
    {
        return [self createTrackLineMenuForCellButton:button];
    }
    NSAssert(NO, @"createMenuForKey key is not implemented");
    return nil;
}

- (void)configureVisualization3dByType:(EOAGPX3DLineVisualizationByType)type
{
    self.gpx.visualization3dByType = type;
    if (_wholeFolderTracks)
    {
        for (OAGPX *track in _wholeFolderTracks)
            track.visualization3dByType = type;
    }

    if (self.isCurrentTrack)
    {
        [self.doc setVisualization3dByType:self.gpx.visualization3dByType];
        [[_app updateRecTrackOnMapObservable] notifyEvent];
    }
    else
    {
        [[_app updateGpxTracksOnMapObservable] notifyEvent];
    }
    [self generateData];
    [UIView transitionWithView:self.tableView
                      duration:0.35f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void) {
        [self.tableView reloadData];
    } completion:nil];
}

- (void)configureVisualization3dWallColorType:(EOAGPX3DLineVisualizationWallColorType)type
{
    self.gpx.visualization3dWallColorType = type;
    if (_wholeFolderTracks)
    {
        for (OAGPX *track in _wholeFolderTracks)
            track.visualization3dWallColorType = type;
    }

    if (self.isCurrentTrack)
    {
        [self.doc setVisualization3dWallColorType:self.gpx.visualization3dWallColorType];
        [[_app updateRecTrackOnMapObservable] notifyEvent];
    }
    else
    {
        [[_app updateGpxTracksOnMapObservable] notifyEvent];
    }
    [self generateData];
    [UIView transitionWithView:self.tableView
                      duration:0.35f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void) {
        [self.tableView reloadData];
    } completion:nil];
}

- (void)configureVisualizationPositionColorType:(EOAGPX3DLineVisualizationPositionType)type
{
    self.gpx.visualization3dPositionType = type;
    if (_wholeFolderTracks)
    {
        for (OAGPX *track in _wholeFolderTracks)
            track.visualization3dPositionType = type;
    }

    if (self.isCurrentTrack)
    {
        [self.doc setVisualization3dPositionType:self.gpx.visualization3dPositionType];
        [[_app updateRecTrackOnMapObservable] notifyEvent];
    }
    else
    {
        [[_app updateGpxTracksOnMapObservable] notifyEvent];
    }
    [self generateData];
    [UIView transitionWithView:self.tableView
                      duration:0.35f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void) {
        [self.tableView reloadData];
    } completion:nil];
}

- (UIMenu *)createVisualizedByMenuForCellButton:(UIButton *)button
{
    NSMutableArray<UIMenuElement *> *menuElements = [NSMutableArray array];
    __weak __typeof(self) weakSelf = self;
    UIAction *none = [UIAction actionWithTitle:OALocalizedString(@"shared_string_none")
                                             image:nil
                                        identifier:nil
                                           handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf configureVisualization3dByType:EOAGPX3DLineVisualizationByTypeNone];
    }];
    [menuElements addObject:none];

    UIAction *altitude = [UIAction actionWithTitle:OALocalizedString(@"altitude")
                                          image:nil
                                     identifier:nil
                                        handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf configureVisualization3dByType:EOAGPX3DLineVisualizationByTypeAltitude];
    }];
    [menuElements addObject:altitude];
    
    UIAction *fixedHeight = [UIAction actionWithTitle:OALocalizedString(@"fixed_height")
                                          image:nil
                                     identifier:nil
                                        handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf configureVisualization3dByType:EOAGPX3DLineVisualizationByTypeFixedHeight];
    }];
    [menuElements addObject:fixedHeight];
    
    NSInteger selectedIndex = self.gpx.visualization3dByType;
    if (selectedIndex >= 0 && selectedIndex < menuElements.count)
        ((UIAction *)menuElements[selectedIndex]).state = UIMenuElementStateOn;
    
    NSString *title = [menuElements[selectedIndex] title];
    
    return [self createChevronMenu:title button:button menuElements:[menuElements copy]];
}

- (UIMenu *)createWallColorMenuForCellButton:(UIButton *)button
{
    NSMutableArray<UIMenuElement *> *menuElements = [NSMutableArray array];
    __weak __typeof(self) weakSelf = self;
    UIAction *none = [UIAction actionWithTitle:OALocalizedString(@"shared_string_none")
                                             image:nil
                                        identifier:nil
                                           handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf configureVisualization3dWallColorType:EOAGPX3DLineVisualizationWallColorTypeNone];
    }];
    [menuElements addObject:none];

    UIAction *solid = [UIAction actionWithTitle:OALocalizedString(@"track_coloring_solid")
                                          image:nil
                                     identifier:nil
                                        handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf configureVisualization3dWallColorType:EOAGPX3DLineVisualizationWallColorTypeSolid];
    }];
    [menuElements addObject:solid];
    
    UIAction *downwardGradient = [UIAction actionWithTitle:OALocalizedString(@"downward_gradient")
                                          image:nil
                                     identifier:nil
                                        handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf configureVisualization3dWallColorType:EOAGPX3DLineVisualizationWallColorTypeDownwardGradient];
    }];
    [menuElements addObject:downwardGradient];
    
    UIAction *upwardGradient = [UIAction actionWithTitle:OALocalizedString(@"upward_gradient")
                                          image:nil
                                     identifier:nil
                                        handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf configureVisualization3dWallColorType:EOAGPX3DLineVisualizationWallColorTypeUpwardGradient];
    }];
    [menuElements addObject:upwardGradient];
    
    NSInteger selectedIndex = self.gpx.visualization3dWallColorType;
    if (selectedIndex >= 0 && selectedIndex < menuElements.count)
        ((UIAction *)menuElements[selectedIndex]).state = UIMenuElementStateOn;
    
    NSString *title = [menuElements[selectedIndex] title];
    
    return [self createChevronMenu:title button:button menuElements:[menuElements copy]];
}

- (UIMenu *)createTrackLineMenuForCellButton:(UIButton *)button
{
    NSMutableArray<UIMenuElement *> *menuElements = [NSMutableArray array];
    __weak __typeof(self) weakSelf = self;
    UIAction *top = [UIAction actionWithTitle:OALocalizedString(@"shared_string_top")
                                             image:nil
                                        identifier:nil
                                           handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf configureVisualizationPositionColorType:EOAGPX3DLineVisualizationPositionTypeTop];
    }];
    [menuElements addObject:top];

    UIAction *bottom = [UIAction actionWithTitle:OALocalizedString(@"shared_string_bottom")
                                          image:nil
                                     identifier:nil
                                        handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf configureVisualizationPositionColorType:EOAGPX3DLineVisualizationPositionTypeBottom];
    }];
    [menuElements addObject:bottom];
    
    UIAction *topBottom = [UIAction actionWithTitle:OALocalizedString(@"shared_string_top_bottom")
                                          image:nil
                                     identifier:nil
                                        handler:^(__kindof UIAction * _Nonnull action) {
        [weakSelf configureVisualizationPositionColorType:EOAGPX3DLineVisualizationPositionTypeTopBottom];
    }];
    [menuElements addObject:topBottom];
    
    NSInteger selectedIndex = self.gpx.visualization3dPositionType;
    if (selectedIndex >= 0 && selectedIndex < menuElements.count)
        ((UIAction *)menuElements[selectedIndex]).state = UIMenuElementStateOn;
    
    NSString *title = [menuElements[selectedIndex] title];
    
    return [self createChevronMenu:title button:button menuElements:[menuElements copy]];
}

- (UIMenu *)createChevronMenu:(NSString *)title
                       button:(UIButton *)button
                 menuElements:(NSArray<UIMenuElement *> *)menuElements
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:title];
    
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    UIImageSymbolConfiguration *config = [UIImageSymbolConfiguration configurationWithPointSize:16 weight:UIImageSymbolWeightBold];
    UIImage *image = [UIImage systemImageNamed:@"chevron.up.chevron.down" withConfiguration:config];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    attachment.image = image;
    
    NSAttributedString *attachmentString = [NSAttributedString attributedStringWithAttachment:attachment];
    [attributedString appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
    [attributedString appendAttributedString:attachmentString];
    
    [button setAttributedTitle:attributedString forState:UIControlStateNormal];
    
    return [UIMenu menuWithChildren:menuElements];
}

- (void)generateData
{
    NSMutableArray<OAGPXTableSectionData *> *appearanceSections = [NSMutableArray array];
        
    OAGPXTableCellData *directionCellData = [OAGPXTableCellData withData:@{
            kTableKey:@"direction_arrows",
            kCellType:[OASwitchTableViewCell getCellIdentifier],
            kCellTitle:OALocalizedString(@"gpx_direction_arrows")
    }];

    OAGPXTableCellData *startFinishCellData = [OAGPXTableCellData withData:@{
            kTableKey:@"start_finish_icons",
            kCellType:[OASwitchTableViewCell getCellIdentifier],
            kCellTitle:OALocalizedString(@"track_show_start_finish_icons")
    }];
    
//    BOOL mapsPlusPurchased = [OAIAPHelper isSubscribedToMaps] || [OAIAPHelper isFullVersionPurchased];
//    
//    OAGPXTableCellData *visualization3DCellData = [OAGPXTableCellData withData:@{
//            kTableKey:@"visualization_3D",
//            kCellType:[OAIAPHelper isOsmAndProAvailable] || mapsPlusPurchased
//            ? [OASwitchTableViewCell getCellIdentifier]
//            : [OAButtonTableViewCell getCellIdentifier],
//            kCellTitle:OALocalizedString(@"track_appearance_3D_visualization")
//    }];

    [appearanceSections addObject:[OAGPXTableSectionData withData:@{
        kTableSubjects: @[directionCellData, startFinishCellData]
    }]];

    NSMutableArray<OAGPXTableCellData *> *colorsCells = [NSMutableArray array];

    OAGPXTableCellData *colorTitleCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"color_title",
            kCellType: [OAValueTableViewCell getCellIdentifier],
            kTableValues: @{
                @"string_value": _selectedItem.title,
                @"accessibility_label": OALocalizedString(@"shared_string_coloring"),
                @"accessibility_value": _selectedItem.title,
                @"accessoryType": @(UITableViewCellAccessoryDisclosureIndicator)
            },
            kCellTitle: OALocalizedString(@"shared_string_coloring"),
    }];

    [colorsCells addObject:colorTitleCellData];

    OAGPXTableCellData *gridOrDescriptionCellData = [self generateGridOrDescriptionCellData];
    [colorsCells addObject:gridOrDescriptionCellData];

    if ([_selectedItem.coloringType isTrackSolid])
    {
        [colorsCells addObject:[self generateAllColorsCellData]];
    }
    else if ([_selectedItem.coloringType isGradient])
    {
        [colorsCells addObject:[self generateDataForColorElevationGradientCellData]];

        if ([self isSelectedTypeSpeed] || [self isSelectedTypeAltitude])
        {
            [colorsCells addObject:[self generateDescriptionCellData:@"color_extra_description" description:OALocalizedString(@"grey_color_undefined")]];
        }
    }

    OAGPXTableSectionData *colorsSectionData = [OAGPXTableSectionData withData:@{
        kTableKey: @"colors_section",
        kTableSubjects: colorsCells,
        kSectionHeaderHeight: @36.
    }];

    [appearanceSections addObject:colorsSectionData];

    NSMutableArray<OAGPXTableCellData *> *widthCells = [NSMutableArray array];
    OAGPXTableCellData *widthTitleCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"width_title",
            kCellType: [OAValueTableViewCell getCellIdentifier],
            kTableValues: @{ @"string_value": _selectedWidth.title },
            kCellTitle: OALocalizedString(@"shared_string_width")
    }];
    [widthCells addObject:widthTitleCellData];

    if ([_appearanceCollection getAvailableWidth].count > 1)
    {
        OAGPXTableCellData *widthValueCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"width_value",
                kCellType: [OASegmentedControlCell getCellIdentifier],
                kTableValues: @{ @"array_value": [_appearanceCollection getAvailableWidth] },
                kCellToggle: @YES
        }];
        [widthCells addObject:widthValueCellData];
    }
    [widthCells addObject:[OAGPXTableCellData withData:@{
        kTableKey: @"width_empty_space",
        kCellType: [OADividerCell getCellIdentifier],
        kTableValues: @{ @"float_value": @14.0 }
    }]];

    if ([_selectedWidth isCustom])
        [widthCells addObject:[self generateDataForWidthCustomSliderCellData]];

    OAGPXTableSectionData *widthSectionData = [OAGPXTableSectionData withData:@{
        kTableKey: @"width_section",
        kTableSubjects: widthCells,
        kSectionHeaderHeight: @36.
    }];

    _widthDataSectionIndex = appearanceSections.count;
    [appearanceSections addObject:widthSectionData];
    
    NSMutableArray *track3DSectionItems = [NSMutableArray array];
    
    // TODO: purchase type and isRelief3D
    BOOL mapsPlusPurchased = YES;//[OAIAPHelper isSubscribedToMaps] || [OAIAPHelper isFullVersionPurchased];
    if (mapsPlusPurchased)
    {
        // 3d Section
        OAGPXTableCellData *visualizedByCellData = [OAGPXTableCellData withData:@{
            kTableKey:@"visualization_3d_visualized_by",
            kCellType:[OAButtonTableViewCell getCellIdentifier],
            kCellTitle:OALocalizedString(@"visualization_3d_visualized_by")
        }];
        [track3DSectionItems addObject:visualizedByCellData];
        if (self.gpx.visualization3dByType != EOAGPX3DLineVisualizationByTypeNone)
            {
            OAGPXTableCellData *wallColorCellData = [OAGPXTableCellData withData:@{
                kTableKey:@"visualization_3d_wall_color",
                kCellType:[OAButtonTableViewCell getCellIdentifier],
                kCellTitle:OALocalizedString(@"visualization_3d_wall_color")
            }];
                [track3DSectionItems addObject:wallColorCellData];
            OAGPXTableCellData *trackLineData = [OAGPXTableCellData withData:@{
                kTableKey:@"visualization_3d_track_line",
                kCellType:[OAButtonTableViewCell getCellIdentifier],
                kCellTitle:OALocalizedString(@"visualization_3d_track_line")
            }];
                [track3DSectionItems addObject:trackLineData];
            // BOOL isRelief3D = [OAIAPHelper isOsmAndProAvailable];
            // if (isRelief3D && [plugin.enable3DMaps get])
            //  OASRTMPlugin *plugin = (OASRTMPlugin *)[OAPluginsHelper getPlugin:OASRTMPlugin.class];
            NSString *alphaValueString = OALocalizedString(@"shared_string_none");
                // TODO:
            double scaleValue = _app.data.verticalExaggerationScale;
            if (scaleValue > 1)
            {
                alphaValueString = [NSString stringWithFormat:@"x%.1f", scaleValue];
            }
            OAGPXTableCellData *verticalExaggerationData = [OAGPXTableCellData withData:@{
                kTableKey:@"vertical_exaggeration",
                kCellType:[OAValueTableViewCell getCellIdentifier],
                kCellTitle:OALocalizedString(@"vertical_exaggeration"),
                kCellIconNameKey:@"ic_custom_terrain_scale",
                kCellIconTintColor:[UIColor colorNamed:ACColorNameIconColorSelected],
                kTableValues:@{
                    @"string_value":alphaValueString,
                    @"accessibility_label":OALocalizedString(@"vertical_exaggeration"),
                    @"accessibility_value":alphaValueString,
                    @"accessoryType":@(UITableViewCellAccessoryDisclosureIndicator)
                },
            }];
            [track3DSectionItems addObject:verticalExaggerationData];
        }
    }

    [appearanceSections addObject:[OAGPXTableSectionData withData:@{
        kTableKey:@"3d_track_section",
        kSectionHeader:[OALocalizedString(@"track_3d") upperCase],
        kSectionHeaderHeight:@36.,
        kTableSubjects:mapsPlusPurchased ? track3DSectionItems : @[[OAGPXTableCellData withData:@{
            kTableKey:@"track_view_3d_empty_state",
            kCellType:[UITableViewCell getCellIdentifier],
        }]]
    }]];

    NSMutableArray<OAGPXTableCellData *> *splitCells = [NSMutableArray array];
    OAGPXTableCellData *splitTitleCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"split_title",
            kCellType: [OAValueTableViewCell getCellIdentifier],
            kTableValues: @{ @"string_value": _selectedSplit.title },
            kCellTitle: OALocalizedString(@"gpx_split_interval")
    }];

    [splitCells addObject:splitTitleCellData];

    OAGPXTableCellData *sliderOrDescriptionCellData = [self generateDataForSplitCustomSliderCellData];

    OAGPXTableCellData *splitValueCellData = [OAGPXTableCellData withData:@{
        kTableKey: @"split_value",
        kCellType: [OASegmentedControlCell getCellIdentifier],
        kTableValues: @{ @"array_value": [_appearanceCollection getAvailableSplitIntervals] },
        kCellToggle: @NO
    }];

    [splitCells addObject:splitValueCellData];
    [splitCells addObject:sliderOrDescriptionCellData];

    OAGPXTableSectionData *splitSectionData = [OAGPXTableSectionData withData:@{
        kTableKey: @"split_section",
        kTableSubjects: splitCells,
        kSectionHeaderHeight: @36.,
        kSectionFooter: OALocalizedString(@"gpx_split_interval_descr")
    }];

    _splitDataSectionIndex = appearanceSections.count;
    [appearanceSections addObject:splitSectionData];

    OAGPXTableCellData *joinGapsCellData = [OAGPXTableCellData withData:@{
            kTableKey:@"join_gaps",
            kCellType:[OASwitchTableViewCell getCellIdentifier],
            kCellTitle:OALocalizedString(@"gpx_join_gaps")
    }];

    [appearanceSections addObject:[OAGPXTableSectionData withData:@{
            kTableSubjects: @[joinGapsCellData],
            kSectionHeaderHeight: @14.,
            kSectionFooter: OALocalizedString(@"gpx_join_gaps_descr")
    }]];

    OAGPXTableCellData *resetCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"reset",
            kCellType: [OARightIconTableViewCell getCellIdentifier],
            kCellTitle: OALocalizedString(@"reset_to_original"),
            kCellRightIconName: @"ic_custom_reset"
    }];

    [appearanceSections addObject:[OAGPXTableSectionData withData:@{
            kTableSubjects: @[resetCellData],
            kSectionHeaderHeight: @42.,
            kSectionHeader:OALocalizedString(@"shared_string_actions"),
            kSectionFooterHeight: @60.
    }]];

    _tableData = appearanceSections;
}

- (CGFloat)initialMenuHeight
{
    return self.topHeaderContainerView.frame.origin.y + self.topHeaderContainerView.frame.size.height + [OAUtilities getBottomMargin];
}

- (BOOL)adjustCentering
{
    return YES;
}

- (BOOL)stopChangingHeight:(UIView *)view
{
    return [view isKindOfClass:[UISlider class]]
            || [view isKindOfClass:[UISegmentedControl class]]
            || [view isKindOfClass:[UICollectionView class]];
}

- (OAGPXTableCellData *)generateDataForColorElevationGradientCellData
{

    OAGPXTableCellData *colorGradientCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"color_elevation_gradient",
            kCellType: [OAImageTextViewCell getCellIdentifier],
            kTableValues: @{
                @"extra_desc": [self generateExtraDescription],
                @"desc_font_size": @([self isSelectedTypeSlope] ? 15 : 17)
            },
            kCellDesc: [self generateDescription],
            kCellRightIconName: [self isSelectedTypeSlope] ? @"img_track_gradient_slope" : @"img_track_gradient_speed"
    }];

    return colorGradientCellData;
}

- (NSString *) generateDescription
{
    if ([self isSelectedTypeSpeed])
        return [OAOsmAndFormatter getFormattedSpeed:0.0];
    else if ([self isSelectedTypeAltitude])
        return [OAOsmAndFormatter getFormattedAlt:self.analysis.minElevation];
    else if ([self isSelectedTypeSlope])
        return OALocalizedString(@"grey_color_undefined");
    return @"";
}

- (NSString *) generateExtraDescription
{
    if ([self isSelectedTypeSpeed])
        return [OAOsmAndFormatter getFormattedSpeed:
                MAX(self.analysis.maxSpeed, [[OAAppSettings sharedManager].applicationMode.get getMaxSpeed])];
    else if ([self isSelectedTypeAltitude])
        return [OAOsmAndFormatter getFormattedAlt:
                MAX(self.analysis.maxElevation, self.analysis.minElevation + 50)];
    return @"";
}

- (OAGPXTableCellData *)generateDataForWidthCustomSliderCellData
{
    OAGPXTableCellData *customSliderCellData = [OAGPXTableCellData withData:@{
            kTableKey: @"width_custom_slider",
            kCellType: [OASegmentSliderTableViewCell getCellIdentifier],
            kTableValues: @{
                    @"custom_string_value": _selectedWidth.customValue,
                    @"array_value": _customWidthValues,
                    @"has_top_labels": @NO,
                    @"has_bottom_labels": @YES,
            }
    }];

    return customSliderCellData;
}

- (OAGPXTableCellData *)generateDataForSplitCustomSliderCellData
{
    OAGPXTableCellData *sliderOrDescriptionCellData;
    if (_selectedSplit.isCustom)
    {
        sliderOrDescriptionCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"split_custom_slider",
                kCellType: [OASegmentSliderTableViewCell getCellIdentifier],
                kCellTitle: OALocalizedString(@"shared_string_interval"),
                kTableValues: @{
                        @"custom_string_value": _selectedSplit.customValue,
                        @"array_value": _selectedSplit.titles,
                        @"has_top_labels": @YES,
                        @"has_bottom_labels": @YES,
                }
        }];
    }
    else
    {
        sliderOrDescriptionCellData = [OAGPXTableCellData withData:@{
                kTableKey: @"split_none_descr",
                kCellType: [OATextLineViewCell getCellIdentifier],
                kCellTitle: OALocalizedString(@"gpx_split_interval_none_descr")
        }];
    }

    return sliderOrDescriptionCellData;
}

- (OAGPXTableCellData *)getCellData:(NSIndexPath *)indexPath
{
    return _tableData[indexPath.section].subjects[indexPath.row];
}

- (void)doAdditionalLayout
{
    [super doAdditionalLayout];
    BOOL isRTL = [self.doneButtonContainerView isDirectionRTL];
    self.doneButtonTrailingConstraint.constant = [self isLandscape]
            ? (isRTL ? [self getLandscapeViewWidth] - [OAUtilities getLeftMargin] + 10. : 0.)
            : [OAUtilities getLeftMargin] + 10.;
    self.doneButtonContainerView.hidden = ![self isLandscape] && self.currentState == EOADraggableMenuStateFullScreen;
}

- (CGFloat)getToolbarHeight
{
    return self.currentState == EOADraggableMenuStateInitial ? [OAUtilities getBottomMargin] : 0.;
}

- (BOOL)isSelectedTypeSlope
{
    return _selectedItem.coloringType == OAColoringType.SLOPE;
}

- (BOOL)isSelectedTypeSpeed
{
    return _selectedItem.coloringType == OAColoringType.SPEED;
}

- (BOOL)isSelectedTypeAltitude
{
    return _selectedItem.coloringType == OAColoringType.ALTITUDE;
}

- (void)checkColoringAvailability
{
    BOOL isAvailable = [_selectedItem.coloringType isAvailableInSubscription];
    if (!isAvailable)
        [OAPluginPopupViewController askForPlugin:kInAppId_Addon_Advanced_Widgets];
    self.doneButton.userInteractionEnabled = isAvailable;
    [self.doneButton setTitleColor:isAvailable ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameIconColorDisabled]
                           forState:UIControlStateNormal];
}

- (void)hide
{
    [self hide:YES duration:.2 onComplete:^{
        if (_reopeningTrackMenuState)
        {
            [self restoreOldValues];
            if (_reopeningTrackMenuState.openedFromTracksList)
            {
                UITabBarController *myPlacesViewController =
                        [[UIStoryboard storyboardWithName:@"MyPlaces" bundle:nil] instantiateInitialViewController];
                [myPlacesViewController setSelectedIndex:1];
                [[OARootViewController instance].navigationController pushViewController:myPlacesViewController animated:YES];
            }
            else
            {
                [self.mapPanelViewController openTargetViewWithGPX:self.gpx
                                                      trackHudMode:EOATrackMenuHudMode
                                                             state:_reopeningTrackMenuState];
            }
        }

        if (self.isCurrentTrack)
            [[_app updateRecTrackOnMapObservable] notifyEvent];
        else
            [[_app updateGpxTracksOnMapObservable] notifyEvent];
    }];
}

- (void)openColorPickerWithColor:(OAColorItem *)colorItem
{
    UIColorPickerViewController *colorViewController = [[UIColorPickerViewController alloc] init];
    colorViewController.delegate = self;
    colorViewController.selectedColor = [colorItem getColor];
    [self.navigationController presentViewController:colorViewController animated:YES completion:nil];
}

- (IBAction)onBackButtonPressed:(id)sender
{
    [self hide];
}

- (IBAction)onDoneButtonPressed:(id)sender
{
    [self hide:YES duration:.2 onComplete:^{
        if (_isNewColorSelected)
            [_appearanceCollection selectColor:_selectedColorItem];

        [[OAGPXDatabase sharedDb] save];
        if (self.isCurrentTrack)
        {
            [self.settings.currentTrackWidth set:self.gpx.width];
            [self.settings.currentTrackShowArrows set:self.gpx.showArrows];
            [self.settings.currentTrackShowStartFinish set:self.gpx.showStartFinish];
            [self.settings.currentTrackRaiseRoutesAboveRelief set:self.gpx.raiseRoutesAboveRelief];
            [self.settings.currentTrackVisualization3dByType set:(int)self.gpx.visualization3dByType];
            [self.settings.currentTrackVisualization3dWallColorType set:(int)self.gpx.visualization3dWallColorType];
            [self.settings.currentTrackVisualization3dPositionType set:(int)self.gpx.visualization3dPositionType];
            
            [self.settings.currentTrackColoringType set:self.gpx.coloringType.length > 0
                    ? [OAColoringType getNonNullTrackColoringTypeByName:self.gpx.coloringType]
                    : OAColoringType.TRACK_SOLID];
            [self.settings.currentTrackColor set:self.gpx.color];

            [self.doc setWidth:self.gpx.width];
            [self.doc setShowArrows:self.gpx.showArrows];
            [self.doc setShowStartFinish:self.gpx.showStartFinish];
            [self.doc setRaiseRoutesAboveRelief:self.gpx.raiseRoutesAboveRelief];
            [self.doc setVisualization3dByType:self.gpx.visualization3dByType];
            [self.doc setVisualization3dWallColorType:self.gpx.visualization3dWallColorType];
            [self.doc setVisualization3dPositionType:self.gpx.visualization3dPositionType];
            [self.doc setColoringType:self.gpx.coloringType];
            [self.doc setColor:self.gpx.color];
        }
        if (_reopeningTrackMenuState)
        {
            if (_reopeningTrackMenuState.openedFromTracksList)
            {
                UITabBarController *myPlacesViewController =
                        [[UIStoryboard storyboardWithName:@"MyPlaces" bundle:nil] instantiateInitialViewController];
                [myPlacesViewController setSelectedIndex:1];
                [[OARootViewController instance].navigationController pushViewController:myPlacesViewController animated:YES];
            }
            else
            {
                [self.mapPanelViewController openTargetViewWithGPX:self.gpx
                                                      trackHudMode:EOATrackMenuHudMode
                                                             state:_reopeningTrackMenuState];
            }
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _tableData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _tableData[section].subjects.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _tableData[section].header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    UITableViewCell *outCell = nil;
    if ([cellData.type isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            [cell setCustomLeftSeparatorInset:YES];
            cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
        }
        if (cell)
        {
            cell.accessoryType =  [cellData.values.allKeys containsObject:@"accessoryType"]
                ? ((UITableViewCellAccessoryType) [cellData.values[@"accessoryType"] integerValue])
                : UITableViewCellAccessoryNone;
            cell.selectionStyle = cell.accessoryType == UITableViewCellAccessoryDisclosureIndicator ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;

            cell.titleLabel.text = cellData.title;
            cell.valueLabel.text = cellData.values[@"string_value"];

            cell.accessibilityLabel = cell.titleLabel.text;
            cell.accessibilityValue = cell.valueLabel.text;

        }
        return cell;
    }
    else if ([cellData.type isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = cellData.title;
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            cell.rightIconView.image = [UIImage templateImageNamed:cellData.rightIconName];
            cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
        }
        return cell;
    }
    else if ([cellData.type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell =
                [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., kPaddingOnSideOfContent, 0., 0.);
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.switchView.on = [self isOn:cellData];
            cell.titleLabel.text = cellData.title;

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OAImageTextViewCell getCellIdentifier]])
    {
        OAImageTextViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAImageTextViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAImageTextViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OAImageTextViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., DeviceScreenWidth, 0., 0.);
        }
        if (cell)
        {
            NSString *extraDesc = cellData.values[@"extra_desc"];
            [cell showExtraDesc:extraDesc && extraDesc.length > 0];

            UIImage *image = [UIImage imageNamed:cellData.rightIconName];
            cell.iconView.image = [cell isDirectionRTL] ? image.imageFlippedForRightToLeftLayoutDirection : image;

            cell.descView.text = cellData.desc;
            cell.descView.font = [UIFont scaledSystemFontOfSize:[cellData.values[@"desc_font_size"] intValue]];
            cell.descView.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];

            cell.extraDescView.text = extraDesc;
            cell.extraDescView.font = [UIFont scaledSystemFontOfSize:[cellData.values[@"desc_font_size"] intValue]];
            cell.extraDescView.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
        }

        if ([cell needsUpdateConstraints])
            [cell setNeedsUpdateConstraints];

        return cell;
    }
    else if ([cellData.type isEqualToString:[OACollectionSingleLineTableViewCell getCellIdentifier]])
    {
        OACollectionSingleLineTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OACollectionSingleLineTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACollectionSingleLineTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = nib[0];
            OAColorCollectionHandler *colorHandler = [[OAColorCollectionHandler alloc] initWithData:@[_sortedColorItems] collectionView:cell.collectionView];
            colorHandler.delegate = self;
            NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:_selectedColorItem] inSection:0];
            if (selectedIndexPath.row == NSNotFound)
                selectedIndexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:[_appearanceCollection getDefaultLineColorItem]] inSection:0];
            [colorHandler setSelectedIndexPath:selectedIndexPath];
            [cell setCollectionHandler:colorHandler];
            cell.separatorInset = UIEdgeInsetsZero;
            cell.rightActionButton.accessibilityLabel = OALocalizedString(@"shared_string_add_color");
            cell.delegate = self;
        }
        if (cell)
        {
            [cell.rightActionButton setImage:[UIImage templateImageNamed:@"ic_custom_add"] forState:UIControlStateNormal];
            cell.rightActionButton.tag = indexPath.section << 10 | indexPath.row;
            [cell.rightActionButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
            [cell.rightActionButton addTarget:self action:@selector(onCellButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
            [cell.collectionView reloadData];
            [cell layoutIfNeeded];
        }
        return cell;
    }
    else if ([cellData.type isEqualToString:[OATextLineViewCell getCellIdentifier]])
    {
        OATextLineViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextLineViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextLineViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OATextLineViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., self.tableView.frame.size.width, 0., 0.);
        }
        if (cell)
        {
            [cell makeSmallMargins:indexPath.row != [self tableView:tableView numberOfRowsInSection:indexPath.section] - 1];
            cell.textView.text = cellData.title;
            cell.textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.textView.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OASegmentedControlCell getCellIdentifier]])
    {
        NSArray *arrayValue = cellData.values[@"array_value"];
        OASegmentedControlCell *cell = cellData.values[@"cell_value"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentedControlCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OASegmentedControlCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.separatorInset = UIEdgeInsetsMake(0., self.tableView.frame.size.width, 0., 0.);
            cell.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
            cell.segmentedControl.backgroundColor = [[UIColor colorNamed:ACColorNameButtonBgColorPrimary] colorWithAlphaComponent:.1];
            [cell changeHeight:YES];

            [cell.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameButtonTextColorPrimary]}
                                                 forState:UIControlStateSelected];
            [cell.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameButtonTextColorSecondary],
                                                                       NSFontAttributeName : [UIFont scaledBoldSystemFontOfSize:15.0f]}
                                                 forState:UIControlStateNormal];

            cell.segmentedControl.selectedSegmentTintColor = [UIColor colorNamed:ACColorNameButtonBgColorPrimary];
        }
        if (cell)
        {
            int i = 0;
            for (OAGPXTrackAppearance *value in arrayValue)
            {
                if (cellData.toggle && [value isKindOfClass:OAGPXTrackWidth.class])
                {
                    UIImage *icon = [UIImage templateImageNamed:((OAGPXTrackWidth *) value).icon];
                    if (i == cell.segmentedControl.numberOfSegments)
                        [cell.segmentedControl insertSegmentWithImage:icon atIndex:i++ animated:NO];
                    else
                        [cell.segmentedControl setImage:icon forSegmentAtIndex:i++];
                }
                else if (!cellData.toggle && [value isKindOfClass:OAGPXTrackSplitInterval.class])
                {
                    if (i == cell.segmentedControl.numberOfSegments)
                        [cell.segmentedControl insertSegmentWithTitle:value.title atIndex:i++ animated:NO];
                    else
                        [cell.segmentedControl setTitle:value.title forSegmentAtIndex:i++];
                }
            }

            NSInteger selectedIndex = 0;
            if ([cellData.key isEqualToString:@"width_value"])
                selectedIndex = [arrayValue indexOfObject:_selectedWidth];
            else if ([cellData.key isEqualToString:@"split_value"])
                selectedIndex = [arrayValue indexOfObject:_selectedSplit];
            [cell.segmentedControl setSelectedSegmentIndex:selectedIndex];

            cell.segmentedControl.tag = indexPath.section << 10 | indexPath.row;
            [cell.segmentedControl removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.segmentedControl addTarget:self
                                      action:@selector(segmentChanged:)
                            forControlEvents:UIControlEventValueChanged];

            NSMutableDictionary *values = [cellData.values mutableCopy];
            values[@"cell_value"] = cell;
            [cellData setData:values];
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OADividerCell getCellIdentifier]])
    {
        OADividerCell *cell = [tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *) nib[0];
            cell.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
            cell.dividerColor = [UIColor colorNamed:ACColorNameGroupBg];
            cell.dividerInsets = UIEdgeInsetsZero;
            cell.separatorInset = UIEdgeInsetsMake(0., self.tableView.frame.size.width, 0., 0.);
            cell.dividerHight = 0.;
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OASegmentSliderTableViewCell getCellIdentifier]])
    {
        OASegmentSliderTableViewCell *cell =
                [tableView dequeueReusableCellWithIdentifier:[OASegmentSliderTableViewCell getCellIdentifier]];
        BOOL hasTopLabels = [cellData.values[@"has_top_labels"] boolValue];
        BOOL hasBottomLabels = [cellData.values[@"has_bottom_labels"] boolValue];
        NSArray *arrayValue = cellData.values[@"array_value"];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASegmentSliderTableViewCell getCellIdentifier]
                                                         owner:self options:nil];
            cell = (OASegmentSliderTableViewCell *) nib[0];
        }
        if (cell)
        {
            [cell showLabels:hasTopLabels topRight:hasTopLabels bottomLeft:hasBottomLabels bottomRight:hasBottomLabels];
            cell.topLeftLabel.text = cellData.title;
            cell.topRightLabel.text = cellData.values[@"custom_string_value"];
            cell.topRightLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            cell.topRightLabel.font = [UIFont scaledSystemFontOfSize:17 weight:UIFontWeightMedium];
            cell.bottomLeftLabel.text = arrayValue.firstObject;
            cell.bottomRightLabel.text = arrayValue.lastObject;
            [cell.sliderView setNumberOfMarks:arrayValue.count additionalMarksBetween:0];
            cell.sliderView.selectedMark = [arrayValue indexOfObject:cellData.values[@"custom_string_value"]];

            cell.sliderView.tag = indexPath.section << 10 | indexPath.row;
            [cell.sliderView removeTarget:self action:NULL forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
            [cell.sliderView addTarget:self
                                action:@selector(sliderChanged:)
                      forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
        }
        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = cellData.title;
            cell.titleLabel.textColor = cellData.tintColor ?: [UIColor colorNamed:ACColorNameTextColorPrimary];
        }
        return cell;
    }
    else if ([cellData.type isEqualToString:[OAButtonTableViewCell getCellIdentifier]])
    {
        OAButtonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAButtonTableViewCell getCellIdentifier]];
        OAGPXTableSectionData *sectionData = _tableData[indexPath.section];
        BOOL is3dTrackSection = [sectionData.key isEqualToString:@"3d_track_section"];

            if (is3dTrackSection)
            {
                cell.titleLabel.text = cellData.title;
                [cell setCustomLeftSeparatorInset:YES];
                [cell descriptionVisibility:NO];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.separatorInset = UIEdgeInsetsMake(0., CGFLOAT_MAX, 0., 0.);
                [cell leftIconVisibility:NO];
                cell.leftIconView.image = nil;
                [cell.button setTitleColor:[UIColor colorNamed:ACColorNameTextColorActive] forState:UIControlStateHighlighted];
                cell.button.tintColor = [UIColor colorNamed:ACColorNameTextColorActive];
                cell.button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
                
                cell.button.menu = [self createMenuForKey:cellData.key button:cell.button];
                cell.button.showsMenuAsPrimaryAction = YES;
                cell.button.changesSelectionAsPrimaryAction = YES;
                return cell;
            }
            else
            {
                cell.separatorInset = UIEdgeInsetsZero;
                [cell leftIconVisibility:YES];
                //                cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
                //                cell.leftIconView.tintColor = item.iconTintColor;
                [cell.button setTitle:nil forState:UIControlStateNormal];
                
                UIButtonConfiguration *conf = [UIButtonConfiguration plainButtonConfiguration];
                //conf.image = [UIImage imageNamed:item.secondaryIconName];
                cell.button.configuration = conf;
                cell.button.menu = nil;
                [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
                [cell.button addTarget:self action:@selector(showChoosePlanScreen) forControlEvents:UIControlEventTouchUpInside];
                return cell;
            }
//        }
        
        
        // TODO:
//        OAButtonTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAButtonTableViewCell getCellIdentifier] forIndexPath:indexPath];
//        [cell leftIconVisibility:NO];
//        [cell titleVisibility:YES];
//        [cell descriptionVisibility:NO];
//        [cell leftEditButtonVisibility:NO];
//        cell.rightContainerConstraint.constant = -3;
//        cell.button.semanticContentAttribute = UISemanticContentAttributeForceRightToLeft;
//        cell.selectionStyle = UITableViewCellSelectionStyleNone;
//        
//        cell.button.layer.cornerRadius = 9.0;
//        cell.button.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 11);
//        cell.button.imageEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
//        UIImage *image = [UIImage templateImageNamed:@"ic_small_arrow_forward"];
//        [cell.button setImage:[cell isDirectionRTL] ? image.imageFlippedForRightToLeftLayoutDirection : image
//                     forState:UIControlStateNormal];
//        cell.button.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
//        [cell.button.heightAnchor constraintEqualToConstant:34].active = YES;
//        
//        [cell.button setTitle:OALocalizedString(@"shared_string_get") forState:UIControlStateNormal];
//        [cell.button setTitleColor:[UIColor colorNamed:ACColorNameButtonTextColorSecondary] forState:UIControlStateNormal];
//        cell.button.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorTertiary];
//        cell.button.imageView.tintColor = [UIColor colorNamed:ACColorNameButtonTextColorSecondary];
//        [cell.button addTarget:self action:@selector(onGetFeatureTerrainButtonPressed:)
//              forControlEvents:UIControlEventTouchUpInside];
//        cell.titleLabel.text = cellData.title;
//        outCell = cell;
    }
    else if ([cellData.type isEqualToString:[UITableViewCell getCellIdentifier]])
    {
        OAGPXTableSectionData *sectionData = _tableData[indexPath.section];
        if ([sectionData.key isEqualToString:@"3d_track_section"])
        {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[UITableViewCell getCellIdentifier]];
            if (!_trackView3DEmptyView)
            {
                _trackView3DEmptyView = LeftIconRightStackTitleDescriptionButtonView.view;
                __weak __typeof(self) weakSelf = self;
                _trackView3DEmptyView.didBottomButtonTapAction = ^{
                    [OAChoosePlanHelper showChoosePlanScreenWithFeature:OAFeature.TERRAIN navController:weakSelf.navigationController];
                };
                [_trackView3DEmptyView configureWithTitle:OALocalizedString(@"track_3d_empty_view_title")
                                              description:OALocalizedString(@"track_3d_empty_view_description")
                                              buttonTitle:OALocalizedString(@"shared_string_get")
                                                leftImage:[UIImage imageNamed:@"ic_custom_3dtrack_colored"]
                                       leftImageTintColor:[UIColor colorNamed:ACColorNameIconColorDefault]];
            }
            
            [cell.contentView addSubview:_trackView3DEmptyView];
            cell.translatesAutoresizingMaskIntoConstraints = NO;
            _trackView3DEmptyView.translatesAutoresizingMaskIntoConstraints = NO;
            
            [cell.contentView addSubview:_trackView3DEmptyView];
            [NSLayoutConstraint activateConstraints:@[
                [_trackView3DEmptyView.leadingAnchor constraintEqualToAnchor:cell.contentView.leadingAnchor constant:20],
                [_trackView3DEmptyView.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-20],
                [_trackView3DEmptyView.topAnchor constraintEqualToAnchor:cell.contentView.topAnchor constant:20],
                [_trackView3DEmptyView.bottomAnchor constraintEqualToAnchor:cell.contentView.bottomAnchor constant:20],
            ]];
            return cell;
            
        }
        return [UITableViewCell new];
        
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    if ([cellData.type isEqualToString:[OADividerCell getCellIdentifier]])
        return [cellData.values[@"float_value"] floatValue];
    if ([cellData.type isEqualToString:[UITableViewCell getCellIdentifier]] && [cellData.key isEqualToString:@"track_view_3d_empty_state"])
    {
        // TODO:
        return [[UIFontMetrics defaultMetrics] scaledValueForValue:82] + 104;
    }
    
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    OAGPXTableSectionData *sectionData = _tableData[section];
    if (sectionData.headerHeight == 0.)
        return 0.001;

    return sectionData.headerHeight > 0
    ? [OAUtilities calculateTextBounds:sectionData.header
                                 width:self.scrollableView.frame.size.width - 40. - [OAUtilities getLeftMargin]
                                  font:[UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]].height + sectionData.headerHeight
    : 0.001;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    OAGPXTableSectionData *sectionData = _tableData[section];
    NSString *footer = sectionData.footer;
    CGFloat footerHeight = sectionData.footerHeight > 0 ? sectionData.footerHeight : 0.;

    if (!footer || footer.length == 0)
        return footerHeight > 0 ? footerHeight : 0.001;

    return [OATableViewCustomFooterView getHeight:footer width:self.tableView.bounds.size.width] + footerHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    NSString *footer = _tableData[section].footer;
    if (!footer || footer.length == 0)
        return nil;

    OATableViewCustomFooterView *vw =
            [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomFooterView getCellIdentifier]];
    UIFont *textFont = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    NSMutableAttributedString *textStr = [[NSMutableAttributedString alloc] initWithString:footer attributes:@{
            NSFontAttributeName: textFont,
            NSForegroundColorAttributeName: [UIColor colorNamed:ACColorNameTextColorSecondary]
    }];
    vw.label.attributedText = textStr;
    return vw;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAGPXTableCellData *cellData = [self getCellData:indexPath];

    [self onButtonPressed:cellData];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UISwitch pressed

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];

    [self onSwitch:switchView.isOn tableData:cellData];

    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - UISegmentedControl pressed

- (void)segmentChanged:(id)sender
{
    UISegmentedControl *segment = (UISegmentedControl *) sender;
    if (segment)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:segment.tag & 0x3FF inSection:segment.tag >> 10];
        OAGPXTableCellData *cellData = [self getCellData:indexPath];

        [self updateProperty:@(segment.selectedSegmentIndex) tableData:cellData];

        
         [self updateData:_tableData[indexPath.section]];

        [UIView setAnimationsEnabled:NO];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section]
                      withRowAnimation:UITableViewRowAnimationNone];
        [UIView setAnimationsEnabled:YES];
    }
}

#pragma mark - UISlider pressed

- (void)sliderChanged:(id)sender
{
    UISlider *slider = (UISlider *) sender;
    if (sender)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:slider.tag & 0x3FF inSection:slider.tag >> 10];
        OASegmentSliderTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        OAGPXTableCellData *cellData = [self getCellData:indexPath];

        [self updateProperty:@(cell.sliderView.selectedMark) tableData:cellData];

        [self updateData:cellData];

        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - Cell action methods

- (void)onSwitch:(BOOL)toggle tableData:(OAGPXBaseTableData *)tableData
{
    if ([tableData.key isEqualToString:@"direction_arrows"])
    {
        self.gpx.showArrows = toggle;
        if (_wholeFolderTracks)
        {
            for (OAGPX *track in _wholeFolderTracks)
                track.showArrows = toggle;
        }

        if (self.isCurrentTrack)
        {
            [self.doc setShowArrows:self.gpx.showArrows];
            [[_app updateRecTrackOnMapObservable] notifyEvent];
        }
        else
        {
            [[_app updateGpxTracksOnMapObservable] notifyEvent];
        }
    }
    else if ([tableData.key isEqualToString:@"start_finish_icons"])
    {
        self.gpx.showStartFinish = toggle;
        if (_wholeFolderTracks)
        {
            for (OAGPX *track in _wholeFolderTracks)
                track.showStartFinish = toggle;
        }

        if (self.isCurrentTrack)
        {
            [self.doc setShowStartFinish:self.gpx.showStartFinish];
            [[_app updateRecTrackOnMapObservable] notifyEvent];
        }
        else
        {
            [[_app updateGpxTracksOnMapObservable] notifyEvent];
        }
    }
    else if ([tableData.key isEqualToString:@"visualization_3D"])
    {
        self.gpx.raiseRoutesAboveRelief = toggle;
        if (_wholeFolderTracks)
        {
            for (OAGPX *track in _wholeFolderTracks)
                track.raiseRoutesAboveRelief = toggle;
        }

        if (self.isCurrentTrack)
        {
            [self.doc setRaiseRoutesAboveRelief:self.gpx.raiseRoutesAboveRelief];
            [[_app updateRecTrackOnMapObservable] notifyEvent];
        }
        else
        {
            [[_app updateGpxTracksOnMapObservable] notifyEvent];
        }
    }
    else if ([tableData.key isEqualToString:@"join_gaps"])
    {
        self.gpx.joinSegments = toggle;
        if (_wholeFolderTracks)
        {
            for (OAGPX *track in _wholeFolderTracks)
                track.joinSegments = toggle;
        }

        if (self.isCurrentTrack)
            [[_app updateRecTrackOnMapObservable] notifyEvent];
        else
            [[_app updateGpxTracksOnMapObservable] notifyEvent];
    }
}


- (BOOL)isOn:(OAGPXBaseTableData *)tableData
{
    if ([tableData.key isEqualToString:@"direction_arrows"])
        return self.gpx.showArrows;
    else if ([tableData.key isEqualToString:@"start_finish_icons"])
        return self.gpx.showStartFinish;
    else if ([tableData.key isEqualToString:@"visualization_3D"])
        return self.gpx.raiseRoutesAboveRelief;
    else if ([tableData.key isEqualToString:@"join_gaps"])
        return self.gpx.joinSegments;

    return NO;
}

- (void)updateData:(OAGPXBaseTableData *)tableData
{
    if ([tableData.key isEqualToString:@"color_title"])
    {
        [tableData setData:@{
            kTableValues: @{
                @"string_value": _selectedItem.title,
                @"accessibility_label": OALocalizedString(@"shared_string_coloring"),
                @"accessibility_value": _selectedItem.title,
                @"accessoryType": @(UITableViewCellAccessoryDisclosureIndicator)
            }
        }];
    }
    else if ([tableData.key isEqualToString:@"color_values"])
    {
        NSMutableArray<NSDictionary *> *newTrackColoringTypes = [NSMutableArray array];
        for (OATrackAppearanceItem *item in _availableColoringTypes)
        {
            [newTrackColoringTypes addObject:@{
                    @"title": item.title,
                    @"available": @(item.isAvailable && item.isEnabled)
            }];
        }
        [tableData setData:@{
                kTableValues: @{
                        @"array_value": newTrackColoringTypes,
                        @"selected_integer_value": @([_availableColoringTypes indexOfObject:_selectedItem])
                }
        }];
    }
    else if ([tableData.key isEqualToString:@"colors_section"])
    {
        OAGPXTableSectionData *section = (OAGPXTableSectionData *)tableData;
        OAGPXTableCellData *gridOrDescriptionCellData = nil;
        NSInteger index = NSNotFound;
        for (NSInteger i = 0; i < section.subjects.count; i++)
        {
            OAGPXTableCellData *row = section.subjects[i];
            if ([row.key isEqualToString:@"color_grid"] || [row.key isEqualToString:@"color_elevation_description"] || [row.key isEqualToString:@"color_attribute_description"])
            {
                gridOrDescriptionCellData = row;
                index = i;
                break;
            }
        }
        if (index != NSNotFound)
        {
            gridOrDescriptionCellData = [self generateGridOrDescriptionCellData];
            section.subjects[index] = gridOrDescriptionCellData;

            OAGPXTableCellData *lastCellData = section.subjects.lastObject;
            if ([lastCellData.key isEqualToString:@"color_extra_description"] || [lastCellData.key isEqualToString:@"all_colors"])
                [section.subjects removeObject:lastCellData];

            BOOL hasElevationGradient = [section.subjects.lastObject.key isEqualToString:@"color_elevation_gradient"];
            if ([_selectedItem.coloringType isGradient] && !hasElevationGradient)
                [section.subjects addObject:[self generateDataForColorElevationGradientCellData]];
            else if (![_selectedItem.coloringType isGradient] && hasElevationGradient)
                [section.subjects removeObject:section.subjects.lastObject];

            if ([self isSelectedTypeSpeed] || [self isSelectedTypeAltitude])
            {
                [section.subjects addObject:[self generateDescriptionCellData:@"color_extra_description"
                        description:OALocalizedString(@"grey_color_undefined")]];
            }
            else if ([_selectedItem.coloringType isTrackSolid])
            {
                [section.subjects addObject:[self generateAllColorsCellData]];
            }
        }
        for (OAGPXTableCellData *cellData in section.subjects)
        {
            [self updateData:cellData];
        }
    }
    else if ([tableData.key isEqualToString:@"width_title"])
    {
        [tableData setData:@{ kTableValues: @{@"string_value": _selectedWidth.title } }];
    }
    else if ([tableData.key isEqualToString:@"width_value"])
    {
        [tableData setData:@{ kTableValues: @{@"array_value": [_appearanceCollection getAvailableWidth] } }];
        OAGPXTableSectionData *widthSectionData = _tableData[_widthDataSectionIndex];
        if ([_selectedWidth isCustom])
            [self updateProperty:@([_selectedWidth.customValue intValue] - 1) tableData:widthSectionData.subjects.lastObject];
    }
    else if ([tableData.key isEqualToString:@"width_section"])
    {
        OAGPXTableSectionData *widthSectionData = (OAGPXTableSectionData *)tableData;
        BOOL hasCustomSlider = [widthSectionData.subjects.lastObject.key isEqualToString:@"width_custom_slider"];
        if ([_selectedWidth isCustom] && !hasCustomSlider)
            [widthSectionData.subjects addObject:[self generateDataForWidthCustomSliderCellData]];
        else if (![_selectedWidth isCustom] && hasCustomSlider)
            [widthSectionData.subjects removeObject:widthSectionData.subjects.lastObject];

        for (OAGPXTableCellData *cellData in widthSectionData.subjects)
        {
            [self updateData:cellData];
        }
    }
    else if ([tableData.key isEqualToString:@"split_title"])
    {
        [tableData setData:@{ kTableValues: @{ @"string_value": _selectedSplit.title } }];
    }
    else if ([tableData.key isEqualToString:@"split_value"])
    {
        [tableData setData:@{ kTableValues: @{ @"array_value": [_appearanceCollection getAvailableSplitIntervals] } }];
    }
    else if ([tableData.key isEqualToString:@"split_section"])
    {
        NSInteger index = NSNotFound;
        OAGPXTableSectionData *section = (OAGPXTableSectionData *)tableData;
        OAGPXTableCellData *sliderOrDescriptionCellData = nil;
        for (NSInteger i = 0; i < section.subjects.count; i++)
        {
            OAGPXTableCellData *row = section.subjects[i];
            if ([row.key isEqualToString:@"split_custom_slider"] || [row.key isEqualToString:@"split_none_descr"])
            {
                sliderOrDescriptionCellData = row;
                index = i;
                break;
            }
        }
        if (index != NSNotFound)
        {
            sliderOrDescriptionCellData = [self generateDataForSplitCustomSliderCellData];
            section.subjects[index] = sliderOrDescriptionCellData;
        }
        for (OAGPXTableCellData *cellData in section.subjects)
        {
            [self updateData:cellData];
        }
    }
    else if ([tableData.key isEqualToString:@"color_elevation_gradient"])
    {
        [tableData setData:@{
                kTableValues: @{
                        @"extra_desc": [self generateExtraDescription],
                        @"desc_font_size": @([self isSelectedTypeSlope] ? 15 : 17)
                },
                kCellDesc: [self generateDescription],
                kCellRightIconName: [self isSelectedTypeSlope] ? @"img_track_gradient_slope" : @"img_track_gradient_speed"
        }];
    }
    else if ([tableData.key isEqualToString:@"width_custom_slider"])
    {
        [tableData setData:@{
                kTableValues: @{
                        @"custom_string_value": _selectedWidth.customValue,
                        @"array_value": _customWidthValues,
                        @"has_top_labels": @NO,
                        @"has_bottom_labels": @YES
                }
        }];
    }
    else if ([tableData.key isEqualToString:@"split_custom_slider"])
    {
        [tableData setData:@{
            kTableValues: @{
                @"custom_string_value": _selectedSplit.customValue,
                @"array_value": _selectedSplit.titles,
                @"has_top_labels": @YES,
                @"has_bottom_labels": @YES
            }
        }];
    }
}

- (void)updateProperty:(id)value tableData:(OAGPXBaseTableData *)tableData
{
    if ([tableData.key isEqualToString:@"width_value"])
    {
        if ([value isKindOfClass:NSNumber.class])
        {
            _selectedWidth = [_appearanceCollection getAvailableWidth][[value intValue]];
            self.gpx.width = [_selectedWidth isCustom] ? _selectedWidth.customValue : _selectedWidth.key;
            if (_wholeFolderTracks)
            {
                for (OAGPX *track in _wholeFolderTracks)
                    track.width = [_selectedWidth isCustom] ? _selectedWidth.customValue : _selectedWidth.key;
            }

            if (self.isCurrentTrack)
            {
                [self.doc setWidth:self.gpx.width];
                [[_app updateRecTrackOnMapObservable] notifyEvent];
            }
            else
            {
                [[_app updateGpxTracksOnMapObservable] notifyEvent];
            }
        }
    }
    else if ([tableData.key isEqualToString:@"split_value"])
    {
        if ([value isKindOfClass:NSNumber.class])
        {
            NSArray<OAGPXTrackSplitInterval *> *availableSplitIntervals = [_appearanceCollection getAvailableSplitIntervals];
            NSInteger index = [value integerValue];
            OAGPXTableSectionData *splitSection = _tableData[_splitDataSectionIndex];
            OAGPXTableCellData *sliderOrDescriptionCellData = nil;
            for (OAGPXTableCellData *row in splitSection.subjects)
            {
                if ([row.key isEqualToString:@"split_custom_slider"] || [row.key isEqualToString:@"split_none_descr"])
                {
                    sliderOrDescriptionCellData = row;
                    break;
                }
            }
            if (availableSplitIntervals.count > index)
            {
                _selectedSplit = availableSplitIntervals[index];
                CGFloat splitInterval = 0.;
                if ([_selectedSplit isCustom])
                {
                    NSInteger indexOfCustomValue = 0;
                    if ([sliderOrDescriptionCellData.values.allKeys containsObject:@"array_value"]
                            && [sliderOrDescriptionCellData.values.allKeys containsObject:@"custom_string_value"])
                    {
                        indexOfCustomValue = [sliderOrDescriptionCellData.values[@"array_value"]
                                indexOfObject:sliderOrDescriptionCellData.values[@"custom_string_value"]];
                    }
                    if (indexOfCustomValue != NSNotFound)
                        splitInterval = [_selectedSplit.values[indexOfCustomValue] doubleValue];
                }

                self.gpx.splitType = _selectedSplit.type;
                self.gpx.splitInterval = splitInterval;
                if (_wholeFolderTracks)
                {
                    for (OAGPX *track in _wholeFolderTracks)
                    {
                        track.splitType = _selectedSplit.type;
                        track.splitInterval = splitInterval;
                    }
                }
                if (self.gpx.splitInterval > 0 && self.gpx.splitType != EOAGpxSplitTypeNone)
                {
                    NSInteger indexOfValue = [_selectedSplit.values indexOfObject:@(self.gpx.splitInterval)];
                    if (indexOfValue != NSNotFound)
                        _selectedSplit.customValue = _selectedSplit.titles[indexOfValue];
                }

                if (self.isCurrentTrack)
                {
                    [self.doc setSplitInterval:self.gpx.splitInterval];
                    [self.doc setSplitType:[OAGPXDatabase splitTypeNameByValue:self.gpx.splitType]];
                    [[_app updateRecTrackOnMapObservable] notifyEvent];
                }
                else
                {
                    [[_app updateGpxTracksOnMapObservable] notifyEvent];
                }
            }
        }
    }
    else if ([tableData.key isEqualToString:@"width_custom_slider"])
    {
        if ([value isKindOfClass:NSNumber.class])
        {
            NSString *selectedValue = _customWidthValues[[value intValue]];
            if (![_selectedWidth.customValue isEqualToString:selectedValue])
            {
                self.gpx.width = _selectedWidth.customValue = selectedValue;
                if (_wholeFolderTracks)
                {
                    for (OAGPX *track in _wholeFolderTracks)
                        track.width = _selectedWidth.customValue = selectedValue;
                }
            }

            if (self.isCurrentTrack)
            {
                [self.doc setWidth:self.gpx.width];
                [[_app updateRecTrackOnMapObservable] notifyEvent];
            }
            else
            {
                [[_app updateGpxTracksOnMapObservable] notifyEvent];
            }
        }
    }
    else if ([tableData.key isEqualToString:@"split_custom_slider"])
    {
        if ([value isKindOfClass:NSNumber.class])
        {
            NSString *customValue = _selectedSplit.titles[[value intValue]];
            if (![_selectedSplit.customValue isEqualToString:customValue])
            {
                _selectedSplit.customValue = customValue;
                self.gpx.splitInterval = _selectedSplit.values[[value intValue]].doubleValue;
                if (_wholeFolderTracks)
                {
                    for (OAGPX *track in _wholeFolderTracks)
                        track.splitInterval = _selectedSplit.values[[value intValue]].doubleValue;
                }
            }

            if (self.isCurrentTrack)
            {
                [self.doc setSplitInterval:self.gpx.splitInterval];
                [[_app updateRecTrackOnMapObservable] notifyEvent];
            }
            else
            {
                [[_app updateGpxTracksOnMapObservable] notifyEvent];
            }
        }
    }
}

- (void)onButtonPressed:(OAGPXBaseTableData *)tableData
{
    if ([tableData.key isEqualToString:@"color_title"])
    {
        OATrackColoringTypeViewController *coloringViewController = [[OATrackColoringTypeViewController alloc] initWithAvailableColoringTypes:_availableColoringTypes selectedItem:_selectedItem];
        coloringViewController.delegate = self;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:coloringViewController];
        navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
        UISheetPresentationController *sheet = navigationController.sheetPresentationController;
        if (sheet)
        {
            sheet.detents = @[UISheetPresentationControllerDetent.mediumDetent];
            sheet.preferredCornerRadius = 20;
        }
        [self.navigationController presentViewController:navigationController animated:YES completion:nil];
    }
    else if ([tableData.key isEqualToString:@"all_colors"])
    {
        OAColorCollectionViewController *colorCollectionViewController =
            [[OAColorCollectionViewController alloc] initWithColorItems:[_appearanceCollection getAvailableColorsSortingByKey]
                                                      selectedColorItem:_selectedColorItem];
        colorCollectionViewController.delegate = self;
        [self.navigationController pushViewController:colorCollectionViewController animated:YES];
    }
    else if ([tableData.key isEqualToString:@"vertical_exaggeration"])
    {
        OAMapSettingsTerrainParametersViewController *controller = [[OAMapSettingsTerrainParametersViewController alloc] initWithSettingsType:EOATerrainSettingsTypeVerticalExaggeration];
        // TODO;
        controller.delegate = self;
        [OARootViewController.instance.mapPanel showScrollableHudViewController:controller];
    }
    else if ([tableData.key isEqualToString:@"reset"])
    {
        if (self.isCurrentTrack)
        {
            [self.settings.currentTrackWidth resetToDefault];
            [self.settings.currentTrackShowArrows resetToDefault];
            [self.settings.currentTrackShowStartFinish resetToDefault];
            [self.settings.currentTrackRaiseRoutesAboveRelief resetToDefault];
            [self.settings.currentTrackVisualization3dByType resetToDefault];
            [self.settings.currentTrackVisualization3dWallColorType resetToDefault];
            [self.settings.currentTrackVisualization3dPositionType resetToDefault];
            [self.settings.currentTrackColoringType resetToDefault];
            [self.settings.currentTrackColor resetToDefault];
            
            [self.doc setWidth:[self.settings.currentTrackWidth get]];
            [self.doc setShowArrows:[self.settings.currentTrackShowArrows get]];            
            [self.doc setShowStartFinish:[self.settings.currentTrackShowStartFinish get]];
            [self.doc setRaiseRoutesAboveRelief:[self.settings.currentTrackRaiseRoutesAboveRelief get]];
            
            [self.doc setVisualization3dByType:(EOAGPX3DLineVisualizationByType)[self.settings.currentTrackVisualization3dByType get]];
            [self.doc setVisualization3dWallColorType:(EOAGPX3DLineVisualizationWallColorType)[self.settings.currentTrackVisualization3dWallColorType get]];
            [self.doc setVisualization3dPositionType:(EOAGPX3DLineVisualizationPositionType)[self.settings.currentTrackVisualization3dPositionType get]];
        
            [self.doc setColoringType:[self.settings.currentTrackColoringType get].name];
            [self.doc setColor:[self.settings.currentTrackColor get]];
        }
        
        [self.gpx resetAppearanceToOriginal];
        [self updateAllValues];
        
        if (self.isCurrentTrack)
            [[_app updateRecTrackOnMapObservable] notifyEvent];
        else
            [[_app updateGpxTracksOnMapObservable] notifyEvent];
        
        [self generateData];
        [UIView transitionWithView:self.tableView
                          duration:0.35f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^(void) {
            [self.tableView reloadData];
        } completion:nil];
    }
}

#pragma mark - OATrackColoringTypeDelegate

- (void)onColoringTypeSelected:(OATrackAppearanceItem *)selectedItem
{
    _selectedItem = selectedItem;
    NSString *coloringType = _selectedItem.coloringType == OAColoringType.ATTRIBUTE ? _selectedItem.attrName : _selectedItem.coloringType.name;
    self.gpx.coloringType = coloringType;
    if (_wholeFolderTracks)
    {
        for (OAGPX *track in _wholeFolderTracks)
            track.coloringType = coloringType;
    }

    if (self.isCurrentTrack)
    {
        [self.doc setColoringType:self.gpx.coloringType];
        [[_app updateRecTrackOnMapObservable] notifyEvent];
    }
    else
    {
        [[_app updateGpxTracksOnMapObservable] notifyEvent];
    }

    OAGPXTableSectionData *section = _tableData[kColorsSection];
    [self updateData:section];

    [UIView transitionWithView:self.tableView
                      duration:0.35f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void)
                    {
                        [self.tableView reloadData];
                        self.doneButton.userInteractionEnabled = YES;
                        [self.doneButton setTitleColor:[UIColor colorNamed:ACColorNameIconColorActive]
                                              forState:UIControlStateNormal];
                    }
                    completion:nil];
}

#pragma mark - Selectors

- (void)onCellButtonPressed:(UIButton *)sender
{
    [self onRightActionButtonPressed:sender.tag];
}

//- (void)onGetFeatureTerrainButtonPressed:(UIButton *)button {
//    [OAChoosePlanHelper showChoosePlanScreenWithFeature:OAFeature.TERRAIN navController:self.navigationController];
//}

#pragma mark - OACollectionTableViewCellDelegate

- (void)onRightActionButtonPressed:(NSInteger)tag
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tag & 0x3FF inSection:tag >> 10];
    OAGPXTableCellData *cellData = [self getCellData:indexPath];
    if ([cellData.key isEqualToString:@"color_grid"])
        [self openColorPickerWithColor:_selectedColorItem];
}

#pragma mark - OAColorCollectionDelegate

- (void)selectColorItem:(OAColorItem *)colorItem
{
    [self onCollectionItemSelected:[NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:colorItem] inSection:0]];
}

- (OAColorItem *)addAndGetNewColorItem:(UIColor *)color
{
    OAColorItem *newColorItem = [_appearanceCollection addNewSelectedColor:color];
    OAGPXTableSectionData *colorSection = _tableData[kColorsSection];
    if (colorSection.subjects.count - 1 >= kColorGridOrDescriptionCell)
    {
        NSIndexPath *colorIndexPath = [NSIndexPath indexPathForRow:kColorGridOrDescriptionCell inSection:kColorsSection];
        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:colorIndexPath];
        OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
        
        [_sortedColorItems insertObject:newColorItem atIndex:0];
        [colorHandler addAndSelectColor:[NSIndexPath indexPathForRow:0 inSection:0] newItem:newColorItem];
    }
    return newColorItem;
}

- (void)changeColorItem:(OAColorItem *)colorItem withColor:(UIColor *)color
{
    OAGPXTableSectionData *colorSection = _tableData[kColorsSection];
    if (colorSection.subjects.count - 1 >= kColorGridOrDescriptionCell)
    {
        NSIndexPath *colorIndexPath = [NSIndexPath indexPathForRow:kColorGridOrDescriptionCell inSection:kColorsSection];
        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:colorIndexPath];
        OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:colorItem] inSection:0];
        [_appearanceCollection changeColor:colorItem newColor:color];
        [colorHandler replaceOldColor:indexPath];
    }
}

- (OAColorItem *)duplicateColorItem:(OAColorItem *)colorItem
{
    OAColorItem *duplicatedColorItem = [_appearanceCollection duplicateColor:colorItem];
    OAGPXTableSectionData *colorSection = _tableData[kColorsSection];
    if (colorSection.subjects.count - 1 >= kColorGridOrDescriptionCell)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:colorItem] inSection:0];
        [_sortedColorItems insertObject:duplicatedColorItem atIndex:indexPath.row + 1];

        NSIndexPath *colorIndexPath = [NSIndexPath indexPathForRow:kColorGridOrDescriptionCell inSection:kColorsSection];
        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:colorIndexPath];
        OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
        [colorHandler addColor:newIndexPath newItem:duplicatedColorItem];
    }
    return duplicatedColorItem;
}

- (void)deleteColorItem:(OAColorItem *)colorItem
{
    OAGPXTableSectionData *colorSection = _tableData[kColorsSection];
    if (colorSection.subjects.count - 1 >= kColorGridOrDescriptionCell)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:[_sortedColorItems indexOfObject:colorItem] inSection:0];
        [_appearanceCollection deleteColor:colorItem];
        [_sortedColorItems removeObjectAtIndex:indexPath.row];

        NSIndexPath *colorIndexPath = [NSIndexPath indexPathForRow:kColorGridOrDescriptionCell inSection:kColorsSection];
        OACollectionSingleLineTableViewCell *colorCell = [self.tableView cellForRowAtIndexPath:colorIndexPath];
        OAColorCollectionHandler *colorHandler = (OAColorCollectionHandler *) [colorCell getCollectionHandler];
        [colorHandler removeColor:indexPath];
    }
}

#pragma mark - OACollectionCellDelegate

- (void)onCollectionItemSelected:(NSIndexPath *)indexPath
{
    _isNewColorSelected = YES;
    _selectedColorItem = _sortedColorItems[indexPath.row];
    self.gpx.color = _selectedColorItem.value;
    if (_wholeFolderTracks)
    {
        for (OAGPX *track in _wholeFolderTracks)
            track.color = _selectedColorItem.value;;
    }

    if (self.isCurrentTrack)
    {
        [self.doc setColor:self.gpx.color];
        [[_app updateRecTrackOnMapObservable] notifyEvent];
    }
    else
    {
        [[_app updateGpxTracksOnMapObservable] notifyEvent];
    }
}

- (void)reloadCollectionData
{
}

#pragma mark - OAColorsCollectionCellDelegate

- (void)onContextMenuItemEdit:(NSIndexPath *)indexPath
{
    _editColorIndexPath = indexPath;
    [self openColorPickerWithColor:_sortedColorItems[indexPath.row]];
}

- (void)duplicateItemFromContextMenu:(NSIndexPath *)indexPath
{
    [self duplicateColorItem:_sortedColorItems[indexPath.row]];
}

- (void)deleteItemFromContextMenu:(NSIndexPath *)indexPath
{
    [self deleteColorItem:_sortedColorItems[indexPath.row]];
}

#pragma mark - UIColorPickerViewControllerDelegate

- (void)colorPickerViewControllerDidFinish:(UIColorPickerViewController *)viewController
{
    if (_editColorIndexPath)
    {
        if (![[_sortedColorItems[_editColorIndexPath.row] getHexColor] isEqualToString:[viewController.selectedColor toHexARGBString]])
        {
            [self changeColorItem:_sortedColorItems[_editColorIndexPath.row] withColor:viewController.selectedColor];
        }
        _editColorIndexPath = nil;
    }
    else
    {
        [self addAndGetNewColorItem:viewController.selectedColor];
    }
}

#pragma mark - OATerrainParametersDelegate

- (void)onBackTerrainParameters
{
    [self generateData];
    [UIView transitionWithView:self.tableView
                      duration:0.35f
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void) {
        [self.tableView reloadData];
    } completion:nil];
}

@end
