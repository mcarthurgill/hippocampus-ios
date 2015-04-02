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
    self.typeOptions = @[@"Other", @"Person", @"Event", @"Place"];
    self.selectedBucketType = [self.bucketDict bucketType];
    [self.pickerView selectRow:[self.typeOptions indexOfObject:selectedBucketType] inComponent:0 animated:NO];
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
    return [self.typeOptions objectAtIndex:row];
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
