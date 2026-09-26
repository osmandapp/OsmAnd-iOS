//
//  OAFreeMemoryView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 17/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAFreeMemoryView.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@implementation OAFreeMemoryView
{
    UILabel *_titleLabel;
    UILabel *_freeMemLabel;
    
    double _sysVal;
    double _appVal;
    double _freeVal;

    unsigned long long _localResourcesSize;
    unsigned long long _deviceMemoryCapacity;
    unsigned long long _deviceMemoryAvailable;
    unsigned long long _documentsSize;
    NSUInteger _updateGeneration;

    OsmAndAppInstance _app;
    OAAutoObserverProxy* _localResourcesChangedObserver;
}

- (instancetype) initWithFrame:(CGRect)frame localResourcesSize:(unsigned long long)localResourcesSize
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _localResourcesSize = localResourcesSize;
        [self commonInit];
    }
    return self;
}

// Horizontal insets of the content: the 15 pt margin plus the safe area, so the labels and the bar
// stay clear of the notch / Dynamic Island in landscape (the table view does not inset custom header views)
- (UIEdgeInsets) contentInsets
{
    UIEdgeInsets safeArea = self.safeAreaInsets;
    return UIEdgeInsetsMake(0.0, 15.0 + safeArea.left, 0.0, 15.0 + safeArea.right);
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    UIEdgeInsets insets = [self contentInsets];
    [_titleLabel sizeToFit];
    [_freeMemLabel sizeToFit];

    _titleLabel.frame = CGRectMake(insets.left, 10.0, _titleLabel.bounds.size.width, _titleLabel.bounds.size.height);
    _freeMemLabel.frame = CGRectMake(self.bounds.size.width - _freeMemLabel.bounds.size.width - insets.right, 10.0, _freeMemLabel.bounds.size.width, _freeMemLabel.bounds.size.height);
    [self setNeedsDisplay];
}

- (void) safeAreaInsetsDidChange
{
    [super safeAreaInsetsDidChange];
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void) commonInit
{
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.clipsToBounds = YES;
    self.contentMode = UIViewContentModeRedraw;
    self.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];

    _sysVal = 0;
    _appVal = 0;
    _freeVal = 0;
    _deviceMemoryCapacity = 1;
    _deviceMemoryAvailable = 0;
    _documentsSize = 0;
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 10.0, 240.0, 20.0)];
    _titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
    _titleLabel.font = [UIFont scaledSystemFontOfSize:14.0];
    _titleLabel.adjustsFontForContentSizeCategory = YES;
    _titleLabel.numberOfLines = 1;
    _titleLabel.text = OALocalizedString(@"device_memory");
    [self addSubview:_titleLabel];
    
    _freeMemLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 10.0, 240.0, 20.0)];
    _freeMemLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
    _freeMemLabel.font = [UIFont scaledSystemFontOfSize:14.0];
    _freeMemLabel.adjustsFontForContentSizeCategory = YES;
    _freeMemLabel.numberOfLines = 1;
    [self addSubview:_freeMemLabel];
    
    [self update];

    _app = [OsmAndApp instance];
    _localResourcesChangedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onLocalResourcesChanged:withKey:)
                                                                andObserve:_app.localResourcesChangedObservable];
}

- (void) dealloc
{
    if (_localResourcesChangedObserver)
    {
        [_localResourcesChangedObserver detach];
        _localResourcesChangedObserver = nil;
    }
}

- (void) setLocalResourcesSize:(unsigned long long)size
{
    _localResourcesSize = size;
}

