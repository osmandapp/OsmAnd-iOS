//
//  OAFreeMemoryView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 17/05/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAFreeMemoryView.h"
#import "Localization.h"

@implementation OAFreeMemoryView
{
    UILabel *_titleLabel;
    UILabel *_freeMemLabel;
    
    double _sysVal;
    double _appVal;
    double _freeVal;

    unsigned long long _localResourcesSize;
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

- (void) layoutSubviews
{
    [_titleLabel sizeToFit];
    [_freeMemLabel sizeToFit];
    
    _titleLabel.frame = CGRectMake(15.0, 10.0, _titleLabel.bounds.size.width, _titleLabel.bounds.size.height);
    _freeMemLabel.frame = CGRectMake(self.frame.size.width - _freeMemLabel.bounds.size.width - 15.0, 10.0, _freeMemLabel.bounds.size.width, _freeMemLabel.bounds.size.height);
}

- (void) commonInit
{
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor whiteColor];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 10.0, 240.0, 20.0)];
    _titleLabel.textColor = [UIColor blackColor];
    _titleLabel.font = [UIFont systemFontOfSize:14.0];;
    _titleLabel.numberOfLines = 1;
    _titleLabel.text = OALocalizedString(@"device_memory");
    [self addSubview:_titleLabel];
    
    _freeMemLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 10.0, 240.0, 20.0)];
    _freeMemLabel.textColor = [UIColor blackColor];
    _freeMemLabel.font = [UIFont systemFontOfSize:14.0];;
    _freeMemLabel.numberOfLines = 1;
    [self addSubview:_freeMemLabel];
    
    [self update];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memInfoDidChange:) name:@"DiskUsageChangedNotification" object:nil];
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DiskUsageChangedNotification" object:nil];
}

- (void) memInfoDidChange:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self update];
        [self setNeedsDisplay];
    });
}

- (void) setLocalResourcesSize:(unsigned long long)size
{
    _localResourcesSize = size;
}

- (void) update
{
    NSError *error = nil;

    unsigned long long deviceMemoryCapacity = 0;
    unsigned long long deviceMemoryAvailable = 0;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    if (dictionary)
    {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        deviceMemoryCapacity = [fileSystemSizeInBytes unsignedLongLongValue];
        
        
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

    unsigned long long docSize = [OAUtilities folderSize:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject]];
    docSize += _localResourcesSize;
    unsigned long long usedBySystem = deviceMemoryCapacity - (docSize + deviceMemoryAvailable);
    
    unsigned long long capValue = deviceMemoryCapacity;
    unsigned long long systemValue = usedBySystem;
    unsigned long long availValue = deviceMemoryAvailable;
    unsigned long long docValue = docSize;
    
    _sysVal = (double) systemValue / capValue;
    _appVal = (double) docValue / capValue;
    _freeVal = (double) availValue / capValue;

    NSString *deviceMemoryAvailableStr = [NSByteCountFormatter stringFromByteCount:deviceMemoryAvailable countStyle:NSByteCountFormatterCountStyleFile];
    _freeMemLabel.text = [NSString stringWithFormat:OALocalizedString(@"free_memory"), deviceMemoryAvailableStr];
}

- (void) drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef rgbColorspace = CGColorSpaceCreateDeviceRGB();
    
    double radius = 3.0f;
    CGRect frame = CGRectMake(15, 35, DeviceScreenWidth - 30, 20);
    
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
    
    double treshold = 2.0;
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

@end
