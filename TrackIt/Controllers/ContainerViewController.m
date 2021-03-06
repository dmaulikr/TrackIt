//
//  ContainerViewController.m
//  TrackIt
//
//  Created by Jason Ji on 11/2/15.
//  Copyright © 2015 Jason Ji. All rights reserved.
//

#import "ContainerViewController.h"
#import "AddEntryViewController.h"
#import "AllEntriesTableViewController.h"
#import "DateTools.h"

const CGFloat minFilterTitleViewHeight = 34.0f;

@interface ContainerViewController ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomDividerLineHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *filterTitleViewHeightConstraint;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editTagsButton;


@property (strong, nonatomic) AllEntriesTableViewController *allEntriesVC;
@property (strong, nonatomic) NSNumberFormatter *formatter;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (nonatomic) DateFilterType currentModelType;

@end

@implementation ContainerViewController

-(NSDateFormatter *)dateFormatter {
    if(!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        _dateFormatter.dateFormat = @"MMMM";
    }
    return _dateFormatter;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    self.bottomDividerLineHeightConstraint.constant = 0.5;
    
    self.formatter = [[NSNumberFormatter alloc] init];
    self.formatter.numberStyle = NSNumberFormatterCurrencyStyle;
    
    self.currentModelType = DateFilterTypeThisMonth;
    
    self.totalTitleLabel.text = [NSString stringWithFormat:@"%@ Total", [self.dateFormatter stringFromDate:[NSDate date]]];
    
    __weak ContainerViewController *weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:@"NewTotalSpending" object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        NSNumber *value = note.userInfo[@"total"];
        weakSelf.totalValueLabel.text = [weakSelf.formatter stringFromNumber:value];
        weakSelf.totalValueLabel.textColor = value.doubleValue >= 0 ? [ColorManager moneyColor] : [UIColor orangeColor];
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName:@"ModelFiltersUpdated" object:self.allEntriesVC.model queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        TagFilter *tagFilter = [weakSelf.allEntriesVC currentTagFilter];
        if(tagFilter.tags.count > 0) {
            [weakSelf.filterTitleView updateWithTags:tagFilter.tags type:tagFilter.type];
            [weakSelf showFilterTitleView];
        }
        else {
            [weakSelf hideFilterTitleView];
        }
    }];
    
    NSDate *currentStartDate = [[NSUserDefaults standardUserDefaults] valueForKey:USER_START_DATE];
    NSDate *currentEndDate = [[NSUserDefaults standardUserDefaults] valueForKey:USER_END_DATE];
    if(!currentStartDate) {
        NSDate *now = [NSDate date];
        currentStartDate = [NSDate dateWithYear:now.year month:now.month day:1];
        [[NSUserDefaults standardUserDefaults] setValue:currentStartDate forKey:USER_START_DATE];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    if(!currentEndDate) {
        NSDate *now = [NSDate date];
        currentEndDate = [NSDate dateWithYear:now.year month:now.month day:now.day];
        [[NSUserDefaults standardUserDefaults] setValue:currentEndDate forKey:USER_END_DATE];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [self.dateButton setTitle:[NSString stringWithFormat:@"%@ to %@", [currentStartDate formattedDateWithStyle:NSDateFormatterMediumStyle locale:[NSLocale currentLocale]], [currentEndDate formattedDateWithStyle:NSDateFormatterMediumStyle locale:[NSLocale currentLocale]]] forState:UIControlStateNormal];
    
    self.filterTitleView.delegate = self;
    self.filterTitleViewHeightConstraint.constant = [self.allEntriesVC currentTagFilter].tags.count > 0 ? minFilterTitleViewHeight : 0;
    
    [self setEditing:NO];
    
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateTotalDisplay];
}

-(void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];
    if(editing) {
        self.editTagsButton = [[UIBarButtonItem alloc] initWithTitle:@"Manage Tags" style:UIBarButtonItemStylePlain target:self action:@selector(editTagsTapped)];
        self.bottomToolbar.items = @[
                                       [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                       self.editTagsButton,
                                       [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]
                                       ];
    }
    else {
        self.addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTapped:)];
        self.bottomToolbar.items = @[
                                     [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                                     self.addButton,
                                     [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil]
                                     ];
    }
    
    [self.allEntriesVC setEditing:editing animated:animated];
}

- (IBAction)timePeriodSelected:(UISegmentedControl *)sender {
    switch(sender.selectedSegmentIndex) {
        case 0: {
            self.currentModelType = DateFilterTypeThisMonth;
            self.dateButton.hidden = YES;
            self.totalTitleLabel.hidden = NO;
            self.totalTitleLabel.text = [NSString stringWithFormat:@"%@ Total", [self.dateFormatter stringFromDate:[NSDate date]]];
            break;
        }
        case 1:
            self.currentModelType = DateFilterTypeAllTime;
            self.dateButton.hidden = YES;
            self.totalTitleLabel.hidden = NO;
            self.totalTitleLabel.text = @"All Time Total";
            break;
        case 2:
            self.currentModelType = DateFilterTypeDateRange;
            // set current start/end dates if not set
            self.dateButton.hidden = NO;
            self.totalTitleLabel.hidden = YES;
            break;
    }
    [self updateTotalDisplay];
}

