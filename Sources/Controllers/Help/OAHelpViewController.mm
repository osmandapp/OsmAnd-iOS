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

static NSString * const kLinkInternalType = @"internal_link";
static NSString * const kLinkExternalType = @"ext_link";

@implementation OAHelpViewController
{
    OAHelpDataManager *_helpDataManager;
    OATableDataModel *_data;
    NSArray *_mostViewedArticles;
}

#pragma mark - Initialization

- (void)commonInit
{
    _helpDataManager  = [OAHelpDataManager sharedInstance];
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
    
    OATableSectionData * userGuideSection = [_data createNewSection];
    userGuideSection.headerText = OALocalizedString(@"user_guide");
    
    OATableRowData *mapRow = [userGuideSection createNewRow];
    [mapRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [mapRow setKey:@"userGuide"];
    [mapRow setTitle:OALocalizedString(@"shared_string_map")];
    [mapRow setIconName:@"ic_custom_book_info"];
    [mapRow setObj:kLinkInternalType forKey:@"linkType"];
    [mapRow setObj:kDocsMap forKey:@"url"];
    
    OATableRowData *mapWidgetsRow = [userGuideSection createNewRow];
    [mapWidgetsRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [mapWidgetsRow setKey:@"userGuide"];
    [mapWidgetsRow setTitle:OALocalizedString(@"map_widgets")];
    [mapWidgetsRow setIconName:@"ic_custom_book_info"];
    [mapWidgetsRow setObj:kLinkInternalType forKey:@"linkType"];
    [mapWidgetsRow setObj:kDocsWidgets forKey:@"url"];
    
    OATableRowData *navigationsRow = [userGuideSection createNewRow];
    [navigationsRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [navigationsRow setKey:@"userGuide"];
    [navigationsRow setTitle:OALocalizedString(@"shared_string_navigation")];
    [navigationsRow setIconName:@"ic_custom_book_info"];
    [navigationsRow setObj:kLinkInternalType forKey:@"linkType"];
    [navigationsRow setObj:kDocsNavigation forKey:@"url"];
    
    OATableRowData *searchRow = [userGuideSection createNewRow];
    [searchRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [searchRow setKey:@"userGuide"];
    [searchRow setTitle:OALocalizedString(@"search_activity")];
    [searchRow setIconName:@"ic_custom_book_info"];
    [searchRow setObj:kLinkInternalType forKey:@"linkType"];
    [searchRow setObj:kDocsSearch forKey:@"url"];
    
    OATableRowData *myDataRow = [userGuideSection createNewRow];
    [myDataRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [myDataRow setKey:@"userGuide"];
    [myDataRow setTitle:OALocalizedString(@"my_data")];
    [myDataRow setIconName:@"ic_custom_book_info"];
    [myDataRow setObj:kLinkInternalType forKey:@"linkType"];
    [myDataRow setObj:kDocsPersonal forKey:@"url"];
    
    OATableRowData *planRouteRow = [userGuideSection createNewRow];
    [planRouteRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [planRouteRow setKey:@"userGuide"];
    [planRouteRow setTitle:OALocalizedString(@"plan_route")];
    [planRouteRow setIconName:@"ic_custom_book_info"];
    [planRouteRow setObj:kLinkInternalType forKey:@"linkType"];
    [planRouteRow setObj:kDocsPlanRoute forKey:@"url"];
    
    OATableRowData *pluginsRow = [userGuideSection createNewRow];
    [pluginsRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [pluginsRow setKey:@"userGuide"];
    [pluginsRow setTitle:OALocalizedString(@"plugins_menu_group")];
    [pluginsRow setIconName:@"ic_custom_book_info"];
    [pluginsRow setObj:kLinkInternalType forKey:@"linkType"];
    [pluginsRow setObj:kDocsPlugins forKey:@"url"];
    
    OATableRowData *purchasesRow = [userGuideSection createNewRow];
    [purchasesRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [purchasesRow setKey:@"userGuide"];
    [purchasesRow setTitle:OALocalizedString(@"purchases")];
    [purchasesRow setIconName:@"ic_custom_book_info"];
    [purchasesRow setObj:kLinkInternalType forKey:@"linkType"];
    [purchasesRow setObj:kDocsPurchases forKey:@"url"];
    
    OATableSectionData *  troubleshootingSection = [_data createNewSection];
    troubleshootingSection.headerText = OALocalizedString(@"troubleshooting");
    
    OATableRowData *setupRow = [troubleshootingSection createNewRow];
    [setupRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [setupRow setKey:@"troubleshooting"];
    [setupRow setTitle:OALocalizedString(@"setup")];
    [setupRow setIconName:@"ic_custom_device_download"];
    [setupRow setObj:kLinkInternalType forKey:@"linkType"];
    [setupRow setObj:kTroubleshootingSetup forKey:@"url"];
    
    OATableRowData *mapTroubleshootingRow = [troubleshootingSection createNewRow];
    [mapTroubleshootingRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [mapTroubleshootingRow setKey:@"troubleshooting"];
    [mapTroubleshootingRow setTitle:OALocalizedString(@"shared_string_map")];
    [mapTroubleshootingRow setIconName:@"ic_custom_overlay_map"];
    [mapTroubleshootingRow setObj:kLinkInternalType forKey:@"linkType"];
    [mapTroubleshootingRow setObj:kTroubleshootingMap forKey:@"url"];
    
    OATableRowData *navigationRow = [troubleshootingSection createNewRow];
    [navigationRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [navigationRow setKey:@"troubleshooting"];
    [navigationRow setTitle:OALocalizedString(@"shared_string_navigation")];
    [navigationRow setIconName:@"ic_custom_navigation"];
    [navigationRow setObj:kLinkInternalType forKey:@"linkType"];
    [navigationRow setObj:kTroubleshootingNavigation forKey:@"url"];
    
    OATableRowData *trackRecordingRow = [troubleshootingSection createNewRow];
    [trackRecordingRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [trackRecordingRow setKey:@"troubleshooting"];
    [trackRecordingRow setTitle:OALocalizedString(@"track_recording")];
    [trackRecordingRow setIconName:@"ic_custom_track_recordable"];
    [trackRecordingRow setObj:kLinkInternalType forKey:@"linkType"];
    [trackRecordingRow setObj:kTroubleshootingTrackRecording forKey:@"url"];
    
    OATableRowData *pluginsTroubleshootingRow = [troubleshootingSection createNewRow];
    [pluginsTroubleshootingRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [pluginsTroubleshootingRow setKey:@"troubleshooting"];
    [pluginsTroubleshootingRow setTitle:OALocalizedString(@"plugins_menu_group")];
    [pluginsTroubleshootingRow setIconName:@"ic_custom_extension"];
    [pluginsTroubleshootingRow setObj:kLinkInternalType forKey:@"linkType"];
    [pluginsTroubleshootingRow setObj:kDocsPlugins forKey:@"url"];
    
    OATableSectionData *  contactUsSection = [_data createNewSection];
    contactUsSection.headerText = OALocalizedString(@"help_contact_us");
    
    OATableRowData *contactSupportRow = [contactUsSection createNewRow];
    [contactSupportRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [contactSupportRow setKey:@"contactSupport"];
    [contactSupportRow setTitle:OALocalizedString(@"contact_support")];
    [contactSupportRow setDescr:kSupportEmail];
    [contactSupportRow setIconName:@"ic_custom_at_mail"];
    [contactSupportRow setObj:kLinkExternalType forKey:@"linkType"];
    [contactSupportRow setObj:kContactEmail forKey:@"url"];
    
    OATableRowData *gitHubDiscussionRow = [contactUsSection createNewRow];
    [gitHubDiscussionRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [gitHubDiscussionRow setKey:@"contactSupport"];
    [gitHubDiscussionRow setTitle:OALocalizedString(@"gitHub_discussion")];
    [gitHubDiscussionRow setDescr:OALocalizedString(@"ask_question_propose_features")];
    [gitHubDiscussionRow setIconName:@"ic_custom_logo_github"];
    [gitHubDiscussionRow setObj:kLinkExternalType forKey:@"linkType"];
    [gitHubDiscussionRow setObj:kGitHubDiscussion forKey:@"url"];
    
    OATableRowData *telegramChatsRow = [contactUsSection createNewRow];
    [telegramChatsRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [telegramChatsRow setKey:@"contactSupportTelegram"];
    [telegramChatsRow setTitle:OALocalizedString(@"telegram_chats")];
    [telegramChatsRow setDescr:[_helpDataManager getTelegramChatsCount]];
    [telegramChatsRow setIconName:@"ic_custom_logo_telegram"];
    
    OATableRowData *twitterRow = [contactUsSection createNewRow];
    [twitterRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [twitterRow setKey:@"contactSupport"];
    [twitterRow setTitle:OALocalizedString(@"twitter")];
    [twitterRow setDescr:kCommunityTwitter];
    [twitterRow setIconName:@"ic_custom_logo_twitter"];
    [twitterRow setObj:kLinkExternalType forKey:@"linkType"];
    [twitterRow setObj:kCommunityTwitter forKey:@"url"];
    
    OATableRowData *redditRow = [contactUsSection createNewRow];
    [redditRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [redditRow setKey:@"contactSupport"];
    [redditRow setTitle:OALocalizedString(@"reddit")];
    [redditRow setDescr:kCommunityReddit];
    [redditRow setIconName:@"ic_custom_logo_reddit"];
    [redditRow setObj:kLinkExternalType forKey:@"linkType"];
    [redditRow setObj:kCommunityReddit forKey:@"url"];
    
    OATableRowData *facebookRow = [contactUsSection createNewRow];
    [facebookRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [facebookRow setKey:@"contactSupport"];
    [facebookRow setTitle:OALocalizedString(@"facebook")];
    [facebookRow setDescr:kCommunityFacebook];
    [facebookRow setIconName:@"ic_custom_logo_facebook"];
    [facebookRow setObj:kLinkExternalType forKey:@"linkType"];
    [facebookRow setObj:kCommunityFacebook forKey:@"url"];
    
    OATableSectionData *  reportAnIssuesSection = [_data createNewSection];
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
    
    OATableSectionData *  aboutOsmAndSection = [_data createNewSection];
    aboutOsmAndSection.headerText = OALocalizedString(@"about_osmAnd");
    
    OATableRowData *osmAndTeamRow = [aboutOsmAndSection createNewRow];
    [osmAndTeamRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [osmAndTeamRow setKey:@"aboutOsmAnd"];
    [osmAndTeamRow setTitle:OALocalizedString(@"osmAnd_team")];
    [osmAndTeamRow setIconName:@"ic_custom_logo_osmand"];
    [osmAndTeamRow setObj:kLinkInternalType forKey:@"linkType"];
    [osmAndTeamRow setObj:kOsmAndTeam forKey:@"url"];
    
    OATableRowData *whatsNewRow = [aboutOsmAndSection createNewRow];
    [whatsNewRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [whatsNewRow setKey:@"aboutOsmAnd"];
    [whatsNewRow setTitle:OALocalizedString(@"help_what_is_new")];
    [whatsNewRow setDescr:[NSString stringWithFormat:@"%@ %@", OALocalizedString(@"OsmAnd Maps"), [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];
    [whatsNewRow setIconName:@"ic_custom_clipboard"];
    [whatsNewRow setObj:kLinkInternalType forKey:@"linkType"];
    [whatsNewRow setObj:kDocsLatestVersion forKey:@"url"];
    
    OATableRowData *testFlightRow = [aboutOsmAndSection createNewRow];
    [testFlightRow setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [testFlightRow setKey:@"aboutOsmAnd"];
    [testFlightRow setTitle:OALocalizedString(@"testFlight")];
    [testFlightRow setDescr:OALocalizedString(@"download_install_beta_version")];
    [testFlightRow setIconName:@"ic_custom_download"];
    [testFlightRow setObj:kLinkInternalType forKey:@"linkType"];
    [testFlightRow setObj:kTestFlight forKey:@"url"];
}

- (void)loadAndParseJson
{
    [_helpDataManager loadAndParseJsonFrom:kPopularArticlesAndTelegramChats completion:^(BOOL success) {
        if (success)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                _mostViewedArticles = [_helpDataManager getPopularArticles];
                [self generateData];
                [self.tableView reloadData];
            });
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(OALocalizedString(@"osm_failed_uploads"));
            });
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
            cell.leftIconView.image =  [UIImage templateImageNamed:item.iconName];
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
    [UIPasteboard generalPasteboard].string = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
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
