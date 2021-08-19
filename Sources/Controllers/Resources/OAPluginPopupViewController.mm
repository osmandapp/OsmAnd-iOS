//
//  OAPluginPopupViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPluginPopupViewController.h"
#import "OAUtilities.h"
#import "OAIAPHelper.h"
#import "OARootViewController.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAResourcesUIHelper.h"
#import "OAPluginsViewController.h"
#import "OAWorldRegion.h"
#import "OAColors.h"

static NSMutableArray *activePopups;

@interface OAPluginPopupViewController ()

@property (nonatomic) OAWorldRegion *worldRegion;

@end

@implementation OAPluginPopupViewController
{
    UIView *_shadeView;
}

- (instancetype)initWithType:(OAPluginPopupType)popupType
{
    self = [super init];
    if (self)
    {
        if (!activePopups)
            activePopups = [NSMutableArray array];

        _pluginPopupType = popupType;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // drop shadow
    [self.view.layer setShadowColor:[UIColor blackColor].CGColor];
    [self.view.layer setShadowOpacity:0.3];
    [self.view.layer setShadowRadius:3.0];
    [self.view.layer setShadowOffset:CGSizeMake(0.0, 0.0)];

    self.okButton.layer.cornerRadius = 4;
    self.okButton.layer.masksToBounds = YES;

    self.cancelButton.layer.cornerRadius = 4;
    self.cancelButton.layer.masksToBounds = YES;
    self.cancelButton.layer.borderWidth = 0.8;
    self.cancelButton.layer.borderColor = UIColorFromRGB(0x4caf50).CGColor;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [_shadeView removeFromSuperview];
        [self show];
    } completion:nil];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self show];
}
- (void)doLayout
{
    CGFloat w = self.view.frame.size.width;
    
    CGRect titleFrame = CGRectMake(50.0, 14.0, w - 50.0 - 40.0, 1000.0);
    titleFrame.size.height = [OAUtilities calculateTextBounds:self.titleLabel.text width:titleFrame.size.width font:self.titleLabel.font].height;
    self.titleLabel.frame = titleFrame;
    
    CGRect descFrame = CGRectMake(46.0, titleFrame.origin.y + titleFrame.size.height - 5.0, w - 50.0 - 15.0, 1000.0);
    descFrame.size.height = [self.descTextView.attributedText boundingRectWithSize:descFrame.size options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading) context:nil].size.height + self.descTextView.textContainerInset.top + self.descTextView.textContainerInset.bottom;
    self.descTextView.frame = descFrame;
    
    CGFloat okWidth = MAX(80.0, [OAUtilities calculateTextBounds:self.okButton.titleLabel.text width:1000.0 font:self.okButton.titleLabel.font].width + 30.0);
    CGFloat cancelWidth = MAX(80.0, [OAUtilities calculateTextBounds:self.cancelButton.titleLabel.text width:1000.0 font:self.cancelButton.titleLabel.font].width + 30.0);
    
    if (self.cancelButton.hidden)
        cancelWidth = 0.0;
    
    BOOL buttonsSingleLine = (w - 50.0 - 10.0 - okWidth - cancelWidth - 15.0) >= 10.0;
    if (buttonsSingleLine)
    {
        if (self.cancelButton.hidden)
        {
            if (okWidth < 120.0)
                okWidth = 120.0;
            self.okButton.frame = CGRectMake(w / 2.0 - okWidth / 2.0, descFrame.origin.y + descFrame.size.height + 5.0, okWidth, 35.0);
        }
        else
        {
            self.okButton.frame = CGRectMake(50.0, descFrame.origin.y + descFrame.size.height + 5.0, okWidth, 35.0);
            self.cancelButton.frame = CGRectMake(50.0 + okWidth + 10.0, descFrame.origin.y + descFrame.size.height + 5.0, cancelWidth, 35.0);
        }
    }
    else
    {
        self.okButton.frame = CGRectMake(50.0, descFrame.origin.y + descFrame.size.height + 5.0, okWidth, 35.0);
        self.cancelButton.frame = CGRectMake(50.0, self.okButton.frame.origin.y + self.okButton.frame.size.height + 10.0, cancelWidth, 35.0);
    }
    
    CGRect f = self.view.frame;
    if (self.cancelButton.hidden)
        f.size.height = self.okButton.frame.origin.y + self.okButton.frame.size.height + 15.0;
    else
        f.size.height = self.cancelButton.frame.origin.y + self.cancelButton.frame.size.height + 15.0;
    f.size.height += [OAUtilities getBottomMargin];
    self.view.frame = f;
}

