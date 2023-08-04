//
//  OADownloadingCellHelper.h
//  OsmAnd
//
//  Created by nnngrach on 31.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAAutoObserverProxy.h"

@class OAResourceItem, OAMultipleResourceItem, OATableDataModel;

typedef void(^ OAFetchResourcesBlock)();
typedef OAResourceItem *(^ OAGetResourceByIndexBlock)(NSIndexPath *);
typedef NSArray<NSArray <NSDictionary *> *> *(^ OAGetTableDataBlock)();
typedef OATableDataModel *(^ OAGetTableModelBlock)();


@interface OADownloadingCellHelper : NSObject

@property (nonatomic, copy) OAFetchResourcesBlock fetchResourcesBlock;
@property (nonatomic, copy) OAGetResourceByIndexBlock getResourceByIndexBlock;
@property (nonatomic, copy) OAGetTableModelBlock getTableDataModelBlock; 
@property (nonatomic, copy) OAGetTableDataBlock getTableDataBlock;

@property (weak, nonatomic) UITableView *hostTableView;
@property (weak, nonatomic) UIViewController *hostViewController;
@property (weak, nonatomic) NSObject *hostDataLock;

- (UITableViewCell *)setupCell:(OAResourceItem *)mapItem indexPath:(NSIndexPath *)indexPath;

- (void)onItemClicked:(NSIndexPath *)indexPath;

- (void)updateAvailableMaps;

@end
