//
//  SHIntroThoughtViewController.m
//  Hippocampus
//
//  Created by Joseph Gill on 11/16/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHIntroThoughtViewController.h"
#import "SHMainViewController.h"
#import "LXAppDelegate.h"

@interface SHIntroThoughtViewController ()

@end

@implementation SHIntroThoughtViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self configureView];
    [self removeAbilityToGoBack];
    [self setupGestureRecognizers];
    [self setupTextField];
    [self setupRightBarButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationItem setHidesBackButton:YES animated:NO];
}

# pragma mark - Setup
- (void) setupTextField
{
    self.thoughtEntryTextField.delegate = self;
}

- (void) setupRightBarButton
{
    UIBarButtonItem *rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(saveAction)];
    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
}

- (void) configureView
{
    NSMutableDictionary *bucket = [LXObjectManager objectWithLocalKey:self.bucketLocalKey];
    [self.questionLabel setText:[NSString stringWithFormat:@"Awesome! What is something you would like to remember about %@?", [bucket firstName]]];
    [self.thoughtEntryTextField setPlaceholder:@"Be specific..."];
}

- (void) removeAbilityToGoBack
{
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    self.navigationItem.hidesBackButton = YES;
}

# pragma mark - Gesture Recognizers

- (void) setupGestureRecognizers
{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]
                                   initWithTarget:self
                                   action:@selector(dismissKeyboard)];
    
    [self.view addGestureRecognizer:tap];
}

-(void)dismissKeyboard {
    [self.thoughtEntryTextField resignFirstResponder];
}

# pragma mark - UITextField Delegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self saveAction];
    [textField resignFirstResponder];
    return YES;
}

                                           
# pragma mark - Actions
- (void) saveAction
{
    NSMutableDictionary *bucket = [LXObjectManager objectWithLocalKey:self.bucketLocalKey];
    if (self.thoughtEntryTextField && self.thoughtEntryTextField.text.length > 0) {
        NSMutableDictionary *item = [NSMutableDictionary createItemWithMessage:self.thoughtEntryTextField.text];
        [item setObject:[bucket localKey] forKey:@"bucket_local_key"];
        [item setObject:@"assigned" forKey:@"status"];
        [[LXObjectManager objectWithLocalKey:[NSMutableDictionary allThoughtsLocalKey]] addItem:item atIndex:0];
        [bucket addItem:item atIndex:0];
        [item saveRemote];
        [self showMainViewController];
    } else {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Whoops!" message:[NSString stringWithFormat:@"You must enter details about %@!", [bucket firstName]] delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:nil];
        [alert show];
    }
}

- (void) showMainViewController
{
    
}
                                           
                                           
@end
