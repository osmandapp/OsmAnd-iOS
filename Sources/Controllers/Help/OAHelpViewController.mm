//
//  OAHelpViewController.mm
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAHelpViewController.h"
#import "OASimpleTableViewCell.h"
#import "Localization.h"
#import "OAWebViewController.h"
#import "OALinks.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAAppVersionDependentConstants.h"

static NSString * const kLinkInternalType = @"internal_link";
static NSString * const kLinkExternalType = @"ext_link";

@implementation OAHelpViewController
{
    OAMenuHelpDataService *_helpDataManager;
    OATableDataModel *_data;
    NSArray *_mostViewedArticles;
}

#pragma mark - Initialization

- (void)commonInit
{
    _helpDataManager  = [OAMenuHelpDataService shared];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self loadAndParseJson];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"shared_string_help");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    UIAction *sendLog = [UIAction actionWithTitle:OALocalizedString(@"send_log") image:[UIImage imageNamed:@"ic_custom_file_send_outlined"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [self sendLogFile];
    }];
    
    UIAction *copyBuildVersion = [UIAction actionWithTitle:OALocalizedString(@"copy_build_version") image:[UIImage imageNamed:@"ic_custom_clipboard"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
        [self copyBuildVersion];
    }];
    
    UIMenu *sendLogMenu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[sendLog]];
    
    UIMenu *copyBuildVersionMenu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[copyBuildVersion]];
    
    UIMenu *menu = [UIMenu menuWithTitle:@"" image:nil identifier:nil options:UIMenuOptionsDisplayInline children:@[sendLogMenu, copyBuildVersionMenu]];
    
    UIBarButtonItem *rightButton = [self createRightNavbarButton:nil iconName:@"ic_navbar_overflow_menu_stroke" action:@selector(onRightNavbarButtonPressed) menu:menu];
    
    rightButton.accessibilityLabel = OALocalizedString(@"shared_string_options");
    
    return @[rightButton];
}

#pragma mark - Table data

