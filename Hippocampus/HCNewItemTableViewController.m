//
//  HCNewItemTableViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import "HCNewItemTableViewController.h"

@interface HCNewItemTableViewController ()

@end

@implementation HCNewItemTableViewController

@synthesize cancelButton;
@synthesize saveButton;
@synthesize bucketID;
@synthesize text;
@synthesize tV;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setText:@""];
    keyboardHeight = 0.0f;
    count = 0;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardChanged:) name:UIKeyboardDidChangeFrameNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 1;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"textCell" forIndexPath:indexPath];
    UITextView* textView = (UITextView*)[cell.contentView viewWithTag:1];
    [textView becomeFirstResponder];
    [textView setText:self.text];
    [textView setDelegate:self];
    [self setTV:textView];
    [self.tV scrollRectToVisible:CGRectMake(1, 1, 10, 10) animated:NO];
    [tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
    return cell;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = self.view.window.frame.size.height - [[UIApplication sharedApplication] statusBarFrame].size.height - self.navigationController.navigationBar.frame.size.height - keyboardHeight;
    return height;
}

# pragma mark keyboard

- (void) keyboardChanged:(NSNotification*)notification
{
    NSDictionary* info = [notification userInfo];
    //CGPoint from = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].origin;
    CGPoint to = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].origin;
    keyboardHeight = self.view.window.frame.size.height - to.y;
    
    if (count < 1) {
        [self.tableView reloadData];
        ++count;
        //[self.tV setContentOffset:CGPointZero animated:NO];
        //[self.tV setContentOffset:CGPointMake(0, 0)];
        //[self.tV scrollRectToVisible:CGRectMake(1, 1, 10, 10) animated:NO];
    }
    
}


# pragma  mark actions

- (IBAction)cancelAction:(id)sender
{
    [self.tV resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)saveAction:(id)sender
{
    if (self.tV.text.length > 0) {
        HCItem* item = [[HCItem alloc] create];
        [item setMessage:self.tV.text];
        [item setItemType:@"note"];
        if (self.bucketID && self.bucketID.length > 0) {
            [item setBucketID:self.bucketID];
            [item setStatus:@"assigned"];
        }
        [item saveWithSuccess:^(id responseBlock) {
                [self dismissViewControllerAnimated:YES completion:nil];
                NSLog(@"SUCCESS! %@", responseBlock);
            }
            failure:^(NSError *error) {
                NSLog(@"Error! %@", [error localizedDescription]);
            }
        ];
    } else {
        [self cancelAction:nil];
    }
}

# pragma mark text view delegate

- (void) textViewDidChange:(UITextView *)textView
{
    [self setText:textView.text];
}

@end
