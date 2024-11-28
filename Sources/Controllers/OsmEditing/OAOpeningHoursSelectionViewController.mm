//
//  OAOpeningHoursSelectionViewController.m
//  OsmAnd
//
//  Created by Paul on 2/27/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAOpeningHoursSelectionViewController.h"
#import "OASimpleTableViewCell.h"
#import "Localization.h"
#import "OAEditPOIData.h"
#import "OASwitchTableViewCell.h"
#import "OADateTimePickerTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OASizes.h"
#import "OAOSMSettings.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"
#import "OALog.h"

#include <ctime>

#define kTime24_00 1440
#define kNumberOfSections 2

static const NSInteger daysSectionIndex = 0;
static const NSInteger timeSectionIndex = 1;

@interface OAOpeningHoursSelectionViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *toolBar;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIButton *applyButton;


@end

@implementation OAOpeningHoursSelectionViewController
{
    NSArray *_weekdaysData;
    NSArray *_timeData;
    
    OAEditPOIData *_poiData;
    std::shared_ptr<OpeningHoursParser::OpeningHours> _openingHours;
    NSInteger _ruleIndex;
    BOOL _createNew;
    
    std::shared_ptr<OpeningHoursParser::OpeningHoursRule> _currentRule;
    
    NSDateFormatter *_dateFormatter;
    NSDate *_startDate;
    NSDate *_endDate;
    
    NSIndexPath *_datePickerIndexPath;
    
    BOOL _isOpened24_7;
}

-(id)initWithEditData:(OAEditPOIData *)poiData openingHours:(std::shared_ptr<OpeningHoursParser::OpeningHours>)openingHours
            ruleIndex:(NSInteger)ruleIndex
{
    self = [super init];
    if (self) {
        _poiData = poiData;
        _openingHours = openingHours;
        _ruleIndex = ruleIndex;
        _createNew = _ruleIndex == -1;
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterNoStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    self.tableView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
    self.navigationItem.title = OALocalizedString(@"osm_add_timespan");
}


-(void) applyLocalization
{
    [_applyButton setTitle:OALocalizedString(@"shared_string_apply") forState:UIControlStateNormal];
    [_deleteButton setTitle:OALocalizedString(@"shared_string_delete") forState:UIControlStateNormal];
}

-(UIView *) getMiddleView
{
    return _tableView;
}

-(UIView *) getBottomView
{
    return _toolBar;
}

-(CGFloat) getToolBarHeight
{
    return customSearchToolBarHeight;
}

- (NSString *)weekdayNameFromWeekdayNumber:(NSInteger)weekdayNumber
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSArray *weekdaySymbols = calendar.weekdaySymbols;
    NSInteger index = (weekdayNumber + calendar.firstWeekday - 1) % 7;
    return weekdaySymbols[index];
}

- (NSInteger)indexFromWeekdayNumber:(NSInteger)weekdayNumber
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    return (weekdayNumber + calendar.firstWeekday - 1) % 7;
}

- (NSInteger)weekdayNumberFromIndex:(NSInteger)index
{
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSInteger value = calendar.firstWeekday == 2 ? index : (index - calendar.firstWeekday + 7) % 7;
    return value;
}

- (void)generateData {
    NSMutableArray *dataArr = [NSMutableArray new];
    for (int i = 0; i < [_dateFormatter weekdaySymbols].count; i++) {
        [dataArr addObject:@{
                             @"title" : [[self weekdayNameFromWeekdayNumber:i] capitalizedString],
                             @"type" : [OASimpleTableViewCell getCellIdentifier]
                             }];
    }
    _weekdaysData = [NSArray arrayWithArray:dataArr];
    
    [dataArr removeAllObjects];
    _isOpened24_7 = _currentRule->isOpened24_7();
    const auto rule = std::dynamic_pointer_cast<OpeningHoursParser::BasicOpeningHourRule>(_currentRule);
    [dataArr addObject:@{
                         @"title" : OALocalizedString(@"osm_around_the_clock"),
                         @"type" : [OASwitchTableViewCell getCellIdentifier]
                         }];

    _startDate = [self dateFromMinutes:rule->getStartTime()];
    _endDate = [self dateFromMinutes:rule->getEndTime()];
    [dataArr addObject:@{
                         @"title" : OALocalizedString(@"osm_opens_at"),
                         @"type" : [OAValueTableViewCell getCellIdentifier],
                         }];
    
    [dataArr addObject:@{
                         @"title" : OALocalizedString(@"osm_closes_at"),
                         @"type" : [OAValueTableViewCell getCellIdentifier],
                         }];
    _timeData = [NSArray arrayWithArray:dataArr];
}

