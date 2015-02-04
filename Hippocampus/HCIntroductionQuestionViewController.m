//
//  HCIntroductionQuestionViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 1/30/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCIntroductionQuestionViewController.h"
#import "LXAppDelegate.h"
#import "HCIntroductionFailureViewController.h"

@interface HCIntroductionQuestionViewController ()

@end

@implementation HCIntroductionQuestionViewController

@synthesize question;
@synthesize index;
@synthesize delegate;


- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


# pragma mark tableview delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1 + [[self.question objectForKey:@"introduction_responses"] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"questionCell" forIndexPath:indexPath];
        
        UILabel* label = (UILabel*)[cell.contentView viewWithTag:1];
        [label setText:[self.question objectForKey:@"question_text"]];
        
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"responseCell" forIndexPath:indexPath];
        
        UILabel* label = (UILabel*)[cell.contentView viewWithTag:1];
        [label setText:[[[self.question objectForKey:@"introduction_responses"] objectAtIndex:indexPath.row - 1] objectForKey:@"response_text"]];
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    if (indexPath.row == 0) {
        return 100;
    }
    else {
        return 60;
    }
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0) {
        if ((BOOL)[[[self.question objectForKey:@"introduction_responses"] objectAtIndex:indexPath.row - 1] objectForKey:@"flagged"] == YES) {
            if([delegate respondsToSelector:@selector(incrementFlagged:)])
            {
                [delegate incrementFlagged:[[self.question objectForKey:@"introduction_responses"] objectAtIndex:indexPath.row - 1]];
            }
        }
        if([delegate respondsToSelector:@selector(isLastQuestion:)]) {
            if([delegate isLastQuestion:self.question]) {
                if([delegate respondsToSelector:@selector(shouldPassIntroduction)]) {
                    if([delegate shouldPassIntroduction]) {
                        [(LXAppDelegate*)[[UIApplication sharedApplication] delegate] setRootStoryboard:@"Main"];
                    } else {
                        //do something if they fail. 
//                        UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Introduction" bundle:[NSBundle mainBundle]];
//                        HCIntroductionFailureViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"failureViewController"];
//                        [self.navigationController presentViewController:vc animated:YES completion:nil];
                    }
                }
            }
        }
    }
}



@end
