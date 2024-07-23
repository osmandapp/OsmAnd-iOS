//
//  OACollapsableNearestPoiWikiView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACollapsableNearestPoiWikiView.h"
#import "OAPOI.h"
#import "OAWorldRegion.h"
#import "OARootViewController.h"
#import "OADownloadsManager.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OANativeUtilities.h"
#import "Localization.h"
#import "OAMapLayers.h"
#import "OAPOIUIFilter.h"
#import "OAIAPHelper.h"
#import "OAInAppCell.h"
#import "OAProducts.h"
#import "OAPluginDetailsViewController.h"
#import "OAManageResourcesViewController.h"
#import "OAWikiArticleHelper.h"
#import "OAWikiArticleHelper+cpp.h"
#import "OAPOIFiltersHelper.h"
#import "OAWikipediaPlugin.h"
#import "OAOsmAndFormatter.h"
#import "OAButton.h"
#import "OAPluginsHelper.h"
#import "GeneratedAssetSymbols.h"
#import "OsmAnd_Maps-Swift.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>

#define kButtonHeight 36.0
#define kDefaultZoomOnShow 16.0f

@interface OACollapsableNearestPoiWikiView () <OAButtonDelegate>

@end

@implementation OACollapsableNearestPoiWikiView
{
    UIView *_bannerView;
    UILabel *_bannerLabel;
    UIButton *_bannerButton;

    NSArray<OAButton *> *_buttons;
    NSInteger _selectedButtonIndex;
    double _latitude;
    double _longitude;
    OAPOIUIFilter *_filter;

    OAWorldRegion *_worldRegion;
    OARepositoryResourceItem *_resourceItem;
    NSInteger _buttonShowOnMapIndex;
    NSInteger _buttonSearchMoreIndex;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        // init
    }
    return self;
}

- (void) traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
        [self buildViews];
}

- (void)setData:(NSArray<OAPOI *> *)nearestItems hasItems:(BOOL)hasItems latitude:(double)latitude longitude:(double)longitude filter:(OAPOIUIFilter *)filter
{
    _nearestItems = nearestItems;
    _hasItems = hasItems;
    _latitude = latitude;
    _longitude = longitude;
    _filter = filter;
    [self buildViews];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    _bannerView.layer.backgroundColor = UIColorFromRGB(0x7bca62).CGColor;
}

- (void) setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    _bannerView.layer.backgroundColor = UIColorFromRGB(0x7bca62).CGColor;
}

- (void) buildViews
{
    if (!self.hasItems)
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        _worldRegion = [app.worldRegion findAtLat:_latitude lon:_longitude];
        _worldRegion = [OAWikiArticleHelper findWikiRegion:_worldRegion];
        
        NSString *regionName;
        if (_worldRegion)
        {
            _resourceItem = [OAWikiArticleHelper findResourceItem:_worldRegion];
            regionName = _worldRegion.localizedName;
        }
        else
        {
            regionName = OALocalizedString(@"download_wiki_region_placeholder");
        }
        
        if (_resourceItem && app.resourcesManager->isResourceInstalled(_resourceItem.resourceId))
        {
            _bannerView = nil;
            _bannerLabel = nil;
            _bannerButton = nil;
        }
        else
        {
            UIView *bannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
            bannerView.layer.cornerRadius = 4.0;
            bannerView.layer.masksToBounds = YES;
            bannerView.layer.backgroundColor = UIColorFromRGB(0x7bca62).CGColor;
            
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
            label.numberOfLines = 0;
            label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
            label.adjustsFontForContentSizeCategory = YES;
            label.textColor = [UIColor whiteColor];
            label.backgroundColor = UIColorFromRGB(0x7bca62);
            
            UIButton *actionButton = [UIButton buttonWithType:UIButtonTypeSystem];
            actionButton.frame = CGRectMake(0, 0, 100, 20);
            actionButton.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
            actionButton.titleLabel.textColor = [UIColor whiteColor];
            actionButton.layer.cornerRadius = 4.0;
            actionButton.layer.masksToBounds = YES;
            [actionButton setBackgroundImage:[OAUtilities imageWithColor:UIColorFromRGB(0xfdc52e)] forState:UIControlStateNormal];
            actionButton.tintColor = [UIColor whiteColor];
            
            [actionButton addTarget:self action:@selector(actionButtonPress:) forControlEvents:UIControlEventTouchUpInside];
            
            OAIAPHelper *helper = [OAIAPHelper sharedInstance];
            if ([helper.wiki isPurchased])
                label.text = [NSString stringWithFormat:OALocalizedString(@"wiki_download_description"), regionName];
            else
                label.text = [NSString stringWithFormat:OALocalizedString(@"wiki_buy_description"), regionName];
            
            [bannerView addSubview:label];
            [bannerView addSubview:actionButton];
            
            _bannerView = bannerView;
            _bannerLabel = label;
            
            _bannerButton = actionButton;
            [self updateButton];
            
            [self addSubview:bannerView];
            
            if (![helper productsLoaded] && AFNetworkReachabilityManager.sharedManager.isReachable)
            {
                [helper requestProductsWithCompletionHandler:^(BOOL success) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self updateButton];
                    });
                }];
            }
        }
    }

    OAWikipediaPlugin *wikiPlugin = (OAWikipediaPlugin *) [OAPluginsHelper getEnabledPlugin:OAWikipediaPlugin.class];
    NSMutableArray *buttons = [NSMutableArray arrayWithCapacity:self.nearestItems.count + 2];
    int i = 0;
    for (OAPOI *poi in self.nearestItems)
    {
        const auto distance = OsmAnd::Utilities::distance(poi.longitude, poi.latitude, _longitude, _latitude);

        NSString *language = [poi.localizedNames.allKeys firstObjectCommonWithArray:[wikiPlugin getLanguagesToShow]];
        NSString *nameLocalized = poi.localizedNames[language];
        if (!nameLocalized)
            nameLocalized = poi.nameLocalized;

        NSString *title = [NSString stringWithFormat:@"%@ (%@)", nameLocalized, [OAOsmAndFormatter getFormattedDistance:distance]];
        OAButton *btn = [self createButton:title tapToCopy:NO longPressToCopy:YES];
        btn.tag = i++;
        [self addSubview:btn];
        [buttons addObject:btn];
    }

    OAButton *showOnMapButton = [self createButton:OALocalizedString(@"shared_string_show_on_map")
                                         tapToCopy:NO
                                   longPressToCopy:NO];
    showOnMapButton.tag = _buttonShowOnMapIndex = i++;
    [self addSubview:showOnMapButton];
    [buttons addObject:showOnMapButton];

    OAButton *searchMoreButton = [self createButton:OALocalizedString(@"search_more")
                                          tapToCopy:NO
                                    longPressToCopy:NO];
    searchMoreButton.tag = _buttonSearchMoreIndex = i++;
    [self addSubview:searchMoreButton];
    [buttons addObject:searchMoreButton];

    _buttons = [NSArray arrayWithArray:buttons];
}

