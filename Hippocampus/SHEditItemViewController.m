//
//  SHEditItemViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/11/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHEditItemViewController.h"

@interface SHEditItemViewController ()

@end

@implementation SHEditItemViewController

@synthesize localKey;
@synthesize textView;
@synthesize topMargin;
@synthesize bottomMargin;

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self setupValues];
    [self setupAppearance];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

- (void) setupAppearance
{
    self.topMargin.constant = -44.0f;
    
    UIBarButtonItem* barButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    [barButton setWidth:50.0f];
    self.navigationItem.leftBarButtonItem = barButton;
    
    UIBarButtonItem* rightBarButton = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:self action:@selector(save)];
    [rightBarButton setWidth:50.0f];
    self.navigationItem.rightBarButtonItem = rightBarButton;
    
    [self.view setBackgroundColor:[UIColor slightBackgroundColor]];
    [self.textView setBackgroundColor:[UIColor slightBackgroundColor]];
    
    [self.textView setFont:[UIFont titleFontWithSize:15.0f]];
    [self.textView setTextColor:[UIColor SHFontDarkGray]];
}

- (void) setupValues
{
    [self.textView setText:[[self item] message]];
    
    [self setTitle:@"Edit Thought"];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.textView scrollRectToVisible:CGRectMake(0, self.textView.contentSize.height-0.0001, 1, 0) animated:NO];
    [self.textView becomeFirstResponder];
}





# pragma mark actions

- (void) cancel
{
    [self.navigationController popViewControllerAnimated:NO];
}

- (void) save
{
    NSMutableDictionary* i = [self item];
    [i saveRemoteWithNewAttributes:@{@"message":self.textView.text} success:nil failure:nil];
    [self.navigationController popViewControllerAnimated:NO];
}




# pragma mark helpers

- (NSMutableDictionary*) item
{
    return [LXObjectManager objectWithLocalKey:self.localKey];
}




# pragma mark keyboard

- (void) keyboardDidShow:(NSNotification*)notification
{
    CGRect endFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.bottomMargin.constant = endFrame.size.height;
}

- (void) keyboardDidHide:(NSNotification*)notification
{
    CGRect endFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.bottomMargin.constant = endFrame.size.height;
}

@end