- (void)generateData
{
    _data = [[OATableDataModel alloc] init];
    
    OATableSectionData *popularArticlesSection = [_data createNewSection];
    popularArticlesSection.headerText = OALocalizedString(@"most_viewed");
    
    for (PopularArticle *article in _mostViewedArticles)
    {
        NSString *title = article.title;
        NSString *url = article.url;
        OATableRowData *articleRow = [popularArticlesSection createNewRow];
        [articleRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
        [articleRow setKey:@"popularArticles"];
        [articleRow setTitle:title];
        [articleRow setIconName:@"ic_custom_file_info"];
        [articleRow setObj:kLinkInternalType forKey:@"linkType"];
        [articleRow setObj:url forKey:@"url"];
    }
    
    OATableSectionData *userGuideSection = [_data createNewSection];
    userGuideSection.headerText = OALocalizedString(@"user_guide");
    NSArray *userGuideItems = @[
        @{@"title": OALocalizedString(@"shared_string_map"), @"url": kDocsMap},
        @{@"title": OALocalizedString(@"map_widgets"), @"url": kDocsWidgets},
        @{@"title": OALocalizedString(@"shared_string_navigation"), @"url": kDocsNavigation},
        @{@"title": OALocalizedString(@"search_activity"), @"url": kDocsSearch},
        @{@"title": OALocalizedString(@"my_data"), @"url": kDocsPersonal},
        @{@"title": OALocalizedString(@"plan_route"), @"url": kDocsPlanRoute},
        @{@"title": OALocalizedString(@"plugins_menu_group"), @"url": kDocsPlugins},
        @{@"title": OALocalizedString(@"purchases"), @"url": kDocsPurchases}
    ];
    for (NSDictionary *item in userGuideItems)
    {
        OATableRowData *row = [userGuideSection createNewRow];
        [row setCellType:[OASimpleTableViewCell getCellIdentifier]];
        [row setKey:@"userGuide"];
        [row setTitle:item[@"title"]];
        [row setIconName:@"ic_custom_book_info"];
        [row setObj:kLinkInternalType forKey:@"linkType"];
        [row setObj:item[@"url"] forKey:@"url"];
    }
    
    OATableSectionData *troubleshootingSection = [_data createNewSection];
    troubleshootingSection.headerText = OALocalizedString(@"troubleshooting");
    NSArray *troubleshootingItems = @[
        @{@"title": OALocalizedString(@"setup"), @"url": kTroubleshootingSetup, @"icon": @"ic_custom_device_download"},
        @{@"title": OALocalizedString(@"shared_string_map"), @"url": kTroubleshootingMap, @"icon": @"ic_custom_overlay_map"},
        @{@"title": OALocalizedString(@"shared_string_navigation"), @"url": kTroubleshootingNavigation, @"icon": @"ic_custom_navigation"},
        @{@"title": OALocalizedString(@"track_recording"), @"url": kTroubleshootingTrackRecording, @"icon": @"ic_custom_track_recordable"},
        @{@"title": OALocalizedString(@"plugins_menu_group"), @"url": kDocsPlugins, @"icon": @"ic_custom_extension"}
    ];
    for (NSDictionary *item in troubleshootingItems)
    {
        OATableRowData *row = [troubleshootingSection createNewRow];
        [row setCellType:[OASimpleTableViewCell getCellIdentifier]];
        [row setKey:@"troubleshooting"];
        [row setTitle:item[@"title"]];
        [row setIconName:item[@"icon"]];
        [row setObj:kLinkInternalType forKey:@"linkType"];
        [row setObj:item[@"url"] forKey:@"url"];
    }
    
    OATableSectionData *contactUsSection = [_data createNewSection];
    contactUsSection.headerText = OALocalizedString(@"help_contact_us");
    NSArray *initialContactUsItems = @[
        @{@"title": OALocalizedString(@"contact_support"), @"descr": kSupportEmail, @"icon": @"ic_custom_at_mail", @"url": kContactEmail},
        @{@"title": OALocalizedString(@"gitHub_discussion"), @"descr": OALocalizedString(@"ask_question_propose_features"), @"icon": @"ic_custom_logo_github", @"url": kGitHubDiscussion}
    ];
    for (NSDictionary *item in initialContactUsItems)
    {
        OATableRowData *row = [contactUsSection createNewRow];
        [row setCellType:[OASimpleTableViewCell getCellIdentifier]];
        [row setKey:@"contactSupport"];
        [row setTitle:item[@"title"]];
        [row setDescr:item[@"descr"]];
        [row setIconName:item[@"icon"]];
        [row setObj:kLinkExternalType forKey:@"linkType"];
        [row setObj:item[@"url"] forKey:@"url"];
    }
    
    OATableRowData *telegramChatsRow = [contactUsSection createNewRow];
    [telegramChatsRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [telegramChatsRow setKey:@"contactSupportTelegram"];
    [telegramChatsRow setTitle:OALocalizedString(@"telegram_chats")];
    [_helpDataManager getCountForCategoryFrom:kPopularArticlesAndTelegramChats for:HelperDataItemsTelegramChats completion:^(NSInteger count) {
        [telegramChatsRow setDescr:[NSString stringWithFormat:@"%ld", (long)count]];
    }];
    [telegramChatsRow setIconName:@"ic_custom_logo_telegram"];
    
    NSArray *additionalContactUsItems = @[
        @{@"title": OALocalizedString(@"twitter"), @"descr": kCommunityTwitter, @"icon": @"ic_custom_logo_twitter", @"url": kCommunityTwitter},
        @{@"title": OALocalizedString(@"reddit"), @"descr": kCommunityReddit, @"icon": @"ic_custom_logo_reddit", @"url": kCommunityReddit},
        @{@"title": OALocalizedString(@"facebook"), @"descr": kCommunityFacebook, @"icon": @"ic_custom_logo_facebook", @"url": kCommunityFacebook}
    ];
    for (NSDictionary *item in additionalContactUsItems)
    {
        OATableRowData *row = [contactUsSection createNewRow];
        [row setCellType:[OASimpleTableViewCell getCellIdentifier]];
        [row setKey:@"contactSupport"];
        [row setTitle:item[@"title"]];
        [row setDescr:item[@"descr"]];
        [row setIconName:item[@"icon"]];
        [row setObj:kLinkExternalType forKey:@"linkType"];
        [row setObj:item[@"url"] forKey:@"url"];
    }
    
    OATableSectionData *reportAnIssuesSection = [_data createNewSection];
    reportAnIssuesSection.headerText = OALocalizedString(@"report_an_issues");
    
    OATableRowData *openIssueOnGitHubRow = [reportAnIssuesSection createNewRow];
    [openIssueOnGitHubRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [openIssueOnGitHubRow setKey:@"reportAnIssues"];
    [openIssueOnGitHubRow setTitle:OALocalizedString(@"open_issue_on_gitHub")];
    [openIssueOnGitHubRow setDescr:OALocalizedString(@"ask_question_propose_features")];
    [openIssueOnGitHubRow setIconName:@"ic_custom_logo_github"];
    [openIssueOnGitHubRow setObj:kLinkExternalType forKey:@"linkType"];
    [openIssueOnGitHubRow setObj:kOpenIssueOnGitHub forKey:@"url"];
    
    OATableRowData *sendLogRow = [reportAnIssuesSection createNewRow];
    [sendLogRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [sendLogRow setKey:@"sendLog"];
    [sendLogRow setTitle:OALocalizedString(@"send_log")];
    [sendLogRow setDescr:OALocalizedString(@"detailed_log_file")];
    [sendLogRow setIconName:@"ic_custom_file_send_outlined"];
    
    OATableSectionData *aboutOsmAndSection = [_data createNewSection];
    aboutOsmAndSection.headerText = OALocalizedString(@"about_osmAnd");
    NSArray *aboutOsmAndItems = @[
        @{@"title": OALocalizedString(@"osmAnd_team"), @"descr": @"", @"icon": @"ic_custom_logo_osmand", @"url": kOsmAndTeam},
        @{@"title": OALocalizedString(@"help_what_is_new"), @"descr": [NSString stringWithFormat:@"%@ %@", OALocalizedString(@"OsmAnd Maps"), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]], @"icon": @"ic_custom_clipboard", @"url": kDocsLatestVersion},
        @{@"title": OALocalizedString(@"testFlight"), @"descr": OALocalizedString(@"download_install_beta_version"), @"icon": @"ic_custom_download", @"url": kTestFlight}
    ];
    for (NSDictionary *item in aboutOsmAndItems)
    {
        OATableRowData *row = [aboutOsmAndSection createNewRow];
        [row setCellType:[OASimpleTableViewCell getCellIdentifier]];
        [row setKey:@"aboutOsmAnd"];
        [row setTitle:item[@"title"]];
        [row setDescr:item[@"descr"]];
        [row setIconName:item[@"icon"]];
        [row setObj:kLinkInternalType forKey:@"linkType"];
        [row setObj:item[@"url"] forKey:@"url"];
    }
}

- (void)loadAndParseJson
{
    [_helpDataManager loadAndParseJsonFrom:kPopularArticlesAndTelegramChats for:HelperDataItemsPopularArticles completion:^(NSArray *articles, NSError *error) {
        if (error) {
            NSLog(OALocalizedString(@"osm_failed_uploads"));
        } else if (articles) {
            _mostViewedArticles = articles;
            [self generateData];
            [self.tableView reloadData];
        }
    }];
}

- (NSInteger)sectionsCount
{
    return _data.sectionCount;;
}

- (NSString *)getTitleForHeader:(NSInteger)section;
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    
    NSString *description = item.descr;
    NSString *key = item.key;
    BOOL isCellAccessoryNone = [key isEqualToString:@"contactSupport"] || [key isEqualToString:@"reportAnIssues"] || [key isEqualToString:@"sendLog"] || [key isEqualToString:@"aboutOsmAnd"];
    
    OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OASimpleTableViewCell *) nib[0];
    }
    if (cell)
    {
        [cell descriptionVisibility:description && description.length > 0];
        cell.titleLabel.text = item.title;
        cell.descriptionLabel.text = description;
        
        if ([item.title isEqualToString:OALocalizedString(@"osmAnd_team")])
        {
            cell.leftIconView.image = [[UIImage imageNamed:item.iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        }
        else
        {
            cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
            cell.leftIconView.tintColor = UIColor.iconColorDefault;
        }
        
        cell.accessoryType = isCellAccessoryNone ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator;
    }
    return cell;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    NSString *key = item.key;
    NSString *linkType = [item objForKey:@"linkType"];
    NSString *url = [item objForKey:@"url"];
    
    if ([linkType isEqualToString:kLinkInternalType])
    {
        OAWebViewController *webView = [[OAWebViewController alloc] initWithUrlAndTitle:url title:item.title];
        [self.navigationController pushViewController:webView animated:YES];
    }
    else if ([linkType isEqualToString:kLinkExternalType])
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
    }
    
    if ([key isEqualToString:@"contactSupportTelegram"])
    {
        OAHelpDetailsViewController *vc = [[OAHelpDetailsViewController alloc] init];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if ([key isEqualToString:@"sendLog"])
    {
        [self sendLogFile];
    }
}

- (UIContextMenuConfiguration *)tableView:(UITableView *)tableView contextMenuConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    
    if ([item.title isEqualToString:OALocalizedString(@"help_what_is_new")])
    {
        UIAction *copyBuildVersion = [UIAction actionWithTitle:OALocalizedString(@"copy_build_version") image:[UIImage imageNamed:@"ic_custom_clipboard"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [self copyBuildVersion];
        }];
        
        copyBuildVersion.accessibilityLabel = OALocalizedString(@"copy_build_version");
        
        UIMenu *contextMenu = [UIMenu menuWithTitle:@"" children:@[copyBuildVersion]];
        
        return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
            return contextMenu;
        }];
    }
    
    return nil;
}