- (OAButton *)createButton:(NSString *)title
                 tapToCopy:(BOOL)tapToCopy
           longPressToCopy:(BOOL)longPressToCopy
{
    OAButton *btn = [OAButton buttonWithType:UIButtonTypeSystem];
    [btn setTitle:title forState:UIControlStateNormal];
    btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    btn.contentEdgeInsets = UIEdgeInsetsMake(0, 12.0, 0, 12.0);
    btn.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    btn.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
    btn.layer.cornerRadius = 4.0;
    btn.layer.masksToBounds = YES;
    btn.layer.borderWidth = 0.8;
    btn.layer.borderColor = [UIColor colorNamed:ACColorNameCustomSeparator].CGColor;
    [btn setBackgroundImage:[OAUtilities imageWithColor:UIColor.clearColor] forState:UIControlStateNormal];
    btn.tintColor = [UIColor colorNamed:ACColorNameTextColorActive];
    btn.delegate = self;
    return btn;
}

- (void) updateButton
{
    OAIAPHelper *helper = [OAIAPHelper sharedInstance];
    if ([helper.wiki isPurchased])
    {
        [_bannerButton setTitle:[OALocalizedString(@"shared_string_download") upperCase] forState:UIControlStateNormal];
    }
    else
    {
        OAProduct *product = [helper product:kInAppId_Addon_Wiki];
        NSString *price;
        if (!product.free)
            price = [OALocalizedString(@"buy") upperCase];
        [_bannerButton setTitle:price forState:UIControlStateNormal];
    }
    
    [_bannerButton sizeToFit];
    CGSize priceSize = CGSizeMake(MAX(kPriceMinTextWidth, _bannerButton.bounds.size.width + (_bannerButton.titleLabel.text.length > 0 ? kPriceTextInset * 2.0 : 0.0)), kPriceMinTextHeight);
    CGRect priceFrame = _bannerButton.frame;
    priceFrame.size = priceSize;
    _bannerButton.frame = priceFrame;
}

