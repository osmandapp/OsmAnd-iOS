#import "OAQuickSearchResourceItem.h"
#import "OAResourcesUIHelper.h"
#import "OAResourcesUISwiftHelper.h"

@implementation OAQuickSearchResourceItem

- (instancetype)initWithResourceItem:(OAResourceItem *)resourceItem {
    self = [super init];
    if (self) {
        _resourceItem = resourceItem;
        _title = resourceItem.title;
        NSString *typeStr = [OAResourceType resourceTypeLocalized:resourceItem.resourceType];
        NSString *sizeStr = [OAResourcesUISwiftHelper formatSize:resourceItem.sizePkg addZero:NO];
        NSString *dateStr = [resourceItem getDate];
        _message = [NSString stringWithFormat: @"%@  •  %@ •  %@",  sizeStr, typeStr, dateStr];

    }
    return self;
}


- (EOAQuickSearchListItemType) getType
{
    return RESOURCE_ITEM;
}

- (NSString *)getName
{
    return  _resourceItem.title;
}
@end
