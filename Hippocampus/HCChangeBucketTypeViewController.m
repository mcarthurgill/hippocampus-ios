//
//  HCChangeBucketTypeViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 4/1/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCChangeBucketTypeViewController.h"

@interface HCChangeBucketTypeViewController ()

@end

@implementation HCChangeBucketTypeViewController

@synthesize typeOptions;
@synthesize pickerView;
@synthesize bucketDict;
@synthesize delegate;
@synthesize selectedBucketType;
@synthesize selectedGroup;

@synthesize groupField;
@synthesize descriptionLabel;


- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.bucketDict = [[NSMutableDictionary alloc] initWithDictionary:[self.bucketDict mutableCopy]];
    
    NSLog(@"BUCKET DICT: %@", self.bucketDict);
    
    self.typeOptions = [[LXSession thisSession] groups];
    [self.typeOptions insertObject:@{@"group_name":@"Ungrouped",@"id":@"0"} atIndex:0];
    
    NSString* groupID = [self.bucketDict getGroupID];
    if (groupID) {
        for (NSDictionary* group in self.typeOptions) {
            if ([[group ID] isEqual:groupID]) {
                self.selectedBucketType = group;
                self.selectedGroup = self.selectedBucketType;
            }
        }
    }
    
    if (self.selectedBucketType && [self.typeOptions indexOfObject:selectedBucketType]) {
        [self.pickerView selectRow:[self.typeOptions indexOfObject:selectedBucketType] inComponent:0 animated:NO];
        self.selectedGroup = self.selectedBucketType;
    }
    
    [self showHidePicker];
    
    if ([self.typeOptions count] < 2) {
        [self.groupField becomeFirstResponder];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


# pragma mark picker view delegate data source

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return [self.typeOptions count];
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return [[self.typeOptions objectAtIndex:row] objectForKey:@"group_name"];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    self.selectedGroup = [self.typeOptions objectAtIndex:row];
}


# pragma mark - Actions

- (IBAction)saveAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(updateBucketGroup:)]) {
        
        if ([self newGroupMode]) {
            self.selectedGroup = nil;
            //CREATE THE NEW GROUP HERE!
            [self showHUDWithMessage:@"Creating Group"];
            [[LXServer shared] requestPath:@"/groups.json" withMethod:@"POST" withParamaters:@{@"group":@{@"group_name":self.groupField.text, @"user_id":[[[LXSession thisSession] user] userID]}}
                                   success:^(id responseObject) {
                                       self.selectedGroup = responseObject;
                                       [self hideHUD];
                                       [self addToGroupAction];
                                   }
                                   failure:^(NSError* error) {
                                       [self hideHUD];
                                   }
             ];
        } else {
            [self addToGroupAction];
        }
    }
}

- (void) addToGroupAction
{
    if (!self.selectedGroup) {
        return;
    }
    [self showHUDWithMessage:@"Moving..."];
    
    [self.bucketDict setObject:[self.selectedGroup ID] forKey:@"group_id"];
    [self.bucketDict setObject:self.selectedGroup forKey:@"group"];
    
    [[LXServer shared] requestPath:@"/buckets/change_group_for_user.json" withMethod:@"PUT" withParamaters:@{@"bucket_id":[self.bucketDict ID], @"group_id":[self.selectedGroup ID], @"user_id":[[[LXSession thisSession] user] userID]} success:^(id responseObject) {
        [self.delegate updateBucketGroup:self.bucketDict];
        [self hideHUD];
        [self dismissViewControllerAnimated:YES completion:nil];
    } failure:^(NSError *error) {
        [self hideHUD];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}

- (IBAction)cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


# pragma mark helpers

- (BOOL) newGroupMode
{
    return [self.groupField isFirstResponder] || (self.groupField.text && [self.groupField.text length] > 0);
}

- (void) showHidePicker
{
    if ([self newGroupMode] || [self.typeOptions count] < 2) {
        [self.descriptionLabel setHidden:YES];
        [self.pickerView setHidden:YES];
    } else {
        [self.descriptionLabel setHidden:NO];
        [self.pickerView setHidden:NO];
    }
}


# pragma mark text field delegate

- (BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self showHidePicker];
    return YES;
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    [self saveAction:nil];
    return NO;
}


# pragma mark hud

- (void) showHUDWithMessage:(NSString*) message
{
    hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = message;
}

- (void) hideHUD
{
    [hud hide:YES];
}

@end
