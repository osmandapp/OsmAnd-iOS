//
//  OADeleteAllVersionsBackupViewController.mm
//  OsmAnd
//
//  Created by Skalii on 22.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OADeleteAllVersionsBackupViewController.h"
#import "OASettingsBackupViewController.h"
#import "OATextLineViewCell.h"
#import "OADownloadProgressBarCell.h"
#import "OAFilledButtonCell.h"
#import "OAColors.h"
#import "Localization.h"
#import "OABackupHelper.h"

@interface OADeleteAllVersionsBackupViewController () <UITableViewDelegate, UITableViewDataSource, OADeleteAllVersionsBackupDelegate, OAOnDeleteFilesListener>

@property (weak, nonatomic) IBOutlet UIView *buttonsContainerView;
@property (weak, nonatomic) IBOutlet UIButton *topButton;
@property (weak, nonatomic) IBOutlet UIButton *bottomButton;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomButtonWithTopButtonConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomButtonNoTopButtonConstraint;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonsContainerWithOneButtonConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *buttonsContainerWithTwoButtonsConstraint;

@end

@implementation OADeleteAllVersionsBackupViewController
{
    EOADeleteBackupScreenType _screenType;
    NSMutableArray<NSMutableDictionary *> *_data;
    NSIndexPath *_progressIndexPath;
    NSString *_description;
    NSString *_sectionDescription;

    NSInteger _progressFilesCompleteCount;
    NSInteger _progressFilesTotalCount;
    BOOL _isDeleted;
}