-(void)setupView
{
    [self applySafeAreaMargins];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    _applyButton.layer.cornerRadius = 9.0;
    _deleteButton.layer.cornerRadius = 9.0;
    if (_openingHours == nullptr)
        _openingHours.reset(new OpeningHoursParser::OpeningHours());
    if (!_createNew && _ruleIndex < _openingHours->getRules().size())
        _currentRule = _openingHours->getRules()[_ruleIndex];
    else
    {
        _currentRule.reset(new OpeningHoursParser::BasicOpeningHourRule());
        const auto rule = std::dynamic_pointer_cast<OpeningHoursParser::BasicOpeningHourRule>(_currentRule);
        rule->setStartTime(0);
        rule->setEndTime(kTime24_00);
    }

    [self generateData];
}

- (BOOL)datePickerIsShown
{
    return _datePickerIndexPath != nil;
}

-(NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    if (indexPath.section == daysSectionIndex)
        return _weekdaysData[indexPath.row];
    else if (indexPath.section == timeSectionIndex)
    {
        if ([self datePickerIsShown]) {
            if ([indexPath isEqual:_datePickerIndexPath])
                return [NSDictionary new];
            else if (indexPath.row < _timeData.count)
                return _timeData[indexPath.row];
            else
                return _timeData[indexPath.row - 1];
        }
        else
            return _timeData[indexPath.row];
    }
    return [NSDictionary new];
}

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        BOOL isChecked = ((UISwitch *) sender).on;
        _isOpened24_7 = isChecked;
        const auto rule = std::dynamic_pointer_cast<OpeningHoursParser::BasicOpeningHourRule>(_currentRule);
        for (int i = 0; i < 7; i++)
        {
            rule->getDays()[i] = isChecked;
        }
        int endTime = isChecked ? kTime24_00 : 0;
        rule->setStartTime(0);
        rule->setEndTime(endTime);
        _startDate = [self dateFromMinutes:0];
        _endDate = [self dateFromMinutes:endTime];
        if ([self datePickerIsShown])
        {
            [_tableView beginUpdates];
            [self hideExistingPicker];
            [_tableView endUpdates];
        }
        [self.tableView reloadData];
    }
}

- (NSDate *) dateNoSec:(NSDate *)date
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:date];
    [dateComponents setSecond:0];
    
    return [calendar dateFromComponents:dateComponents];
}

- (NSDate *) dateFromMinutes:(int)minutes
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    
    NSDateComponents *dateComponents = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute fromDate:[[NSDate alloc] init]];
    [dateComponents setSecond:0];
    [dateComponents setMinute:minutes % 60];
    [dateComponents setHour:minutes/60];
    
    return [calendar dateFromComponents:dateComponents];
}

- (int) dateToMinutes:(NSDate *)date
{
    NSCalendar *calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSCalendarIdentifierGregorian];
    NSDateComponents *components = [calendar components:(NSCalendarUnitHour | NSCalendarUnitMinute) fromDate:date];
    NSInteger hour = [components hour];
    NSInteger minutes = [components minute];
    return (int) (hour * 60 + minutes);
}

-(void)timePickerChanged:(id)sender
{
    UIDatePicker *picker = (UIDatePicker *)sender;
    NSDate *newDate = [self dateNoSec:picker.date];
    if (_datePickerIndexPath.row == 2)
        _startDate = [self dateNoSec:newDate];
    else if (_datePickerIndexPath.row == 3)
        _endDate = [self dateNoSec:newDate];
    [self updateRuleTime];
    [_tableView reloadData];
}