- (void) updateLayout:(CGFloat)width
{
    CGFloat y = 0;
    CGFloat viewHeight = 0;
    
    if (!self.hasItems && _bannerView)
    {
        CGSize labelSize = [OAUtilities calculateTextBounds:_bannerLabel.text width:width - 65.0 - 10.0 - 10.0 font:_bannerLabel.font];
        _bannerView.frame = CGRectMake(kMarginLeft, 0.0, width - kMarginLeft - kMarginRight, 12.0 + labelSize.height + 10.0 + _bannerButton.bounds.size.height + 10.0);
        _bannerLabel.frame = CGRectMake(12.0, 12.0, _bannerView.bounds.size.width - 24.0, labelSize.height);
        _bannerButton.frame = CGRectMake(12.0, _bannerLabel.frame.origin.y + _bannerLabel.frame.size.height + 10.0, _bannerButton.bounds.size.width, _bannerButton.bounds.size.height);
        viewHeight += _bannerView.bounds.size.height + 10.0;
        y += viewHeight;
    }
    
    int i = 0;
    for (OAButton *btn in _buttons)
    {
        if (i > 0)
        {
            y += kButtonHeight + 10.0;
            viewHeight += 10.0;
        }
        
        btn.frame = CGRectMake(kMarginLeft, y, width - kMarginLeft - kMarginRight, kButtonHeight);
        viewHeight += kButtonHeight;
        i++;
    }
    
    viewHeight += 8.0;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, viewHeight);
}

- (void) goToPoint:(OAPOI *)poi
{
    const OsmAnd::LatLon latLon(poi.latitude, poi.longitude);
    OAMapViewController* mapVC = [OARootViewController instance].mapPanel.mapViewController;
    Point31 pos = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
    [mapVC goToPosition:pos andZoom:kDefaultZoomOnShow animated:YES];
    [mapVC showContextPinMarker:poi.latitude longitude:poi.longitude animated:NO];
    
    OATargetPoint *targetPoint = [mapVC.mapLayers.poiLayer getTargetPoint:poi];
    targetPoint.centerMap = YES;
    [[OARootViewController instance].mapPanel showContextMenu:targetPoint];
}

- (void) adjustHeightForWidth:(CGFloat)width
{
    [self updateLayout:width];
}

- (void) actionButtonPress:(id)sender
{
    [[OARootViewController instance].mapPanel hideContextMenu];

    OAIAPHelper *helper = [OAIAPHelper sharedInstance];
    if (![helper.wiki isPurchased])
    {
        OAPluginDetailsViewController *pluginDetails = [[OAPluginDetailsViewController alloc] initWithProduct:helper.wiki];
        [[OARootViewController instance].navigationController pushViewController:pluginDetails animated:YES];
    }
    else if (_worldRegion && _resourceItem)
    {
        OsmAndAppInstance app = [OsmAndApp instance];
        if (_resourceItem && [app.downloadsManager downloadTasksWithKey:[@"resource:" stringByAppendingString:_resourceItem.resourceId.toNSString()]].count == 0)
        {
            NSString *resourceName = [OAResourcesUIHelper titleOfResource:_resourceItem.resource
                                                                 inRegion:_resourceItem.worldRegion
                                                           withRegionName:YES
                                                         withResourceType:YES];
            
            [OAResourcesUIHelper startBackgroundDownloadOf:_resourceItem.resource resourceName:resourceName];
        }
    }
    else
    {
        OASuperViewController* resourcesViewController = [[UIStoryboard storyboardWithName:@"Resources" bundle:nil] instantiateInitialViewController];
        [[OARootViewController instance].navigationController pushViewController:resourcesViewController animated:YES];
    }
}

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return [sender isKindOfClass:UIMenuController.class] && action == @selector(copy:);
}

- (void)copy:(id)sender
{
    if (_buttons.count > _selectedButtonIndex)
    {
        OAButton *button = _buttons[_selectedButtonIndex];
        UIPasteboard *pb = [UIPasteboard generalPasteboard];
        [pb setString:button.titleLabel.text];
    }
}

#pragma mark - OACustomButtonDelegate

- (void)onButtonTapped:(NSInteger)tag
{
    if (self.nearestItems.count > tag)
    {
        OAPOI *item = self.nearestItems[tag];
        if (item)
            [self goToPoint:item];
    }
    else
    {
        [[OARootViewController instance].mapPanel hideContextMenu];
        if (tag == _buttonShowOnMapIndex)
        {
            [[OARootViewController instance].mapPanel showPoiToolbar:_filter latitude:_latitude longitude:_longitude];
            OAPOIFiltersHelper *helper = [OAPOIFiltersHelper sharedInstance];
            [helper clearSelectedPoiFilters];
            [helper addSelectedPoiFilter:_filter];
            [[OARootViewController instance].mapPanel.mapViewController updatePoiLayer];
        }
        else if (tag == _buttonSearchMoreIndex)
        {
            [[OARootViewController instance].mapPanel openSearch:_filter location:[[CLLocation alloc] initWithLatitude:_latitude longitude:_longitude]];
        }
    }
}

- (void)onButtonLongPressed:(NSInteger)tag
{
    if (tag != _buttonShowOnMapIndex && tag != _buttonSearchMoreIndex)
    {
        _selectedButtonIndex = tag;
        if (_buttons.count > _selectedButtonIndex)
            [OAUtilities showMenuInView:self fromView:_buttons[_selectedButtonIndex]];
    }
}

@end