#pragma mark - Aditions

- (void)copyBuildVersion
{
    [UIPasteboard generalPasteboard].string = [OAAppVersionDependentConstants getVersion];
}

- (void)sendLogFile
{
    NSString *logsPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"Logs"];
    NSFileManager *manager = [NSFileManager defaultManager];
    
    NSArray<NSString *> *files = [manager contentsOfDirectoryAtPath:logsPath error:nil];
    files = [files sortedArrayUsingComparator:^NSComparisonResult(NSString *file1, NSString *file2) {
        NSString *path1 = [logsPath stringByAppendingPathComponent:file1];
        NSString *path2 = [logsPath stringByAppendingPathComponent:file2];
        NSDictionary *attr1 = [manager attributesOfItemAtPath:path1 error:nil];
        NSDictionary *attr2 = [manager attributesOfItemAtPath:path2 error:nil];
        return [attr2[NSFileCreationDate] compare:attr1[NSFileCreationDate]];
    }];
    
    if (files.count > 0)
    {
        NSString *latestLogFile = [logsPath stringByAppendingPathComponent:[files firstObject]];
        NSURL *logFileURL = [NSURL fileURLWithPath:latestLogFile];
        
        UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[logFileURL] applicationActivities:nil];
        [self presentViewController:activityViewController animated:YES completion:nil];
    }
}

@end