- (instancetype)initWithScreenType:(EOADeleteBackupScreenType)screenType
{
    self = [super initWithNibName:@"OADeleteAllVersionsBackupViewController" bundle:nil];
    if (self)
    {
        _screenType = screenType;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _progressFilesCompleteCount = 0;
    _progressFilesTotalCount = 1;

    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    [self setupButtons];
    [self setupView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self deleteBackupFiles];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (@available(iOS 13.0, *))
        return UIStatusBarStyleDarkContent;

    return UIStatusBarStyleDefault;
}

- (void)applyLocalization
{
    [super applyLocalization];
    _sectionDescription = @"";
    NSString *title = @"";
    NSString *titleBottomButton = @"";
    switch (_screenType)
    {
        case EOADeleteAllDataBackupScreenType:
        {
            title = OALocalizedString(@"backup_delete_all_data");
            titleBottomButton = OALocalizedString(@"shared_string_cancel");
            _description = OALocalizedString(@"backup_delete_all_data_warning");
            [self.topButton setTitle:OALocalizedString(@"backup_delete_all_data") forState:UIControlStateNormal];
            break;
        }
        case EOADeleteAllDataConfirmBackupScreenType:
        {
            title = OALocalizedString(@"are_you_sure");
            _description = OALocalizedString(@"backup_delete_all_data_warning");
            break;
        }
        case EOADeleteAllDataProgressBackupScreenType:
        {
            title = OALocalizedString(@"backup_deleting_all_data");
            titleBottomButton = OALocalizedString(@"shared_string_close");
            _description = OALocalizedString(@"shared_string_progress");
            _sectionDescription = OALocalizedString(@"backup_delete_all_data_in_progress");
            break;
        }
        case EOARemoveOldVersionsBackupScreenType:
        {
            title = OALocalizedString(@"backup_delete_old_data");
            titleBottomButton = OALocalizedString(@"shared_string_remove");
            _description = OALocalizedString(@"backup_delete_old_data_warning");
            break;
        }
        case EOARemoveOldVersionsProgressBackupScreenType:
        {
            title = OALocalizedString(@"backup_delete_old_data");
            titleBottomButton = OALocalizedString(@"shared_string_close");
            _description = OALocalizedString(@"shared_string_progress");
            break;
        }
    }
    self.titleLabel.text = title;
    [self.bottomButton setTitle:titleBottomButton forState:UIControlStateNormal];
}

- (NSString *)getTableHeaderTitle
{
    return self.titleLabel.text;
}

- (UIColor *)navBarBackgroundColor
{
    return UIColorFromRGB(color_bottom_sheet_background);
}

- (void)setupButtons
{
    BOOL isRemoveOld = _screenType == EOARemoveOldVersionsBackupScreenType;
    BOOL isConfirm = _screenType == EOADeleteAllDataConfirmBackupScreenType;
    BOOL isProgress = _screenType == EOADeleteAllDataProgressBackupScreenType
            || _screenType == EOARemoveOldVersionsProgressBackupScreenType;
    BOOL hasTwoButtons = _screenType == EOADeleteAllDataBackupScreenType;

    self.bottomButton.tintColor = isRemoveOld ? UIColorFromRGB(color_support_red) : UIColorFromRGB(color_primary_purple);
    [self.bottomButton setTitleColor:isRemoveOld ? UIColorFromRGB(color_support_red) : UIColorFromRGB(color_primary_purple)
                            forState:UIControlStateNormal];

    self.backButton.hidden = !(isConfirm || isRemoveOld);
    self.backImageButton.hidden = isConfirm || isRemoveOld;
    [self.backImageButton setImage:[UIImage templateImageNamed:isProgress ? @"ic_navbar_close" : @"ic_navbar_chevron"]
                          forState:UIControlStateNormal];

    self.topButton.hidden = isConfirm || isRemoveOld || isProgress;
    self.bottomButton.hidden = isConfirm || isProgress;
    self.buttonsContainerView.hidden = isConfirm || isProgress;

    self.bottomButtonWithTopButtonConstraint.active = hasTwoButtons;
    self.bottomButtonNoTopButtonConstraint.active = !hasTwoButtons;
    self.buttonsContainerWithOneButtonConstraint.active = !hasTwoButtons;
    self.buttonsContainerWithTwoButtonsConstraint.active = hasTwoButtons;

    [self.view setNeedsUpdateConstraints];
    [self.view updateConstraintsIfNeeded];
}

- (void)setupView
{
    NSMutableArray *data = [NSMutableArray array];
    BOOL isProgress = _screenType == EOADeleteAllDataProgressBackupScreenType
            || _screenType == EOARemoveOldVersionsProgressBackupScreenType;
    if (isProgress)
    {
        NSMutableArray<NSMutableDictionary *> *progressCells = [NSMutableArray array];
        NSMutableDictionary *progressSection = [NSMutableDictionary dictionary];
        progressSection[@"cells"] = progressCells;
        progressSection[@"footer"] = _sectionDescription;
        [data addObject:progressSection];

        NSMutableDictionary *progressData = [NSMutableDictionary dictionary];
        progressData[@"key"] = @"progress_cell";
        progressData[@"type"] = [OADownloadProgressBarCell getCellIdentifier];
        progressData[@"title"] = _description;
        [progressCells addObject:progressData];
        _progressIndexPath = [NSIndexPath indexPathForRow:[progressCells indexOfObject:progressData]
                                                inSection:[data indexOfObject:progressSection]];
    }
    else
    {
        NSMutableArray<NSMutableDictionary *> *descriptionCells = [NSMutableArray array];
        NSMutableDictionary *descriptionSection = [NSMutableDictionary dictionary];
        descriptionSection[@"cells"] = descriptionCells;
        [data addObject:descriptionSection];

        NSMutableDictionary *descriptionData = [NSMutableDictionary dictionary];
        descriptionData[@"key"] = @"description_cell";
        descriptionData[@"type"] = [OATextLineViewCell getCellIdentifier];
        descriptionData[@"title"] = _description;
        [descriptionCells addObject:descriptionData];

        if (_screenType == EOADeleteAllDataConfirmBackupScreenType)
        {
            NSMutableArray<NSMutableDictionary *> *deleteCells = [NSMutableArray array];
            NSMutableDictionary *deleteSection = [NSMutableDictionary dictionary];
            deleteSection[@"cells"] = deleteCells;
            [data addObject:deleteSection];

            NSMutableDictionary *deleteData = [NSMutableDictionary dictionary];
            deleteData[@"key"] = @"delete_cell";
            deleteData[@"type"] = [OAFilledButtonCell getCellIdentifier];
            deleteData[@"title"] = OALocalizedString(@"delete_all_confirmation");
            deleteData[@"action"] = @"onDeleteButtonPressed";
            [deleteCells addObject:deleteData];
        }
    }

    _data = data;
}

- (NSMutableDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][@"cells"][indexPath.row];
}

- (void)deleteBackupFiles
{
    BOOL isProgressOfDeleteAll = _screenType == EOADeleteAllDataProgressBackupScreenType;
    BOOL isProgressOfRemoveOld = _screenType == EOARemoveOldVersionsProgressBackupScreenType;
    if (isProgressOfDeleteAll)
        [[OABackupHelper sharedInstance] deleteAllFiles:nil listener:self];
    else if (isProgressOfRemoveOld)
        [[OABackupHelper sharedInstance] deleteOldFiles:nil listener:self];
}

- (void)updateAfterFinished
{
    if (_screenType == EOADeleteAllDataProgressBackupScreenType)
        _sectionDescription = OALocalizedString(@"backup_delete_all_data_finished");
    else if (_screenType == EOARemoveOldVersionsProgressBackupScreenType)
        _sectionDescription = OALocalizedString(@"backup_remove_old_versions_finished");

    if (_progressIndexPath)
        _data[_progressIndexPath.section][@"footer"] = _sectionDescription;

    [self.tableView reloadData];
    self.bottomButton.hidden = NO;
    self.buttonsContainerView.hidden = NO;

    [self onCompleteTasks];
    _isDeleted = YES;
}

