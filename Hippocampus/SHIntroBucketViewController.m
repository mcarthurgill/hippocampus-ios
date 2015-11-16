//
//  SHIntroBucketViewController.m
//  Hippocampus
//
//  Created by Joseph Gill on 11/16/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHIntroBucketViewController.h"
#import "SHIntroThoughtViewController.h"

@interface SHIntroBucketViewController ()

@end

@implementation SHIntroBucketViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupGestureRecognizers];
    [self setupTextField];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark - Setup
- (void) setupTextField
{
    self.bucketNameField.delegate = self; 
}

# pragma mark - Actions
- (IBAction)nextAction:(id)sender {
    if (self.bucketNameField.text && self.bucketNameField.text.length > 0) {
        NSMutableDictionary *b = [self createBucket];
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]];
        SHIntroThoughtViewController *vc = (SHIntroThoughtViewController*)[storyboard instantiateViewControllerWithIdentifier:@"introThoughtViewController"];
        [vc setBucketLocalKey:[b localKey]];
        [self.navigationController pushViewController:vc animated:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Whoops!" message:@"You must enter a name!" delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
    }
}

- (NSMutableDictionary*) createBucket
{
    //CREATE BUCKET
    NSMutableDictionary* newBucket = [NSMutableDictionary create:@"bucket"];
    [newBucket setObject:self.bucketNameField.text forKey:@"first_name"];
    [newBucket assignLocalVersionIfNeeded:YES];
    [NSMutableDictionary addRecentBucketLocalKey:[newBucket localKey]];
    [newBucket saveRemote:^(id responseObject){
        [NSMutableDictionary bucketKeysWithSuccess:^(id responseObject){
            [[NSNotificationCenter defaultCenter] postNotificationName:@"updatedBucketLocalKeys" object:nil userInfo:nil];
        }failure:nil];
    }failure:nil];
    return newBucket;
}

# pragma mark - Gesture Recognizer
- (void) setupGestureRecognizers
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
}

-(void)dismissKeyboard {
    [self.bucketNameField resignFirstResponder];
}

# pragma mark - UITextField Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self nextAction:textField];
    [textField resignFirstResponder];
    return YES;
}


@end
