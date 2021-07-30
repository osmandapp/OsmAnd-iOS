//
//  OAPluginDetailsViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 22/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAPluginDetailsViewController.h"
#import "OAUtilities.h"
#import "OAIAPHelper.h"
#import "Localization.h"
#import "OAPluginPopupViewController.h"
#import "OAPurchasesViewController.h"
#import <Reachability.h>
#import "OASizes.h"
#import "OARootViewController.h"
#import "OAChoosePlanHelper.h"
#import "OAPlugin.h"
#import "OAColors.h"

#define kPriceButtonTextInset 8.0
#define kPriceButtonMinTextWidth 80.0
#define kPriceButtonMinTextHeight 40.0
#define kPriceButtonRectBorder 15.0

typedef NS_ENUM(NSInteger, EOAPluginScreenType) {
    EOAPluginScreenTypeProduct = 0,
    EOAPluginScreenTypeCustomPlugin
};

@interface OAPluginDetailsViewController ()

@end

@implementation OAPluginDetailsViewController
{
    OAIAPHelper *_iapHelper;
    OAPlugin *_plugin;
    
    EOAPluginScreenType _screenType;

    CALayer *_horizontalLineDesc;
}

- (instancetype) initWithProduct:(OAProduct *)product
{
    self = [super init];
    if (self)
    {
        _product = product;
        _screenType = EOAPluginScreenTypeProduct;
    }
    return self;
}

- (instancetype) initWithCustomPlugin:(OAPlugin *)plugin
{
    self = [super init];
    if (self)
    {
        _plugin = plugin;
        _screenType = EOAPluginScreenTypeCustomPlugin;
    }
    return self;
}

- (void) applyLocalization
{
    self.descLabel.text = OALocalizedStringUp(@"description");
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    _iapHelper = [OAIAPHelper sharedInstance];

    _horizontalLineDesc = [CALayer layer];
    _horizontalLineDesc.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    [self.detailsView.layer addSublayer:_horizontalLineDesc];
    
    self.priceButton.layer.cornerRadius = 4;
    self.priceButton.layer.masksToBounds = YES;
    
    self.buttonDeleteCustomPlugin.hidden = _screenType != EOAPluginScreenTypeCustomPlugin;
    self.buttonDeleteCustomPlugin.userInteractionEnabled = !self.buttonDeleteCustomPlugin.hidden;

    UIImage *screenshotImage;
    if (_screenType == EOAPluginScreenTypeProduct)
    {
        NSString *screenshotName = [_product productScreenshotName];
        if (screenshotName)
            screenshotImage = [UIImage imageNamed:screenshotName];
    }
    else if (_screenType == EOAPluginScreenTypeCustomPlugin)
    {
        screenshotImage = _plugin.getAssetResourceImage;
    }
    self.screenshot.image = screenshotImage;
    
    UIImage *logo;
    if (_screenType == EOAPluginScreenTypeProduct)
    {
        NSString *iconName = [_product productIconName];
        if (iconName)
        {
            logo = [UIImage templateImageNamed:iconName];
            self.icon.tintColor = UIColorFromRGB(plugin_icon_green);
        }
        self.icon.contentMode = UIViewContentModeCenter;
    }
    else if (_screenType == EOAPluginScreenTypeCustomPlugin)
    {
        logo = [_plugin getLogoResource];
        self.icon.contentMode = UIViewContentModeScaleAspectFit;
    }
    self.icon.image = logo;
    
    [self applySafeAreaMargins];
    [self updatePurchaseButton];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productsRequested:) name:OAIAPProductsRequestSucceedNotification object:nil];

    [[OARootViewController instance] requestProductsWithProgress:YES reload:NO];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    
    CGFloat w;

    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
    {
        w = DeviceScreenWidth;
        _screenshot.frame = CGRectMake(0.0, 0.0, w, 220.0);
        
        _detailsView.frame = CGRectMake(0.0, _screenshot.frame.size.height, w, DeviceScreenHeight - _screenshot.frame.size.height);
    }
    else
    {
        w = DeviceScreenWidth / 2.0;
        
        _screenshot.frame = CGRectMake(0.0, 0.0, w, DeviceScreenHeight);
        
        _detailsView.frame = CGRectMake(w, 0.0, DeviceScreenWidth - w, DeviceScreenHeight);
        
    }

    _toolbarView.frame = CGRectMake(0.0, 0.0, w, _toolbarView.frame.size.height);
    _titleLabel.frame = CGRectMake(50.0, _titleLabel.frame.origin.y, w - 100.0, _titleLabel.frame.size.height);
    _gradient.frame = _toolbarView.bounds;

    _priceButton.frame = CGRectMake(_detailsView.frame.size.width - _priceButton.frame.size.width - 15.0, 15.0, _priceButton.frame.size.width, _priceButton.frame.size.height);
    
    _buttonDeleteCustomPlugin.frame = CGRectMake(CGRectGetMinX(_priceButton.frame) - 16. - 30., CGRectGetMinY(_priceButton.frame) + 5.0, 30., 30.);

    _descLabel.frame = CGRectMake(15.0, 85.0, w - 30.0, _descLabel.frame.size.height);
    _descTextView.frame = CGRectMake(10.0, 105.0, w - 20.0, _detailsView.frame.size.height - 105.0);
    
    _horizontalLineDesc.frame = CGRectMake(15.0, 70.0, _detailsView.frame.size.width - 30.0, 0.5);

}


