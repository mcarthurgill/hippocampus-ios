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


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.typeOptions = [[NSMutableArray alloc] initWithArray:[[NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] objectForKey:@"buckets"]] groups]]; //@[@"Other", @"Person", @"Event", @"Place"];
    [self.typeOptions insertObject:@{@"group_name":@"Ungrouped",@"id":@"0"} atIndex:0];
    
    NSString* groupID = [self.bucketDict getGroupID];
    if (groupID) {
        for (NSDictionary* group in self.typeOptions) {
            if ([[group ID] isEqual:groupID]) {
                self.selectedBucketType = group;
            }
        }
    }
    
    if (self.selectedBucketType && [self.typeOptions indexOfObject:selectedBucketType]) {
        [self.pickerView selectRow:[self.typeOptions indexOfObject:selectedBucketType] inComponent:0 animated:NO];
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
    self.selectedBucketType = [self.typeOptions objectAtIndex:row];
}


# pragma mark - Actions

- (IBAction)saveAction:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(updateBucketType:)]) {
        [self.bucketDict setObject:self.selectedBucketType forKey:@"bucket_type"];
        [self.delegate updateBucketType:self.bucketDict];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
