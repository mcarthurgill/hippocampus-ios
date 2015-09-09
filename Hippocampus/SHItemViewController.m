//
//  SHItemViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHItemViewController.h"

@interface SHItemViewController ()

@end

@implementation SHItemViewController

@synthesize localKey;
@synthesize tableView;
@synthesize sections;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupSettings];
}

- (void) setupSettings
{
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}






# pragma mark table view delegate

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    self.sections = [[NSMutableArray alloc] init];
    
    
    
    return [self.sections count];
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}





@end
