#import "OAQuickSearchListItem.h"
#import "OAResourcesUIHelper.h"

@interface OAQuickSearchResourceItem : OAQuickSearchListItem

@property (nonatomic) NSString *title;
@property (nonatomic) NSString *message;
@property (nonatomic) OAResourceItem *resourceItem;

- (instancetype)initWithResourceItem:(OAResourceItem *)resourceItem;

@end