- (void)show
{
    [activePopups addObject:self];
    
    [self doLayout];
    
    if (!_shadeView)
        _shadeView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, DeviceScreenHeight)];
    else
        _shadeView.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, DeviceScreenHeight);
    
    _shadeView.backgroundColor = UIColorFromRGBA(0x00000060);
    _shadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _shadeView.alpha = 0.0;
    [_shadeView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hide)]];
    
    [self.parentViewController.view addSubview:_shadeView];
    
    CGRect f = self.view.frame;
    f.origin.y = DeviceScreenHeight;
    self.view.frame = f;
    [self.parentViewController.view addSubview:self.view];
    
    f.origin.y = DeviceScreenHeight - self.view.frame.size.height;
    
    [UIView animateWithDuration:.25 animations:^{

        _shadeView.alpha = 1.0;
        self.view.frame = f;
        
    }];
}

- (void)hide
{
    CGRect f = self.view.frame;
    f.origin.y = DeviceScreenHeight;
    [UIView animateWithDuration:.25 animations:^{
        
        _shadeView.alpha = 0.0;
        self.view.frame = f;
        
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        [_shadeView removeFromSuperview];
        _shadeView = nil;
        [self removeFromParentViewController];
        
        [activePopups removeObject:self];
    }];
}

- (IBAction)closePressed:(id)sender
{
    [self hide];
}

+ (void)showRegionOnMap:(OAWorldRegion *)region
{
    [self hideRegionOnMap];
    
    OAPluginPopupViewController *popup = [[OAPluginPopupViewController alloc] initWithType:OAPluginPopupTypeShowRegionOnMap];
    popup.view.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 200.0);
 
    popup.worldRegion = region;
    
    NSString *title;
    NSString *descText;
    NSString *okButtonName;
    NSString *cancelButtonName;
    
    title = OALocalizedString(@"show_region_on_map_title");
    descText = [NSString stringWithFormat:OALocalizedString(@"show_region_on_map_desc"), region.name];
    cancelButtonName = OALocalizedString(@"shared_string_later");
    okButtonName = OALocalizedString(@"show_region_on_map_go");
    
    [popup.okButton addTarget:popup action:@selector(showOnMap) forControlEvents:UIControlEventTouchUpInside];
    
    UIViewController *top = [OARootViewController instance].navigationController.topViewController;
    
    popup.icon.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_custom_map"] color:UIColorFromRGB(0x4caf50)];
    popup.titleLabel.text = title;
    
    NSString *styledText = [self.class styledHTMLwithHTML:descText];
    popup.descTextView.attributedText = [self.class attributedStringWithHTML:styledText];
    
    [popup.okButton setTitle:okButtonName forState:UIControlStateNormal];
    [popup.cancelButton setTitle:cancelButtonName forState:UIControlStateNormal];
    
    [top addChildViewController:popup];
    [popup show];
}

+ (void)hideRegionOnMap
{
    for (OAPluginPopupViewController *popup in activePopups)
        if (popup.pluginPopupType == OAPluginPopupTypeShowRegionOnMap)
        {
            [popup hide];
            break;
        }
}

+ (void)askForWorldMap
{
    OAPluginPopupViewController *popup = [[OAPluginPopupViewController alloc] initWithType:OAPluginPopupTypeWorldMap];
    popup.view.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 200.0);
    
    NSString *title;
    NSString *descText;
    NSString *okButtonName;
    NSString *cancelButtonName;
    
    title = OALocalizedString(@"res_wmap");
    descText = OALocalizedString(@"all_world_popup_desc");
    cancelButtonName = OALocalizedString(@"shared_string_later");
    
    const auto repositoryMap = [OsmAndApp instance].resourcesManager->getResourceInRepository(kWorldBasemapKey);
    NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:repositoryMap->packageSize
                                                               countStyle:NSByteCountFormatterCountStyleFile];
    okButtonName = [NSString stringWithFormat:@"%@ (%@)", OALocalizedString(@"download"), stringifiedSize];

    [popup.okButton addTarget:popup action:@selector(downloadWorldMap) forControlEvents:UIControlEventTouchUpInside];
    [popup.cancelButton addTarget:popup action:@selector(cancelDownloadWorldMap) forControlEvents:UIControlEventTouchUpInside];

    UIViewController *top = [OARootViewController instance].navigationController.topViewController;
    
    popup.icon.image = [OAUtilities tintImageWithColor:[UIImage imageNamed:@"ic_custom_map"] color:UIColorFromRGB(0x4caf50)];
    popup.titleLabel.text = title;
    
    NSString *styledText = [self.class styledHTMLwithHTML:descText];
    popup.descTextView.attributedText = [self.class attributedStringWithHTML:styledText];
    
    [popup.okButton setTitle:okButtonName forState:UIControlStateNormal];
    [popup.cancelButton setTitle:cancelButtonName forState:UIControlStateNormal];
    
    [top addChildViewController:popup];
    [popup show];
}