-(void)updateRuleTime
{
    const auto rule = std::dynamic_pointer_cast<OpeningHoursParser::BasicOpeningHourRule>(_currentRule);
    OALog(@"startMinutes: %d", [self dateToMinutes:_startDate]);
    rule->setStartTime([self dateToMinutes:_startDate]);
    rule->setEndTime([self dateToMinutes:_endDate]);
}

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        
        if (cell)
        {
            [cell.titleLabel setText:item[@"title"]];
            cell.accessoryType = _currentRule->containsDay({0, 0, 0, 0, 0, 0, static_cast<int>([self indexFromWeekdayNumber:indexPath.row])}) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];

            cell.switchView.on = _isOpened24_7;
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.valueLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = [_dateFormatter stringFromDate:indexPath.row == 1 ? _startDate : _endDate];
        }
        return cell;
    }
    else if ([self datePickerIsShown] && [_datePickerIndexPath isEqual:indexPath])
    {
        OADateTimePickerTableViewCell* cell;
        cell = (OADateTimePickerTableViewCell *)[tableView dequeueReusableCellWithIdentifier:[OADateTimePickerTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADateTimePickerTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OADateTimePickerTableViewCell *)[nib objectAtIndex:0];
        }
        cell.dateTimePicker.datePickerMode = UIDatePickerModeTime;
        cell.dateTimePicker.date = indexPath.row - 1 == 1 ? _startDate : _endDate;
        [cell.dateTimePicker removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
        [cell.dateTimePicker addTarget:self action:@selector(timePickerChanged:) forControlEvents:UIControlEventValueChanged];
        
        return cell;
    }
    else
        return nil;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == daysSectionIndex)
        return _weekdaysData.count;
    else if (section == timeSectionIndex)
        return _timeData.count + ([self datePickerIsShown] ? 1 : 0);
    return 0;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == daysSectionIndex)
        return OALocalizedString(@"working_days");
    else if (section == timeSectionIndex)
        return OALocalizedString(@"shared_string_time");
    return @"";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberOfSections;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        [self.tableView beginUpdates];
        
        if ([self datePickerIsShown] && (_datePickerIndexPath.row - 1 == indexPath.row))
            [self hideExistingPicker];
        else
        {
            NSIndexPath *newPickerIndexPath = [self calculateIndexPathForNewPicker:indexPath];
            if ([self datePickerIsShown])
                [self hideExistingPicker];
            
            [self showNewPickerAtIndex:newPickerIndexPath];
            _datePickerIndexPath = [NSIndexPath indexPathForRow:newPickerIndexPath.row + 1 inSection:indexPath.section];
        }
        
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.tableView endUpdates];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:YES];
    }
    else if ([item[@"type"] isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        const auto rule = std::dynamic_pointer_cast<OpeningHoursParser::BasicOpeningHourRule>(_currentRule);
        rule->getDays()[[self weekdayNumberFromIndex:indexPath.row]] = !rule->getDays()[[self weekdayNumberFromIndex:indexPath.row]];
        [_tableView reloadData];
    }
}

- (void)hideExistingPicker {
    
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:_datePickerIndexPath.row inSection:_datePickerIndexPath.section]]
                          withRowAnimation:UITableViewRowAnimationFade];
    _datePickerIndexPath = nil;
}

- (NSIndexPath *)calculateIndexPathForNewPicker:(NSIndexPath *)selectedIndexPath {
    NSIndexPath *newIndexPath;
    if (([self datePickerIsShown]) && (_datePickerIndexPath.row < selectedIndexPath.row))
        newIndexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row - 1 inSection:timeSectionIndex];
    else
        newIndexPath = [NSIndexPath indexPathForRow:selectedIndexPath.row  inSection:timeSectionIndex];
    
    return newIndexPath;
}

- (void)showNewPickerAtIndex:(NSIndexPath *)indexPath {
    
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:timeSectionIndex]];
    
    [self.tableView insertRowsAtIndexPaths:indexPaths
                          withRowAnimation:UITableViewRowAnimationFade];
}

- (std::vector<std::shared_ptr<OpeningHoursParser::OpeningHoursRule> >)getRulesWithoutCurrent {
    auto rules = _openingHours->getRules();
    if (!_createNew)
        rules.erase(rules.begin() + _ruleIndex);
    return rules;
}

- (NSString *)generateOpeningHoursString:(const std::vector<std::shared_ptr<OpeningHoursParser::OpeningHoursRule> > &)rules {
    NSMutableString *mutableStr = [[NSMutableString alloc] init];
    int count = 0;
    for (const auto& rule : rules)
    {
        [mutableStr appendString:[NSString stringWithUTF8String:rule->toRuleString().c_str()]];
        if (++count < rules.size())
            [mutableStr appendString:@"; "];
    }
    return mutableStr;
}

- (IBAction)applyButtonPressed:(id)sender {
    auto rules = [self getRulesWithoutCurrent];
    rules.push_back(_currentRule);
    NSString *openingHoursStr = [self generateOpeningHoursString:rules];
    [_poiData putTag:[OAOSMSettings getOSMKey:OSM_TAG_OPENING_HOURS] value:openingHoursStr];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)deleteButtonPressed:(id)sender {
    auto rules = [self getRulesWithoutCurrent];
    NSString *openingHoursStr = [self generateOpeningHoursString:rules];
    [_poiData putTag:[OAOSMSettings getOSMKey:OSM_TAG_OPENING_HOURS] value:openingHoursStr];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