- (void) update
{
    NSError *error = nil;

    unsigned long long deviceMemoryCapacity = 1;
    unsigned long long deviceMemoryAvailable = 0;
    
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:NSHomeDirectory() error: &error];
    if (dictionary && !error)
    {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        deviceMemoryCapacity = [fileSystemSizeInBytes unsignedLongLongValue];
        if (deviceMemoryCapacity <= 0)
        {
            NSLog(@"Error obtaining dvice memory capacity");
            deviceMemoryCapacity = 1;
        }
        
        NSURL *home = [NSURL fileURLWithPath:NSHomeDirectory()];
        NSDictionary *results = [home resourceValuesForKeys:@[NSURLVolumeAvailableCapacityForImportantUsageKey] error:&error];
        if (results)
            deviceMemoryAvailable = [results[NSURLVolumeAvailableCapacityForImportantUsageKey] unsignedLongLongValue];

        if (deviceMemoryAvailable == 0)
        {
            NSNumber *fileSystemFreeSizeInBytes = [dictionary objectForKey: NSFileSystemFreeSize];
            deviceMemoryAvailable = [fileSystemFreeSizeInBytes unsignedLongLongValue];
        }
    }
    else
    {
        NSLog(@"Error Obtaining File System Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }

    _deviceMemoryCapacity = deviceMemoryCapacity;
    _deviceMemoryAvailable = deviceMemoryAvailable;
    [self applyValues];

    NSString *deviceMemoryAvailableStr = [NSByteCountFormatter stringFromByteCount:deviceMemoryAvailable countStyle:NSByteCountFormatterCountStyleFile];
    _freeMemLabel.text = [NSString stringWithFormat:OALocalizedString(@"free"), deviceMemoryAvailableStr];
    [_freeMemLabel sizeToFit];
    [self setNeedsLayout];

    // Walking the whole Documents folder (maps, tiles, tracks) takes seconds on a full device,
    // so it runs off the main thread and the bar is redrawn when the size is known
    NSUInteger generation = ++_updateGeneration;
    unsigned long long localResourcesSize = _localResourcesSize;
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        unsigned long long docSize = [OAUtilities folderSize:documentsPath] + localResourcesSize;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            if (!strongSelf || strongSelf->_updateGeneration != generation)
                return;

            strongSelf->_documentsSize = docSize;
            [strongSelf applyValues];
            [strongSelf setNeedsDisplay];
        });
    });
}

// Until the Documents size is known the app share is 0 and everything used counts as system
- (void) applyValues
{
    unsigned long long capValue = _deviceMemoryCapacity;
    unsigned long long availValue = _deviceMemoryAvailable;
    unsigned long long docValue = _documentsSize;
    unsigned long long systemValue = capValue - (docValue + availValue);

    _sysVal = (double) systemValue / capValue;
    _appVal = (double) docValue / capValue;
    _freeVal = (double) availValue / capValue;
    double sum = _sysVal + _appVal + _freeVal;
    if (sum > 1.5 || sum <= 0)
    {
        NSLog(@"Incorrect storage calculation (total:%llu, system:%llu, free:%llu, doc:%llu)", capValue, systemValue, availValue, docValue);
        _sysVal = 0;
        _appVal = 0;
        _freeVal = 1;
    }
}