-(void)updateTotalDisplay {
    NSNumber *total;
    NSDate *currentStartDate = (NSDate *)[[NSUserDefaults standardUserDefaults] valueForKey:USER_START_DATE];
    NSDate *currentEndDate = (NSDate *)[[NSUserDefaults standardUserDefaults] valueForKey:USER_END_DATE];
    
    switch(self.currentModelType) {
        case DateFilterTypeLast7Days:
            break;
        case DateFilterTypeThisMonth: {
            DateFilter *filter = [[DateFilter alloc] initWithType:DateFilterTypeThisMonth];
            total = [self.allEntriesVC updateValuesWithFilters:@[filter]];
            break;
        }
        case DateFilterTypeAllTime: {
            DateFilter *filter = [[DateFilter alloc] initWithType:DateFilterTypeAllTime];
            total = [self.allEntriesVC updateValuesWithFilters:@[filter]];
            break;
        }
        case DateFilterTypeDateRange: {
            DateFilter *filter = [[DateFilter alloc] initWithType:DateFilterTypeDateRange startDate:currentStartDate endDate:currentEndDate];
            total = [self.allEntriesVC updateValuesWithFilters:@[filter]];
            break;
        }
    }
    self.totalValueLabel.text = [self.formatter stringFromNumber:total];
    self.totalValueLabel.textColor = total.doubleValue >= 0 ? [ColorManager moneyColor] : [UIColor orangeColor];
    
    [self.dateButton setTitle:[NSString stringWithFormat:@"%@ to %@", [currentStartDate formattedDateWithStyle:NSDateFormatterMediumStyle], [currentEndDate formattedDateWithStyle:NSDateFormatterMediumStyle]] forState:UIControlStateNormal];
}

-(void)showFilterTitleView {
    if(self.filterTitleViewHeightConstraint.constant != [self.filterTitleView preferredContentHeight]) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.filterTitleView.alpha = 1.0;
            self.filterTitleViewHeightConstraint.constant = [self.filterTitleView preferredContentHeight];
            [self.view layoutIfNeeded];
        } completion:nil];
    }
}

-(void)hideFilterTitleView {
    if(self.filterTitleViewHeightConstraint.constant > 0) {
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.filterTitleView.alpha = 0;
            self.filterTitleViewHeightConstraint.constant = 0;
            [self.view layoutIfNeeded];
        } completion:nil];
    }
}

- (IBAction)addTapped:(UIBarButtonItem *)sender {
    [self performSegueWithIdentifier:@"addEntrySegue" sender:self];
}

-(void)editTagsTapped {
    [self performSegueWithIdentifier:@"manageTagsSegue" sender:self];
}

#pragma mark - SelectDatesDelegate

-(void)newDatesSelected {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self updateTotalDisplay];
}

-(void)dateSelectionCanceled {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - FilterTitleViewDelegate

-(void)closeViewTapped {
    [self hideFilterTitleView];
    TagFilter *noTagFilter = [[TagFilter alloc] initWithType:TagFilterTypeShow tags:@[]];
    [self.allEntriesVC updateValuesWithFilters:@[noTagFilter]];
    [self updateTotalDisplay];
}

#pragma mark - EntryDelegate
// This is delegate because 3D touch may be invoked from cold app start, and self.allEntriesVC wouldn't exist yet
-(void)entryAddedOrChanged {
    [self.allEntriesVC entryAddedOrChanged];
}

-(void)entryCanceled {
    [self.allEntriesVC entryCanceled];
}

#pragma mark - TagFilterDelegate

-(void)didSelectTags:(NSArray<Tag *> *)tags withType:(enum TagFilterType)type {
    TagFilter *tagFilter = [[TagFilter alloc] initWithType:type tags:tags];
    [self.allEntriesVC updateValuesWithFilters:@[tagFilter]];
    if(tags.count > 0) {
        [self.filterTitleView updateWithTags:tags type:type];
        [self showFilterTitleView];
    }
    else
        [self hideFilterTitleView];
    
    [self updateTotalDisplay];
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"embedAllEntriesController"]) {
        self.allEntriesVC = segue.destinationViewController;
    }
    else if([segue.identifier isEqualToString:@"addEntrySegue"]) {
        AddEntryViewController *vc = segue.destinationViewController;
        vc.delegate = self;
    }
    else if([segue.identifier isEqualToString:@"manageTagsSegue"]) {
        ManageTagsViewController *vc = segue.destinationViewController;
        vc.popoverPresentationController.delegate = self;
        vc.popoverPresentationController.barButtonItem = self.editTagsButton;
        vc.coreDataManager = [CoreDataStackManager sharedInstance];
    }
    else if([segue.identifier isEqualToString:@"selectDatesSegue"]) {
        SelectDatesViewController *vc = segue.destinationViewController;
        vc.delegate = self;
    }
    else if([segue.identifier isEqualToString:@"showTagFilter"]) {
        SelectTagsViewController *vc = segue.destinationViewController;
        vc.delegate = self;
        vc.popoverPresentationController.delegate = self;
        vc.coreDataManager = [CoreDataStackManager sharedInstance];
        vc.selectedTags = [self.allEntriesVC currentTagFilter].tags;
        vc.currentFilterType = [self.allEntriesVC currentTagFilter].type;
    }
}

#pragma mark - UIPopoverPresentationController

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
    return UIModalPresentationNone;
}

@end
