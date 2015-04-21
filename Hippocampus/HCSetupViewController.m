//
//  HCSetupViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 4/17/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCSetupViewController.h"

@interface HCSetupViewController ()

@end

@implementation HCSetupViewController

@synthesize imageView;
@synthesize overlayView;
@synthesize screenshot;
@synthesize submitButton;
@synthesize setupTextField;
@synthesize progressLabel;
@synthesize mainLabel;
@synthesize blackView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.imageView setImage:screenshot];
    self.overlayView.layer.cornerRadius = 5;
    [self.overlayView.layer setMasksToBounds:YES];
    [self.imageView setBackgroundColor:[[UIColor clearColor] colorWithAlphaComponent:0.75]];
    [self.blackView setBackgroundColor:[[UIColor clearColor] colorWithAlphaComponent:0.75]];
    permission = NO;
    completed = NO;
    
    [self setupViews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupViews
{
    if (permission) {
        [self clearSetupTextField];
        [self setSubmitButtonWithTitle:@"Submit"];
        [self setupProgressLabel];
        [self setQuestionText];
    } else {
        [self askPermission];
    }
}

- (IBAction)dismissAction:(id)sender {
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)submitAction:(id)sender {
    if (permission) {
        if (self.setupTextField.text && self.setupTextField.text.length > 0) {
            [[LXServer shared] submitResponseToSetupQuestion:self.setupTextField.text success:^(id responseObject) {
                [[LXSetup theSetup] removeCurrentQuestion];
                [self refresh];
            }failure:^(NSError *error) {
                NSLog(@"ugh i hate my horse = %@", error);
            }];
        }
    } else {
        permission = YES;
        [self refresh];
    }
}

- (void) refresh
{
    if ([[LXSetup theSetup] questionsLeft]) {
        [UIView animateWithDuration:0.5
                         animations:^{
                            self.view.alpha = 0.1;
                         }
                         completion:^(BOOL finished){
                             [self setupViews];
                             [UIView animateWithDuration:0.5
                                              animations:^{
                                                  self.view.alpha = 1;
                                              }
                                              completion:^(BOOL finished){
                                                  
                                              }];
                         }];
    } else {
        if (completed) {
            [self dismissAction:nil];
        } else {
            [UIView animateWithDuration:0.5
                             animations:^{
                                 self.view.alpha = 0.1;
                             }
                             completion:^(BOOL finished){
                                 [self congratulate];
                                 [UIView animateWithDuration:0.5
                                                  animations:^{
                                                      self.view.alpha = 1;
                                                  }
                                                  completion:^(BOOL finished){
                                                      
                                                  }];
                             }];
        }
    }
}

# pragma mark - Helpers
-(void) clearSetupTextField
{
    if ([self.setupTextField isHidden]) {
        [self.setupTextField setHidden:NO];
    }
    self.setupTextField.text = @"";
}

- (void) setQuestionText
{
    if (permission) {
        [self.mainLabel setText:[[LXSetup theSetup] questionTextToShow]];
    }
}

-(void) setupProgressLabel
{
    unsigned long numQuestions = (unsigned long)[[[LXSetup theSetup] questions] count];
    [self.progressLabel setText:[NSString stringWithFormat:@"%lu more %@", numQuestions, numQuestions == 1 ? @"question" : @"questions"]];
}

-(void) setSubmitButtonWithTitle:(NSString*)title
{
    [self.submitButton setTitle:title forState:UIControlStateNormal];
}

- (void) askPermission
{
    [self.mainLabel setText:@"Would you like to finish setting up Hippocampus?"];
    [self.setupTextField setHidden:YES];
    [self setSubmitButtonWithTitle:@"Okay"];
    [self setupProgressLabel];
}

- (void) congratulate
{
    [self.mainLabel setText:@"Awesome job. You're done setting up! Keep making people feel like they matter."];
    [self.setupTextField setHidden:YES];
    [self setupProgressLabel];
    [self.submitButton setHidden:YES];
    completed = YES;
}

@end
