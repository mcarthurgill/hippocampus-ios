//
//  HCIntroductionViewController.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 1/30/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCIntroductionViewController.h"
#import "HCIntroductionQuestionViewController.h"
@interface HCIntroductionViewController ()

@end

@implementation HCIntroductionViewController

@synthesize pageController;
@synthesize introQuestions;
@synthesize flagged;

- (void)viewDidLoad {
    [super viewDidLoad];
    self.flagged = 0;
    [self.navigationController.navigationBar setHidden:YES];
    
    [self getQuestions];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) getQuestions {
    [[LXServer shared] requestPath:[NSString stringWithFormat:@"/intro_questions.json"] withMethod:@"GET" withParamaters: nil
                           success:^(id responseObject) {
                               NSLog(@"response: %@", responseObject);
                               self.introQuestions = responseObject;
                               [self setPageViewController];
                           }
                           failure:^(NSError *error) {
                               NSLog(@"error: %@", [error localizedDescription]);
                           }
     ];

}

- (void) setPageViewController {
    self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    
    self.pageController.dataSource = self;
    [[self.pageController view] setFrame:[[self view] bounds]];
    
    HCIntroductionQuestionViewController *initialViewController = [self viewControllerAtIndex:0];
    
    NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
    
    [self.pageController setViewControllers:viewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    
    [self addChildViewController:self.pageController];
    [[self view] addSubview:[self.pageController view]];
    [self.pageController didMoveToParentViewController:self];
}

- (HCIntroductionQuestionViewController *)viewControllerAtIndex:(NSUInteger)index {
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"Introduction" bundle:[NSBundle mainBundle]];
    HCIntroductionQuestionViewController* qvc = [storyboard instantiateViewControllerWithIdentifier:@"HCIntroductionQuestionViewController"];
    [qvc setQuestion:[self.introQuestions objectAtIndex:index]];
    qvc.delegate = self;
    [self.navigationController pushViewController:qvc animated:YES];

    qvc.index = index;
    
    return qvc;
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(HCIntroductionQuestionViewController *)viewController index];
    if (index == 0) {
        return nil;
    }
    
    // Decrease the index by 1 to return
    index--;
    
    return [self viewControllerAtIndex:index];
    
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    
    NSUInteger index = [(HCIntroductionQuestionViewController *)viewController index];
    
    index++;

    if (index == self.introQuestions.count) {
        return nil;
    }
    
    return [self viewControllerAtIndex:index];
    
}


# pragma mark HCIntroductionQuestionDelegate 

-(void) incrementFlagged:(NSDictionary *)response {
    if ((BOOL)[response objectForKey:@"flagged"] == YES) {
        self.flagged++;
    }
}

-(BOOL) isLastQuestion:(NSDictionary *)question {
    return self.introQuestions.lastObject == question;
}

-(BOOL) shouldPassIntroduction {
    NSLog(@"****self.flagged = %d", self.flagged);
        NSLog(@"****total Q's = %lu", self.introQuestions.count/2);
    return (long)self.flagged < self.introQuestions.count/2;
}

@end
