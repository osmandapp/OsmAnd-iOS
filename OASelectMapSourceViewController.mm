//
//  OASelectMapSourceViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 26.05.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASelectMapSourceViewController.h"
#import "OAMapSource.h"
#import "OsmAndApp.h"
#import "OABottomSheetActionCell.h"
#import "OATableViewCustomHeaderView.h"

#include "Localization.h"
#include "OASizes.h"
#include <QSet>

#include <OsmAndCore/Map/IOnlineTileSources.h>
#include <OsmAndCore/Map/OnlineTileSources.h>

#define kHeaderId @"TableViewSectionHeader"

@interface OASelectMapSourceViewController() <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;



@end

@implementation OASelectMapSourceViewController
{
    OsmAndAppInstance _app;
    
    QList<std::shared_ptr<const OsmAnd::OnlineTileSources::Source>> _onlineMapSources;
}

-(void) applyLocalization
{
    [super applyLocalization];
    self.titleView.text = OALocalizedString(@"select_online_source");
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _app = [OsmAndApp instance];
    [self.tableView setDataSource:self];
    [self.tableView setDelegate:self];
    self.tableView.separatorInset = UIEdgeInsetsMake(0., 16.0, 0., 0.);
    self.tableView.contentInset = UIEdgeInsetsMake(10., 0., 0., 0.);
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:kHeaderId];
    [self setupView];
}

- (void) viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (UIView *) getTopView
{
    return _navBarView;
}

- (UIView *) getMiddleView
{
    return _tableView;
}

- (CGFloat) getNavBarHeight
{
    return defaultNavBarHeight;
}

- (void) adjustViews
{
    CGRect buttonFrame = _cancelButton.frame;
    CGRect titleFrame = _titleView.frame;
    CGFloat statusBarHeight = [OAUtilities getStatusBarHeight];
    buttonFrame.origin.y = statusBarHeight;
    titleFrame.origin.y = statusBarHeight;
    _cancelButton.frame = buttonFrame;
    _titleView.frame = titleFrame;
}

- (void) setupView
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        const auto& onlineSourcesCollection = _app.resourcesManager->downloadOnlineTileSources();
        if (onlineSourcesCollection != nullptr)
        {
            _onlineMapSources = _app.resourcesManager->downloadOnlineTileSources()->getCollection().values();
            std::sort(_onlineMapSources, [](
                                            const std::shared_ptr<const OsmAnd::OnlineTileSources::Source> s1,
                                            const std::shared_ptr<const OsmAnd::OnlineTileSources::Source> s2)
                                            {
                                                return s1->priority < s2->priority;
                                            });
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                self.tableView.allowsMultipleSelectionDuringEditing = NO;
                [self.tableView reloadData];
            });
        }
        else
        {
            NSLog(@"Failed to download online tile resources list.");
        }
    });
}

- (IBAction)onCancelButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = OALocalizedString(@"online_sources");
    return [OATableViewCustomHeaderView getHeight:title width:tableView.bounds.size.width];
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    NSString *title = OALocalizedString(@"online_sources");
    OATableViewCustomHeaderView *vw = [tableView dequeueReusableHeaderFooterViewWithIdentifier:kHeaderId];
    if (!title)
    {
        vw.label.text = title;
        return vw;
    }
    vw.label.text = [title upperCase];
    return vw;
}


- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _onlineMapSources.count();
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    const auto& item = _onlineMapSources[(int) indexPath.row];
    NSString* caption = item->name.toNSString();
    
    static NSString* const identifierCell = @"OABottomSheetActionCell";
    OABottomSheetActionCell* cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
        cell = (OABottomSheetActionCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        UIImage *img = nil;
        img = [UIImage imageNamed:@"ic_custom_map_online"];
        
        cell.textView.text = caption;
        cell.descView.hidden = YES;
        cell.iconView.image = img;
        cell.separatorInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
    }
    return cell;
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}


@end

