//
//  HCMainTabBarController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCMainTabBarController.h"

@interface HCMainTabBarController ()

@end

@implementation HCMainTabBarController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showNoteView:) name:@"openNewItemScreen" object:nil];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark login views



- (void) presentLoginViews:(BOOL)animated
{
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Login" bundle:nil];
    UIViewController * loginController = [storyboard instantiateInitialViewController];
    [self presentViewController:loginController animated:animated completion:nil];
}

- (void) presentNoteView:(BOOL)animated
{
    UIStoryboard * storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UINavigationController * nc = [storyboard instantiateViewControllerWithIdentifier:@"newItemNavigationController"];
    [self presentViewController:nc animated:animated completion:nil];
}

- (void) showNoteView:(NSNotification*)notification
{
    [self presentNoteView:NO];
}

@end
