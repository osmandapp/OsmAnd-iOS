//
//  OAOverviewTrackMenuViewController.mm
//  OsmAnd
//
//  Created by Skalii on 08.09.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAOverviewTrackMenuViewController.h"
#import "OARootViewController.h"
#import "OsmAndApp.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAGPXDatabase.h"
#import "OASavingTrackHelper.h"

@interface OAOverviewTrackMenuViewController ()

@end

@implementation OAOverviewTrackMenuViewController
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAGPX *_gpx;
    OASavingTrackHelper *_savingHelper;
    OAMapViewController *_mapViewController;

    BOOL _isCurrentTrack;
    BOOL _isShown;
}

- (instancetype)initWithGpx:(OAGPX *)gpx
{
    self = [super init];
    if (self)
    {
        _savingHelper = [OASavingTrackHelper sharedInstance];
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _gpx = gpx;
        _isShown = [_settings.mapSettingVisibleGpx.get containsObject:_gpx.gpxFilePath];
        _isCurrentTrack = _gpx.gpxFilePath.length == 0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;

    self.titleIconView.image = [UIImage templateImageNamed:@"ic_custom_trip"];
    self.titleIconView.tintColor = UIColorFromRGB(color_icon_inactive);

    [self.directionTextView setText:[_app getFormattedDistance:_gpx.totalDistance]];

    [self.showHideButton setImage:[UIImage templateImageNamed:_isShown ? @"ic_custom_show" : @"ic_custom_hide"] forState:UIControlStateNormal];
}

- (void)applyLocalization
{
    _titleView.text = [_gpx getNiceTitle];
    [self.showHideButton setTitle:_isShown ? OALocalizedString(@"sett_show") : OALocalizedString(@"poi_hide") forState:UIControlStateNormal];
    [self.appearanceButton setTitle:OALocalizedString(@"map_settings_appearance") forState:UIControlStateNormal];
    [self.exportButton setTitle:OALocalizedString(@"shared_string_export") forState:UIControlStateNormal];
    [self.navigationButton setTitle:OALocalizedString(@"routing_settings") forState:UIControlStateNormal];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CGFloat)getToolBarHeight
{
    return _statisticsCollectionView.frame.origin.y;
}

- (CGFloat)getHeaderHeight
{
    return _tableView.frame.origin.y;
}

+ (NSString *)getFirstParagraph:(NSString *)descriptionHtml
{
    if (descriptionHtml)
    {
//        NSString *firstParagraph = WikiArticleHelper.getPartialContent(descriptionHtml);
//        if (firstParagraph && firstParagraph.length > 0)
//            return firstParagraph;
    }
    return descriptionHtml;
}

#pragma mark - Action buttons pressed

- (IBAction)onShowHidePressed
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onShowHidePressed)])
    {
        _isShown = [self.delegate onShowHidePressed];
        [self.showHideButton setTitle:_isShown ? OALocalizedString(@"sett_show") : OALocalizedString(@"poi_hide") forState:UIControlStateNormal];
        [self.showHideButton setImage:[UIImage templateImageNamed:_isShown ? @"ic_custom_show" : @"ic_custom_hide"] forState:UIControlStateNormal];
    }
}

- (IBAction)onAppearancePressed
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onColorPressed)])
        [self.delegate onColorPressed];
}

- (IBAction)onExportPressed
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onExportPressed)])
        [self.delegate onExportPressed];
}

- (IBAction)onNavigationPressed
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(onNavigationPressed)])
        [self.delegate onNavigationPressed];
}

@end
