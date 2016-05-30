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
    
    float _sysVal;
    float _appVal;
    float _tmpVal;
    float _freeVal;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)layoutSubviews
{
    [_titleLabel sizeToFit];
    [_freeMemLabel sizeToFit];
    
    _titleLabel.frame = CGRectMake(15.0, 10.0, _titleLabel.bounds.size.width, _titleLabel.bounds.size.height);
    _freeMemLabel.frame = CGRectMake(self.frame.size.width - _freeMemLabel.bounds.size.width - 15.0, 10.0, _freeMemLabel.bounds.size.width, _freeMemLabel.bounds.size.height);
}

- (void)commonInit
{
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.clipsToBounds = YES;
    self.backgroundColor = [UIColor whiteColor];

    /*
    UIImageView *background = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"img_purchase_banner_portrait"]];
    background.frame = self.frame;
    background.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:background];
     */
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 10.0, 240.0, 20.0)];
    _titleLabel.textColor = [UIColor blackColor];
    _titleLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];;
    _titleLabel.numberOfLines = 1;
    _titleLabel.text = OALocalizedString(@"device_memory");
    [self addSubview:_titleLabel];
    
    _freeMemLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0, 10.0, 240.0, 20.0)];
    _freeMemLabel.textColor = [UIColor blackColor];
    _freeMemLabel.font = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];;
    _freeMemLabel.numberOfLines = 1;
    [self addSubview:_freeMemLabel];
    
    [self update];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memInfoDidChange:) name:@"DiskUsageChangedNotification" object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"DiskUsageChangedNotification" object:nil];
}

- (void)memInfoDidChange:(NSNotification*)notification
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        [self update];
        [self setNeedsDisplay];
    });
}

- (void)update
{
    NSError *error = nil;

    double deviceMemoryCapacity = 0.0;
    double deviceMemoryCapacityReal = 0.0;
    double deviceMemoryAvailable = 0.0;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSDictionary *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:[paths lastObject] error: &error];
    if (dictionary)
    {
        NSNumber *fileSystemSizeInBytes = [dictionary objectForKey: NSFileSystemSize];
        deviceMemoryCapacityReal = [fileSystemSizeInBytes doubleValue];
        deviceMemoryCapacity = floorf([fileSystemSizeInBytes doubleValue] / (1024.0 * 1024.0 * 1024.0));
        
        NSNumber *fileSystemFreeSizeInBytes = [dictionary objectForKey: NSFileSystemFreeSize];
        deviceMemoryAvailable = [fileSystemFreeSizeInBytes doubleValue] - 200 * 1024 * 1024;
        
    } else {
        NSLog(@"Error Obtaining File System Info: Domain = %@, Code = %ld", [error domain], (long)[error code]);
    }
    
    double docSize = [self docFolderSize];
    double tempFolderSize = [self folderSize:NSTemporaryDirectory()];
    double usedBySystem = deviceMemoryCapacityReal - (docSize + tempFolderSize + deviceMemoryAvailable);
    
    double capValue = deviceMemoryCapacityReal;
    double systemValue = usedBySystem;
    double availValue = deviceMemoryAvailable;
    double docValue = docSize;
    double tempValue = tempFolderSize;
    
    _sysVal = systemValue / capValue;
    _appVal = docValue / capValue;
    _tmpVal = tempValue / capValue;
    _freeVal = availValue / capValue;

    _freeMemLabel.text = [NSString stringWithFormat:OALocalizedString(@"free_memory"), [self getFormattedSize:deviceMemoryAvailable]];
}

- (NSString *) getFormattedSize:(double)size
{
    NSString *sizeStr;
    if (size >= 1024 * 1024 * 1024) {
        sizeStr = [NSString stringWithFormat:@"%02.2lf %@", size / (1024.0 * 1024.0 * 1024.0), OALocalizedString(@"GB")];
    } else if (size >= 1024 * 1024) {
        sizeStr = [NSString stringWithFormat:@"%.1lf %@", size / (1024.0 * 1024.0), OALocalizedString(@"MB")];
    } else if (size == 0) {
        sizeStr = [NSString stringWithFormat:@"0 %@", OALocalizedString(@"kB")];
    } else {
        sizeStr = [NSString stringWithFormat:@"%.0lf %@", size / 1024, OALocalizedString(@"kB")];
    }
    return sizeStr;
}

- (double)folderSize:(NSString *)folderPath {
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    double fileSize = 0;
    
    while (fileName = [filesEnumerator nextObject]) {
        NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileName] error:nil];
        fileSize += [fileDictionary fileSize];
    }
    
    return fileSize;
}