- (void)onDeleteButtonPressed
{
    EOADeleteBackupScreenType nextScreen = _screenType;
    if (_screenType == EOADeleteAllDataBackupScreenType)
        nextScreen = EOADeleteAllDataConfirmBackupScreenType;
    else if (_screenType == EOADeleteAllDataConfirmBackupScreenType)
        nextScreen = EOADeleteAllDataProgressBackupScreenType;
    else if (_screenType == EOARemoveOldVersionsBackupScreenType)
        nextScreen = EOARemoveOldVersionsProgressBackupScreenType;

    OADeleteAllVersionsBackupViewController *deleteAllDataViewController = [[OADeleteAllVersionsBackupViewController alloc] initWithScreenType:nextScreen];
    deleteAllDataViewController.deleteDelegate = self;
    [self.navigationController pushViewController:deleteAllDataViewController animated:YES];
}

- (IBAction)onDeleteButtonPressed:(id)sender
{
    [self onDeleteButtonPressed];
}

- (IBAction)onCancelButtonPressed:(id)sender
{
    if (_screenType == EOARemoveOldVersionsBackupScreenType)
        [self onDeleteButtonPressed];
    else
        [self onCloseDeleteAllBackupData];
}

- (IBAction)backButtonClicked:(id)sender
{
    [self onCloseDeleteAllBackupData];
}

- (IBAction)backImageButtonPressed:(id)sender
{
    [self onCloseDeleteAllBackupData];
}

#pragma mark - OAOnDeleteFilesListener

- (void)onFilesDeleteStarted:(NSArray<OARemoteFile *> *)files
{
    _progressFilesTotalCount = files.count;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_progressIndexPath)
            [self.tableView reloadRowsAtIndexPaths:@[_progressIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    });
}

- (void)onFileDeleteProgress:(OARemoteFile *)file progress:(NSInteger)progress
{
    _progressFilesCompleteCount = progress;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_progressIndexPath)
            [self.tableView reloadRowsAtIndexPaths:@[_progressIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    });
}

- (void)onFilesDeleteDone:(NSDictionary<OARemoteFile *, NSString *> *)errors
{
    _progressFilesCompleteCount = 1;
    _progressFilesTotalCount = 1;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateAfterFinished];
    });
}

- (void)onFilesDeleteError:(NSInteger)status message:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateAfterFinished];
    });
}

#pragma mark - OADeleteAllVersionsBackupDelegate

- (void)onCloseDeleteAllBackupData
{
    BOOL isProgress = _screenType == EOADeleteAllDataProgressBackupScreenType
            || _screenType == EOARemoveOldVersionsProgressBackupScreenType;
    BOOL isConfirm = _screenType == EOADeleteAllDataConfirmBackupScreenType;
    if (isProgress || isConfirm)
    {
        for (UIViewController *controller in self.navigationController.viewControllers)
        {
            if ([controller isKindOfClass:[OASettingsBackupViewController class]])
            {
                [self.navigationController popToViewController:controller animated:YES];
                return;
            }
        }
    }

    [self dismissViewController];
}

- (void)onCompleteTasks
{
    if (!_isDeleted && self.deleteDelegate)
        [self.deleteDelegate onCompleteTasks];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *) _data[section][@"cells"]).count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *cellType = item[@"type"];
    UITableViewCell *outCell = nil;

    if ([cellType isEqualToString:[OATextLineViewCell getCellIdentifier]])
    {
        OATextLineViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATextLineViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextLineViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextLineViewCell *) nib[0];
            cell.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
        }
        outCell = cell;
    }
    else if ([cellType isEqualToString:[OADownloadProgressBarCell getCellIdentifier]])
    {
        OADownloadProgressBarCell *cell = [tableView dequeueReusableCellWithIdentifier:[OADownloadProgressBarCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADownloadProgressBarCell getCellIdentifier] owner:self options:nil];
            cell = (OADownloadProgressBarCell *) nib[0];
            cell.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            cell.progressStatusLabel.text = item[@"title"];

            float progress = (float) _progressFilesCompleteCount / _progressFilesTotalCount;
            cell.progressValueLabel.text = [NSString stringWithFormat:@"%i%%", (int) (progress * 100)];
            [cell.progressBarView setProgress:progress];
        }

        outCell = cell;
    }
    else if ([cellType isEqualToString:[OAFilledButtonCell getCellIdentifier]])
    {
        OAFilledButtonCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAFilledButtonCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFilledButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAFilledButtonCell *) nib[0];
        }
        if (cell)
        {
            cell.backgroundColor = UIColor.clearColor;
            cell.button.backgroundColor = UIColorFromRGB(color_support_red);
            [cell.button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
            cell.button.layer.cornerRadius = 9;
            cell.topMarginConstraint.constant = 9.;
            cell.heightConstraint.constant = 42.;
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.button addTarget:self
                            action:NSSelectorFromString(item[@"action"])
                  forControlEvents:UIControlEventTouchUpInside];
        }
        outCell = cell;
    }

    [outCell updateConstraintsIfNeeded];
    return outCell;
}

@end
