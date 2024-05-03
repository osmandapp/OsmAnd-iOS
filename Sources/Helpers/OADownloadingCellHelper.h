//
//  OADownloadingCellHelper.h
//  OsmAnd
//
//  Created by nnngrach on 31.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAAutoObserverProxy.h"
#import "OAResourcesUISwiftHelper.h"

@class OAResourceItem, OAMultipleResourceItem, OATableDataModel, OARightIconTableViewCell;

typedef void(^ OAFetchResourcesBlock)();
typedef OAResourceItem *(^ OAGetResourceByIndexBlock)(NSIndexPath *);
typedef OAResourceSwiftItem *(^ OAGetSwiftResourceByIndexBlock)(NSIndexPath *);
typedef NSArray<NSArray <NSDictionary *> *> *(^ OAGetTableDataBlock)();
typedef OATableDataModel *(^ OAGetTableModelBlock)();


@interface OADownloadingCellHelper : NSObject

@property (nonatomic, copy) OAFetchResourcesBlock fetchResourcesBlock;
@property (nonatomic, copy) OAGetSwiftResourceByIndexBlock getSwiftResourceByIndexBlock;
@property (nonatomic, copy) OAGetResourceByIndexBlock getResourceByIndexBlock;
@property (nonatomic, copy) OAGetTableModelBlock getTableDataModelBlock; 
@property (nonatomic, copy) OAGetTableDataBlock getTableDataBlock;

@property (weak, nonatomic) UITableView *hostTableView;
@property (weak, nonatomic) UIViewController *hostViewController;
@property (weak, nonatomic) NSObject *hostDataLock;

- (OARightIconTableViewCell *)setupSwiftCell:(OAResourceSwiftItem *)swiftMapItem indexPath:(NSIndexPath *)indexPath;
- (OARightIconTableViewCell *)setupCell:(OAResourceItem *)mapItem indexPath:(NSIndexPath *)indexPath;
- (void)onItemClicked:(NSIndexPath *)indexPath;
- (void)updateAvailableMaps;

@end
