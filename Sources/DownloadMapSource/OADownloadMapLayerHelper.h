#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class OAMapSource, OAResourceItem;

typedef NS_ENUM(NSInteger, EOADownloadMapLayer)
{
    EOADownloadMapLayerMapSource,
    EOADownloadMapLayerOverlay,
    EOADownloadMapLayerUnderlay
};

@interface OADownloadMapLayerHelper : NSObject

+ (NSArray<NSNumber *> *)downloadableLayers;
+ (nullable OAMapSource *)mapSourceForLayer:(EOADownloadMapLayer)layer;
+ (void)setMapSource:(OAMapSource *)source forLayer:(EOADownloadMapLayer)layer;
+ (nullable OAResourceItem *)resourceItemForLayer:(EOADownloadMapLayer)layer;
+ (NSString *)titleForLayer:(EOADownloadMapLayer)layer;
+ (NSString *)iconNameForLayer:(EOADownloadMapLayer)layer;

@end

NS_ASSUME_NONNULL_END
