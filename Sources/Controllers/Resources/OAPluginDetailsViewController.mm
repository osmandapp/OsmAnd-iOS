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

#define kPriceButtonTextInset 8.0
#define kPriceButtonMinTextWidth 80.0
#define kPriceButtonMinTextHeight 40.0
#define kPriceButtonRectBorder 15.0

@interface OAPluginDetailsViewController ()

@end

@implementation OAPluginDetailsViewController
{
    MBProgressHUD* _loadProductsProgressHUD;
    NSNumberFormatter *_numberFormatter;

    CALayer *_horizontalLineDesc;
    CALayer *_horizontalLine;
}

- (instancetype)initWithProductId:(NSString *)productId
{
    self = [super init];
    if (self)
    {
        _productId = productId;
    }
    return self;
}

- (void)applyLocalization
{
    self.descLabel.text = OALocalizedStringUp(@"description");

    [_btnToolbarMaps setTitle:OALocalizedString(@"maps") forState:UIControlStateNormal];
    [_btnToolbarPlugins setTitle:OALocalizedString(@"plugins") forState:UIControlStateNormal];
    [_btnToolbarPurchases setTitle:OALocalizedString(@"purchases") forState:UIControlStateNormal];
    [OAUtilities layoutComplexButton:self.btnToolbarMaps];
    [OAUtilities layoutComplexButton:self.btnToolbarPlugins];
    [OAUtilities layoutComplexButton:self.btnToolbarPurchases];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _loadProductsProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    //_loadProductsProgressHUD.dimBackground = YES;
    _loadProductsProgressHUD.minShowTime = .5f;
    
    [self.view addSubview:_loadProductsProgressHUD];

    _numberFormatter = [[NSNumberFormatter alloc] init];
    [_numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
    [_numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];

    _horizontalLine = [CALayer layer];
    _horizontalLine.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    self.bottomToolbarView.backgroundColor = UIColorFromRGB(kBottomToolbarBackgroundColor);
    [self.bottomToolbarView.layer addSublayer:_horizontalLine];

    _horizontalLineDesc = [CALayer layer];
    _horizontalLineDesc.backgroundColor = [UIColorFromRGB(kBottomToolbarTopLineColor) CGColor];
    [self.detailsView.layer addSublayer:_horizontalLineDesc];
    
    self.priceButton.layer.cornerRadius = 4;
    self.priceButton.layer.masksToBounds = YES;

    NSString *screenshotName = [OAIAPHelper productScreenshotName:_productId];
    if (screenshotName)
        self.screenshot.image = [UIImage imageNamed:screenshotName];
    
    NSString *iconName = [OAIAPHelper productIconName:_productId];
    if (iconName)
        self.icon.image = [UIImage imageNamed:iconName];
    
    [self updatePurchaseButton];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchased:) name:OAIAPProductPurchasedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(productPurchaseFailed:) name:OAIAPProductPurchaseFailedNotification object:nil];
    
    if (![[OAIAPHelper sharedInstance] productsLoaded])
    {
        [_loadProductsProgressHUD show:YES];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[OAIAPHelper sharedInstance] requestProductsWithCompletionHandler:^(BOOL success) {
                
                [self updatePurchaseButton];
                
                [_loadProductsProgressHUD hide:YES];
            }];
        });
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    _horizontalLine.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, 0.5);
    _horizontalLineDesc.frame = CGRectMake(15.0, 70.0, DeviceScreenWidth - 30.0, 0.5);
}

- (void)updatePurchaseButton
{
    NSString *title;
    NSString *desc;
    NSString *price;
    
    OAProduct *product = [[OAIAPHelper sharedInstance] product:_productId];
    if (product)
    {
        title = product.localizedTitle;
        desc = product.localizedDescriptionExt;
        if (product.price)
        {
            [_numberFormatter setLocale:product.priceLocale];
            price = [_numberFormatter stringFromNumber:product.price];
        }
        else
        {
            price = [OALocalizedString(@"shared_string_buy") uppercaseStringWithLocale:[NSLocale currentLocale]];
        }
    }
    
    self.titleLabel.text = title;
    self.descTextView.text = desc;
    self.descTextView.selectable = NO;
    
    BOOL purchased = [[OAIAPHelper sharedInstance] productPurchasedIgnoreDisable:_productId];
    BOOL disabled = [[OAIAPHelper sharedInstance] isProductDisabled:_productId];
    
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
    priceFrame.origin = CGPointMake(DeviceScreenWidth - priceSize.width - kPriceButtonRectBorder, 15.0);
    priceFrame.size = priceSize;
    self.priceButton.frame = priceFrame;
}

- (IBAction)priceButtonClicked:(id)sender
{
    BOOL purchased = [[OAIAPHelper sharedInstance] productPurchasedIgnoreDisable:_productId];
    BOOL disabled = [[OAIAPHelper sharedInstance] isProductDisabled:_productId];
    
    if (purchased)
    {
        if (disabled)
        {
            [[OAIAPHelper sharedInstance] enableProduct:_productId];
            [OAPluginPopupViewController showProductAlert:_productId afterPurchase:NO];
        }
        else
        {
            [[OAIAPHelper sharedInstance] disableProduct:_productId];
        }
        [self updatePurchaseButton];
        
        return;
    }
    
    OAProduct *product = [[OAIAPHelper sharedInstance] product:_productId];    
    if (product)
    {
        [_loadProductsProgressHUD show:YES];
        
        [[OAIAPHelper sharedInstance] buyProduct:product];
    }
}

- (void)productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_loadProductsProgressHUD hide:YES];
        
        [self updatePurchaseButton];

        [OAPluginPopupViewController showProductAlert:_productId afterPurchase:YES];

    });
}

- (void)productPurchaseFailed:(NSNotification *)notification
{
    NSString * identifier = notification.object;
    OAProduct *product = [[OAIAPHelper sharedInstance] product:identifier];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [_loadProductsProgressHUD hide:YES];
        
        if (product) {
            NSString *text = [NSString stringWithFormat:OALocalizedString(@"prch_failed"), product.localizedTitle];
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"" message:text delegate:self cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil];
            [alert show];
        }
    });
}

- (IBAction)btnToolbarMapsClicked:(id)sender
{
    NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    [controllers removeLastObject];
    [controllers removeLastObject];
    [self.navigationController setViewControllers:controllers];
}

- (IBAction)btnToolbarPurchasesClicked:(id)sender
{
    OAPurchasesViewController *purchasesViewController = [[OAPurchasesViewController alloc] init];
    purchasesViewController.openFromSplash = self.openFromSplash;
    
    NSMutableArray *controllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
    [controllers removeLastObject];
    [controllers removeLastObject];
    [controllers addObject:purchasesViewController];
    [self.navigationController setViewControllers:controllers];
}

@end