+ (void)showNoInternetConnectionFirst
{
    OAPluginPopupViewController *popup = [[OAPluginPopupViewController alloc] initWithType:OAPluginPopupTypeNoInternet];
    popup.view.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 200.0);
    
    NSString *title;
    NSString *descText;
    NSString *okButtonName;
    
    title = OALocalizedString(@"no_internet_avail");
    descText = OALocalizedString(@"no_internet_avail_desc_first");
    okButtonName = OALocalizedString(@"shared_string_ok");
    
    [popup.okButton addTarget:popup action:@selector(closePressed:) forControlEvents:UIControlEventTouchUpInside];
    
    UIViewController *top = [OARootViewController instance].navigationController.topViewController;
    
    popup.icon.image = [UIImage imageNamed:@"ic_popup_no_internet"];
    popup.titleLabel.text = title;
    
    NSString *styledText = [self.class styledHTMLwithHTML:descText];
    popup.descTextView.attributedText = [self.class attributedStringWithHTML:styledText];
    
    [popup.okButton setTitle:okButtonName forState:UIControlStateNormal];
    popup.cancelButton.hidden = YES;
    
    [top addChildViewController:popup];
    [popup show];
}

+ (void) hideNoInternetConnection
{
    for (OAPluginPopupViewController *popup in activePopups)
        if (popup.pluginPopupType == OAPluginPopupTypeNoInternet)
        {
            [popup hide];
            break;
        }
}

