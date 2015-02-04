//
//  HCIntroductionQuestionViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 1/30/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//
@protocol HCIntroductionQuestionDelegate <NSObject>
@required
-(void)incrementFlagged:(NSDictionary *)response;
-(BOOL)isLastQuestion:(NSDictionary *)question;
-(BOOL)shouldPassIntroduction;
@end

#import <UIKit/UIKit.h>
#import "HCIntroductionViewController.h"

@interface HCIntroductionQuestionViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) NSDictionary *question;
@property (assign, nonatomic) NSInteger index;
@property(nonatomic,assign)id delegate;

@end