- (double)docFolderSize
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    NSString *docDir = [paths objectAtIndex:0];
    
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *filesArray = [manager subpathsOfDirectoryAtPath:docDir error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    double fileSize = 0;
    
    while (fileName = [filesEnumerator nextObject]) {
        NSDictionary *fileDictionary = [manager attributesOfItemAtPath:[docDir stringByAppendingPathComponent:fileName] error:nil];
        fileSize += [fileDictionary fileSize];
    }
    
    return fileSize;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGColorSpaceRef rgbColorspace = CGColorSpaceCreateDeviceRGB();
    
    float radius = 3.0f;
    CGRect frame = CGRectMake(15, 35, self.bounds.size.width - 30, 20);
    
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
    /*
    CGGradientRef glossGradientApp;
    CGGradientRef glossGradientTmp;
     */
    CGGradientRef glossGradientFree;
    
    size_t num_locations = 2;
    CGFloat locations[2] = { 0.0, 1.0 };
    
    float treshold = 3.0;
    
    float values[4] = { _sysVal, _appVal, _tmpVal, _freeVal };
    float total = 0;
    for (int i = 0; i < 4; i++)
    {
        values[i] *= frame.size.width;
        if (values[i] < treshold) values[i] = treshold;
        total += values[i];
    }
    
    int index = 0;
    while (total > frame.size.width)
    {
        if (values[index] > treshold + 0.1)
        {
            values[index] -= 0.1;
        }
        index++;
        if (index > 3) index = 0;
        total = values[0] + values[1] + values[2] + values[3];
    }
    
    
    CGFloat componentsSys[8] = { 255/255.0, 165/255.0, 89/255.0, 1.0,  // Start color
        255/255.0, 128/255.0, 0/255.0, 1.0 }; // End color
    glossGradientSys = CGGradientCreateWithColorComponents(rgbColorspace, componentsSys, locations, num_locations);
    
    /*
    CGFloat componentsApp[8] = { 147/255.0, 211/255.0, 247/255.0, 1.0,  // Start color
        14/255.0, 148/255.0, 186/255.0, 1.0 }; // End color
    glossGradientApp = CGGradientCreateWithColorComponents(rgbColorspace, componentsApp, locations, num_locations);
    
    CGFloat componentsTmp[8] = { 250/255.0, 196/255.0, 160/255.0, 1.0,  // Start color
        229/255.0, 73/255.0, 4/255.0, 1.0 }; // End color
    glossGradientTmp = CGGradientCreateWithColorComponents(rgbColorspace, componentsTmp, locations, num_locations);
    */
    
    CGFloat componentsFree[8] = { 30/255.0, 30/255.0, 30/255.0, 1.0,  // Start color
        120/255.0, 120/255.0, 120/255.0, 1.0 }; // End color
    glossGradientFree = CGGradientCreateWithColorComponents(rgbColorspace, componentsFree, locations, num_locations);
    
    CGContextSaveGState(context);
    
    CGContextBeginPath(context);
    CGContextSetGrayFillColor(context, 0.5, 0.7);
    CGContextMoveToPoint(context, CGRectGetMinX(frame) + radius, CGRectGetMinY(frame));
    CGContextAddLineToPoint(context, CGRectGetMinX(frame) + values[0] + values[1] + values[2], CGRectGetMinY(frame));
    CGContextAddLineToPoint(context, CGRectGetMinX(frame) + values[0] + values[1] + values[2], CGRectGetMaxY(frame));
    CGContextAddLineToPoint(context, CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame));
    CGContextAddArc(context, CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame) - radius, radius, M_PI / 2, M_PI, 0);
    CGContextAddArc(context, CGRectGetMinX(frame) + radius, CGRectGetMinY(frame) + radius, radius, M_PI, 3 * M_PI / 2, 0);
    
    CGContextClosePath(context);
    CGContextClip(context);
    
    CGPoint topCenter = CGPointMake(CGRectGetMidX(frame), 0.0f);
    CGPoint midCenter = CGPointMake(CGRectGetMidX(frame), CGRectGetMaxY(frame));
    CGContextDrawLinearGradient(context, glossGradientSys, topCenter, midCenter, 0);
    
    CGContextRestoreGState(context);
    
    /*
    CGContextSaveGState(context);
    
    CGContextAddRect(context, CGRectMake(CGRectGetMinX(frame) + values[0], CGRectGetMinY(frame), values[1], frame.size.height));
    CGContextClip(context);
    
    topCenter = CGPointMake(CGRectGetMidX(frame), 0.0f);
    midCenter = CGPointMake(CGRectGetMidX(frame), CGRectGetMaxY(frame));
    CGContextDrawLinearGradient(context, glossGradientApp, topCenter, midCenter, 0);
    
    CGContextRestoreGState(context);
    
    
    CGContextSaveGState(context);
    
    CGContextAddRect(context, CGRectMake(CGRectGetMinX(frame) + values[0] + values[1], CGRectGetMinY(frame), values[2], frame.size.height));
    CGContextClip(context);
    
    topCenter = CGPointMake(CGRectGetMidX(frame), 0.0f);
    midCenter = CGPointMake(CGRectGetMidX(frame), CGRectGetMaxY(frame));
    CGContextDrawLinearGradient(context, glossGradientTmp, topCenter, midCenter, 0);
    
    CGContextRestoreGState(context);
    */
    
    CGContextSaveGState(context);
    
    CGContextBeginPath(context);
    CGContextSetGrayFillColor(context, 0.5, 0.7);
    CGContextMoveToPoint(context, CGRectGetMaxX(frame) - values[3], CGRectGetMinY(frame));
    CGContextAddArc(context, CGRectGetMaxX(frame) - radius, CGRectGetMinY(frame) + radius, radius, 3 * M_PI / 2, 0, 0);
    CGContextAddArc(context, CGRectGetMaxX(frame) - radius, CGRectGetMaxY(frame) - radius, radius, 0, M_PI / 2, 0);
    CGContextAddLineToPoint(context, CGRectGetMaxX(frame) - values[3], CGRectGetMaxY(frame));
    
    CGContextClosePath(context);
    CGContextClip(context);
    
    topCenter = CGPointMake(CGRectGetMidX(frame), 0.0f);
    midCenter = CGPointMake(CGRectGetMidX(frame), CGRectGetMaxY(frame));
    CGContextDrawLinearGradient(context, glossGradientFree, topCenter, midCenter, 0);
    
    CGContextRestoreGState(context);
    
    /*
    CGColorRelease(fillColor);
    CGColorRelease(shadowColor);
     */
    
    CGGradientRelease(glossGradientSys);
    /*
    CGGradientRelease(glossGradientApp);
    CGGradientRelease(glossGradientTmp);
     */
    CGGradientRelease(glossGradientFree);
    
    CGColorSpaceRelease(rgbColorspace);
    
}

@end