- (UIView *) getTopView
{
    return self.toolbarView;
}

- (UIView *) getMiddleView
{
    return self.detailsView;
}

- (CGFloat) getToolBarHeight
{
    return defaultToolBarHeight;
}

- (void) updatePurchaseButton
{
    NSString *title;
    NSString *desc = nil;
    NSAttributedString *attrDesc = nil;
    NSString *price;
    
    if (_screenType == EOAPluginScreenTypeProduct)
    {
        title = _product.localizedTitle;
        desc = _product.localizedDescriptionExt;
        if (_product.price)
            price = _product.formattedPrice;
        else
            price = [OALocalizedString(@"shared_string_buy") uppercaseStringWithLocale:[NSLocale currentLocale]];
    }
    else if (_screenType == EOAPluginScreenTypeCustomPlugin)
    {
        title = _plugin.getName;
        attrDesc = [OAUtilities attributedStringFromHtmlString:_plugin.getDescription fontSize:17];
    }
    
    self.titleLabel.text = title;
    self.descTextView.selectable = NO;
    
    if (desc)
        self.descTextView.text = desc;
    else if (attrDesc)
    {
        self.descTextView.attributedText = attrDesc;
        self.descTextView.linkTextAttributes = @{NSForegroundColorAttributeName: UIColorFromRGB(color_primary_purple)};
    }
    
    BOOL purchased = NO;
    BOOL disabled = YES;
    
    if (_screenType == EOAPluginScreenTypeProduct)
    {
        purchased = [_product isPurchased];
        disabled = _product.disabled;
    }
    else if (_screenType == EOAPluginScreenTypeCustomPlugin)
    {
        purchased = YES;
        disabled = !_plugin.isActive;
    }
    
    if (purchased)
    {
        [self.priceButton setTitle:@"" forState:UIControlStateNormal];
        if (!disabled)
        {
            self.priceButton.layer.borderWidth = 0.0;
            self.priceButton.backgroundColor = UIColorFromRGB(0xff8f00);
            self.priceButton.tintColor = [UIColor whiteColor];
            [self.priceButton setImage:[UIImage imageNamed:@"ic_checkmark_big_enable"] forState:UIControlStateNormal];
        }
        else
        {
            self.priceButton.layer.borderWidth = 0.8;
            self.priceButton.layer.borderColor = UIColorFromRGB(0xff8f00).CGColor;
            self.priceButton.backgroundColor = [UIColor clearColor];
            self.priceButton.tintColor = UIColorFromRGB(0xff8f00);
            [self.priceButton setImage:[UIImage imageNamed:@"ic_checkmark_big_enable"] forState:UIControlStateNormal];
        }
    }
    else
    {
        self.priceButton.layer.borderWidth = 0.0;
        self.priceButton.backgroundColor = UIColorFromRGB(0xff8f00);
        self.priceButton.tintColor = [UIColor whiteColor];
        [self.priceButton setTitle:price forState:UIControlStateNormal];
    }
    
    [self.priceButton sizeToFit];
    CGSize priceSize = CGSizeMake(MAX(kPriceButtonMinTextWidth, self.priceButton.bounds.size.width + (!purchased ? kPriceButtonTextInset * 2.0 : 0.0)), kPriceButtonMinTextHeight);
    CGRect priceFrame = self.priceButton.frame;
    priceFrame.origin = CGPointMake(_detailsView.frame.size.width - priceSize.width - kPriceButtonRectBorder, 15.0);
    priceFrame.size = priceSize;
    self.priceButton.frame = priceFrame;
}

- (IBAction)deleteButtonClicked:(id)sender
{
    [OAPlugin removeCustomPlugin:(OACustomPlugin *)_plugin];
    [self backButtonClicked:nil];
}

- (IBAction) priceButtonClicked:(id)sender
{
    if (_screenType == EOAPluginScreenTypeProduct)
    {
        BOOL purchased = [_product isPurchased];
        BOOL disabled = _product.disabled;
        if (purchased)
        {
            if (disabled)
            {
                [_iapHelper enableProduct:_product.productIdentifier];
                [OAPluginPopupViewController showProductAlert:_product afterPurchase:NO];
            }
            else
            {
                [_iapHelper disableProduct:_product.productIdentifier];
            }
            [self updatePurchaseButton];
            
            return;
        }
        
    //    [[OARootViewController instance] buyProduct:_product showProgress:YES];
        [OAChoosePlanHelper showChoosePlanScreenWithProduct:_product navController:self.navigationController];
    }
    else
    {
        [OAPlugin enablePlugin:_plugin enable:!_plugin.isActive];
        [self updatePurchaseButton];
    }
}

- (void) productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updatePurchaseButton];
        [OAPluginPopupViewController showProductAlert:_product afterPurchase:YES];
    });
}

- (void) productsRequested:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updatePurchaseButton];
    });
}

@end
