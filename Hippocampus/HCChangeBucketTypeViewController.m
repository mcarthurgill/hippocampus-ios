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
@synthesize bucket;
@synthesize delegate; 


- (void)viewDidLoad {
    [super viewDidLoad];
    self.typeOptions = @[@"Other", @"Person", @"Event", @"Place"];
    [self.pickerView selectRow:[self.typeOptions indexOfObject:[self.bucket bucketType]] inComponent:0 animated:NO];
}

- (void)didReceiveMemoryWarning {
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
    [self.bucket setObject:[self.typeOptions objectAtIndex:row] forKey:@"bucket_type"];
}


# pragma mark - Actions

- (IBAction)saveAction:(id)sender {
    [self.delegate updateBucketType:self.bucket];
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
