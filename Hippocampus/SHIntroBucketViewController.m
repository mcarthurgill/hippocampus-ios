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

@synthesize descriptionLabel;
@synthesize bucketNameField;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupGestureRecognizers];
    [self setupTextField];
    [self setupLabel];
    
    [self setTitle:@"Step 1 of 2"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.bucketNameField becomeFirstResponder];
}



# pragma mark - Setup

- (void) setupLabel
{
    [self.descriptionLabel setText:@"Who is the last person you met with?"];
    [self.descriptionLabel setFont:[UIFont secondaryFontWithSize:18.0f]];
    [self.descriptionLabel setTextColor:[UIColor SHFontDarkGray]];
}

- (void) setupTextField
{
    self.bucketNameField.delegate = self;
    
    [self.bucketNameField setFont:[UIFont titleFontWithSize:15.0f]];
    [self.bucketNameField setPlaceholder:@"eg. Sarah Jones"];
    [self.bucketNameField setTextColor:[UIColor SHFontDarkGray]];
}




# pragma mark - Actions

- (IBAction)nextAction:(id)sender
{
    if (self.bucketNameField.text && self.bucketNameField.text.length > 0) {
        [self goToNext];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Whoops!" message:@"You must enter a name." delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
    }
}

- (void) goToNext
{
    NSMutableDictionary *b = [self createBucket];
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Seahorse" bundle:[NSBundle mainBundle]];
    SHIntroThoughtViewController *vc = (SHIntroThoughtViewController*)[storyboard instantiateViewControllerWithIdentifier:@"introThoughtViewController"];
    [vc setBucketLocalKey:[b localKey]];
    [self.navigationController pushViewController:vc animated:YES];
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

-(void)dismissKeyboard
{
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