- (void) drawRect:(CGRect)rect
{
    double treshold = 2.0;
    UIEdgeInsets insets = [self contentInsets];
    CGRect frame = CGRectMake(insets.left, 35, self.bounds.size.width - insets.left - insets.right, 20);
    // The shrink loop below never takes a segment under treshold + 0.1, so it would not end on a narrower bar
    if (frame.size.width < 3 * (treshold + 0.1))
        return;

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef rgbColorspace = CGColorSpaceCreateDeviceRGB();
    
    double radius = 3.0f;
    
    /*
    CGFloat compShadow[4] = { 0.2, 0.2, 0.2, 0.9 };
    CGColorRef shadowColor = CGColorCreate(rgbColorspace, compShadow);
    
    CGFloat compFill[4] = { 1.0, 1.0, 1.0, 1.0 };
    CGColorRef fillColor = CGColorCreate(rgbColorspace, compFill);
    
    CGContextSaveGState(context);
    CGContextSetShadowWithColor(context, CGSizeMake(0, 0), 1.0, shadowColor);
    CGContextBeginPath(context);
    //CGContextSetGrayFillColor(context, 0.5, 0.7);
    CGContextMoveToPoint(context, CGRectGetMinX(frame) + radius, CGRectGetMinY(frame));
    CGContextAddArc(context, CGRectGetMaxX(frame) - radius, CGRectGetMinY(frame) + radius, radius, 3 * M_PI / 2, 0, 0);
    CGContextAddArc(context, CGRectGetMaxX(frame) - radius, CGRectGetMaxY(frame) - radius, radius, 0, M_PI / 2, 0);
    CGContextAddArc(context, CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame) - radius, radius, M_PI / 2, M_PI, 0);
    CGContextAddArc(context, CGRectGetMinX(frame) + radius, CGRectGetMinY(frame) + radius, radius, M_PI, 3 * M_PI / 2, 0);
    
    CGContextClosePath(context);
    CGContextSetFillColorWithColor(context, fillColor);
    CGContextFillPath(context);
    CGContextRestoreGState(context);
    */
    
    CGGradientRef glossGradientSys;
    CGGradientRef glossGradientApp;
    CGGradientRef glossGradientFree;
    
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    
    double values[3] = { _sysVal, _appVal, _freeVal };
    double total = 0;
    for (int i = 0; i < 3; i++)
    {
        values[i] *= frame.size.width;
        if (values[i] < treshold)
            values[i] = treshold;
        
        total += values[i];
    }
    
    int index = 0;
    while (total > frame.size.width)
    {
        if (values[index] > treshold + 0.1)
            values[index] -= 0.1;

        index++;
        if (index > 2)
            index = 0;
        
        total = values[0] + values[1] + values[2];
    }

    CGFloat componentsSys[8] = { 41/255.0, 234/255.0, 186/255.0, 1.0,  // Start color
        20/255.0, 204/255.0, 158/255.0, 1.0 }; // End color
    glossGradientSys = CGGradientCreateWithColorComponents(rgbColorspace, componentsSys, locations, num_locations);

    CGFloat componentsApp[8] = { 255/255.0, 165/255.0, 89/255.0, 1.0,  // Start color
        255/255.0, 128/255.0, 0/255.0, 1.0 }; // End color
    glossGradientApp = CGGradientCreateWithColorComponents(rgbColorspace, componentsApp, locations, num_locations);
    
    CGFloat componentsFree[8] = { 30/255.0, 30/255.0, 30/255.0, 1.0,  // Start color
        120/255.0, 120/255.0, 120/255.0, 1.0 }; // End color
    glossGradientFree = CGGradientCreateWithColorComponents(rgbColorspace, componentsFree, locations, num_locations);
    
    CGContextSaveGState(context);
    
    CGContextBeginPath(context);
    CGContextSetGrayFillColor(context, 0.5, 0.7);
    CGContextMoveToPoint(context, CGRectGetMinX(frame) + radius, CGRectGetMinY(frame));
    CGContextAddLineToPoint(context, CGRectGetMinX(frame) + values[0], CGRectGetMinY(frame));
    CGContextAddLineToPoint(context, CGRectGetMinX(frame) + values[0], CGRectGetMaxY(frame));
    CGContextAddLineToPoint(context, CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame));
    CGContextAddArc(context, CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame) - radius, radius, M_PI / 2, M_PI, 0);
    CGContextAddArc(context, CGRectGetMinX(frame) + radius, CGRectGetMinY(frame) + radius, radius, M_PI, 3 * M_PI / 2, 0);
    
    CGContextClosePath(context);
    CGContextClip(context);
    
    CGPoint topCenter = CGPointMake(CGRectGetMidX(frame), 0.0f);
    CGPoint midCenter = CGPointMake(CGRectGetMidX(frame), CGRectGetMaxY(frame));
    CGContextDrawLinearGradient(context, glossGradientSys, topCenter, midCenter, 0);
    
    CGContextRestoreGState(context);
    CGContextSaveGState(context);
    
    CGContextAddRect(context, CGRectMake(CGRectGetMinX(frame) + values[0], CGRectGetMinY(frame), values[1], frame.size.height));
    CGContextClip(context);
    
    topCenter = CGPointMake(CGRectGetMidX(frame), 0.0f);
    midCenter = CGPointMake(CGRectGetMidX(frame), CGRectGetMaxY(frame));
    CGContextDrawLinearGradient(context, glossGradientApp, topCenter, midCenter, 0);
    
    CGContextRestoreGState(context);
    CGContextSaveGState(context);
    
    CGContextBeginPath(context);
    CGContextSetGrayFillColor(context, 0.5, 0.7);
    CGContextMoveToPoint(context, CGRectGetMaxX(frame) - values[2], CGRectGetMinY(frame));
    CGContextAddArc(context, CGRectGetMaxX(frame) - radius, CGRectGetMinY(frame) + radius, radius, 3 * M_PI / 2, 0, 0);
    CGContextAddArc(context, CGRectGetMaxX(frame) - radius, CGRectGetMaxY(frame) - radius, radius, 0, M_PI / 2, 0);
    CGContextAddLineToPoint(context, CGRectGetMaxX(frame) - values[2], CGRectGetMaxY(frame));
    
    CGContextClosePath(context);
    CGContextClip(context);
    
    topCenter = CGPointMake(CGRectGetMidX(frame), 0.0f);
    midCenter = CGPointMake(CGRectGetMidX(frame), CGRectGetMaxY(frame));
    CGContextDrawLinearGradient(context, glossGradientFree, topCenter, midCenter, 0);
    
    CGContextRestoreGState(context);
    
    //CGColorRelease(fillColor);
    //CGColorRelease(shadowColor);
    CGGradientRelease(glossGradientSys);
    CGGradientRelease(glossGradientApp);
    CGGradientRelease(glossGradientFree);
    CGColorSpaceRelease(rgbColorspace);
}

- (void) onLocalResourcesChanged:(id<OAObservableProtocol>)observer withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self update];
        [self setNeedsDisplay];
    });
}

@end