+ (void) askForPlugin:(NSString *)productIdentifier
{
    BOOL needShow = NO;

    OAPluginPopupViewController *popup = [[OAPluginPopupViewController alloc] initWithType:OAPluginPopupTypePlugin];
    popup.view.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 200.0);
    
    NSString *title;
    NSString *descText;
    NSString *okButtonName;
    NSString *cancelButtonName;

    OAIAPHelper *helper = [OAIAPHelper sharedInstance];
    OAProduct *product;
    if ([kInAppId_Addon_Wiki isEqualToString:productIdentifier])
    {
        needShow = YES;
        product = helper.wiki;
        
        title = OALocalizedString(@"turn_on_plugin");
        descText = OALocalizedString(@"plugin_popup_wiki_ask");
        okButtonName = OALocalizedString(@"plugins");
        cancelButtonName = OALocalizedString(@"shared_string_cancel");
        
        [popup.okButton addTarget:popup action:@selector(goToPlugins) forControlEvents:UIControlEventTouchUpInside];
    }
    else if ([kInAppId_Addon_Srtm isEqualToString:productIdentifier])
    {
        needShow = YES;
        product = helper.srtm;
        
        title = OALocalizedString(@"turn_on_plugin");
        descText = OALocalizedString(@"plugin_popup_srtm_ask");
        okButtonName = OALocalizedString(@"plugins");
        cancelButtonName = OALocalizedString(@"shared_string_cancel");
        
        [popup.okButton addTarget:popup action:@selector(goToPlugins) forControlEvents:UIControlEventTouchUpInside];
    }
    else if ([kInAppId_Addon_OsmEditing isEqualToString:productIdentifier])
    {
        needShow = YES;
        product = helper.osmEditing;
        
        title = OALocalizedString(@"plugin_popup_osm_editing_title");
        descText = OALocalizedString(@"plugin_popup_osm_editing_ask");
        okButtonName = OALocalizedString(@"plugins");
        cancelButtonName = OALocalizedString(@"shared_string_cancel");
        
        [popup.okButton addTarget:popup action:@selector(goToPlugins) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (needShow)
    {
        NSString *iconName = [product productIconName];
        
        UIViewController *top = [OARootViewController instance].navigationController.topViewController;
        
        popup.icon.image = [UIImage templateImageNamed:iconName];
        popup.icon.tintColor = UIColorFromRGB(plugin_icon_green);
        popup.titleLabel.text = title;
        
        NSString *styledText = [self.class styledHTMLwithHTML:descText];
        popup.descTextView.attributedText = [self.class attributedStringWithHTML:styledText];
        
        [popup.okButton setTitle:okButtonName forState:UIControlStateNormal];
        [popup.cancelButton setTitle:cancelButtonName forState:UIControlStateNormal];
        
        [top addChildViewController:popup];
        [popup show];
    }
}

+ (void) showProductAlert:(OAProduct *)product afterPurchase:(BOOL)afterPurchase
{
    BOOL needShow = NO;
    
    OAPluginPopupViewController *popup = [[OAPluginPopupViewController alloc] initWithType:OAPluginPopupTypeProduct];
    popup.view.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 200.0);
    
    NSString *title;
    NSString *descText;
    NSString *okButtonName;
    NSString *cancelButtonName;
    id isShownPref = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"%@_alert_showed", product.productIdentifier]];
    
    OAIAPHelper *helper = [OAIAPHelper sharedInstance];
    if ([helper.skiMap isEqual:product])
    {
        if (isShownPref == nil)
        {
            needShow = YES;
            
            title = OALocalizedString(@"plugin_popup_ski_title");
            descText = OALocalizedString(@"plugin_popup_ski_desc");
            okButtonName = OALocalizedString(@"open_map_settings");
            cancelButtonName = OALocalizedString(@"shared_string_cancel");
            
            [popup.okButton addTarget:popup action:@selector(openMapSettings) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    else if ([helper.wiki isEqual:product])
    {
        if (isShownPref == nil)
        {
            needShow = YES;
            
            title = OALocalizedString(@"plugin_popup_wiki_title");
            descText = OALocalizedString(@"plugin_popup_wiki_desc");
            okButtonName = OALocalizedString(@"go_to_downloads");
            cancelButtonName = OALocalizedString(@"shared_string_later");
            
            [popup.okButton addTarget:popup action:@selector(goToDownloads) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    else if ([helper.srtm isEqual:product])
    {
        if (isShownPref == nil)
        {
            needShow = YES;
            
            title = OALocalizedString(@"plugin_popup_srtm_title");
            descText = OALocalizedString(@"plugin_popup_srtm_desc");
            okButtonName = OALocalizedString(@"go_to_downloads");
            cancelButtonName = OALocalizedString(@"shared_string_later");
            
            [popup.okButton addTarget:popup action:@selector(goToDownloads) forControlEvents:UIControlEventTouchUpInside];
        }
    }
    
    if (afterPurchase)
    {
        if ([helper.nautical isEqual:product])
        {
            if (isShownPref == nil)
            {
                needShow = YES;
                
                title = OALocalizedString(@"plugin_popup_nautical_title");
                descText = OALocalizedString(@"plugin_popup_nautical_desc");
                cancelButtonName = OALocalizedString(@"shared_string_later");
                
                [popup.okButton addTarget:popup action:@selector(downloadNautical) forControlEvents:UIControlEventTouchUpInside];
                
                std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> repositoryMap = [OsmAndApp instance].resourcesManager->getResourceInRepository(kWorldSeamarksKey);
                if (!repositoryMap)
                    repositoryMap = [OsmAndApp instance].resourcesManager->getResourceInRepository(kWorldSeamarksOldKey);

                if (repositoryMap)
                {
                    NSString* stringifiedSize = [NSByteCountFormatter stringFromByteCount:repositoryMap->packageSize
                                                                               countStyle:NSByteCountFormatterCountStyleFile];
                    okButtonName = [NSString stringWithFormat:@"%@ (%@)", OALocalizedString(@"download"), stringifiedSize];
                }
                else
                {
                    needShow = NO;
                }
            }
        }
    }
    
    if (needShow)
    {
        [[NSUserDefaults standardUserDefaults] setObject:@"OK" forKey:[NSString stringWithFormat:@"%@_alert_showed", product.productIdentifier]];
        
        NSString *iconName = [product productIconName];

        UIViewController *top = [OARootViewController instance].navigationController.topViewController;
        
        popup.icon.image = [UIImage templateImageNamed:iconName];
        popup.icon.tintColor = UIColorFromRGB(plugin_icon_green);
        popup.titleLabel.text = title;
        
        NSString *styledText = [self.class styledHTMLwithHTML:descText];
        popup.descTextView.attributedText = [self.class attributedStringWithHTML:styledText];
        
        [popup.okButton setTitle:okButtonName forState:UIControlStateNormal];
        [popup.cancelButton setTitle:cancelButtonName forState:UIControlStateNormal];
        
        [top addChildViewController:popup];
        [popup show];
    }
}

+ (NSString *) styledHTMLwithHTML:(NSString *)HTML
{
    NSString *style = @"<meta charset=\"UTF-8\"><style> body { font-family: -apple-system; font-size: 12px; color:#727272} b {font-family: -apple-system; font-weight: bolder; font-size: 12px; color:#727272 }</style>";
    
    return [NSString stringWithFormat:@"%@%@", style, HTML];
}

+ (NSAttributedString *)attributedStringWithHTML:(NSString *)HTML
{
    NSDictionary *options = @{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType };
    return [[NSAttributedString alloc] initWithData:[HTML dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:NULL error:NULL];
}

- (void) showOnMap
{
    if (self.worldRegion)
    {
        [[OARootViewController instance].navigationController popToRootViewControllerAnimated:YES];
        
        if (![[OARootViewController instance].mapPanel goToMyLocationIfInArea:_worldRegion.bboxTopLeft bottomRight:_worldRegion.bboxBottomRight])
        {
            [[OARootViewController instance].mapPanel displayAreaOnMap:_worldRegion.bboxTopLeft bottomRight:_worldRegion.bboxBottomRight zoom:7.0 bottomInset:0 leftInset:0];
        }
    }
    
    [self hide];
}

- (void) goToPlugins
{
    OAPluginsViewController *pluginsViewController = [[OAPluginsViewController alloc] init];
    [self.navigationController pushViewController:pluginsViewController animated:NO];
    [self hide];
}

- (void) openMapSettings
{
    [[OARootViewController instance].navigationController popToRootViewControllerAnimated:NO];
    [[OARootViewController instance].mapPanel mapSettingsButtonClick:nil];
}

- (void) goToDownloads
{
    [[OARootViewController instance].navigationController popToRootViewControllerAnimated:NO];
    OASuperViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController];
    [[OARootViewController instance].navigationController pushViewController:resourcesViewController animated:NO];
}

- (void) downloadWorldMap
{
    const auto repositoryMap = [OsmAndApp instance].resourcesManager->getResourceInRepository(kWorldBasemapKey);
    NSString* name = [OAResourcesUIHelper titleOfResource:repositoryMap
                                                 inRegion:[OsmAndApp instance].worldRegion
                                           withRegionName:YES withResourceType:NO];
    [OAResourcesUIHelper startBackgroundDownloadOf:repositoryMap resourceName:name];
    
    [self hide];
    
    [[OsmAndApp instance].resourcesRepositoryUpdatedObservable notifyEventWithKey:nil];
}

- (void) cancelDownloadWorldMap
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kMapDownloadStopReminding];
    [[NSUserDefaults standardUserDefaults] setDouble:[[NSDate date] timeIntervalSince1970] forKey:kMapDownloadReminderStoppedDate];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) downloadNautical
{
    // Download map
    std::shared_ptr<const OsmAnd::ResourcesManager::ResourceInRepository> repositoryMap = [OsmAndApp instance].resourcesManager->getResourceInRepository(kWorldSeamarksKey);
    if (!repositoryMap)
        repositoryMap = [OsmAndApp instance].resourcesManager->getResourceInRepository(kWorldSeamarksOldKey);

    if (repositoryMap)
    {
        NSString* name = [OAResourcesUIHelper titleOfResource:repositoryMap
                                                     inRegion:[OsmAndApp instance].worldRegion
                                               withRegionName:YES withResourceType:NO];
        
        [OAResourcesUIHelper startBackgroundDownloadOf:repositoryMap resourceName:name];
        
        [[OARootViewController instance].navigationController popToRootViewControllerAnimated:YES];
    }
}


@end
