//
//  LXSetup.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 4/17/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LXSetup : NSObject

@property (strong, nonatomic) NSMutableArray *questions;
@property BOOL prompted;

+ (LXSetup*) theSetup;
- (void) getSetupQuestions;
- (BOOL) shouldPromptForCompletion;
- (NSString*) questionTextToShow;
- (NSDictionary*) currentQuestion;
- (void) removeCurrentQuestion;
- (BOOL) questionsLeft;
- (BOOL) visitedThisScreen:(id)vc;
- (BOOL) visitedThisScreen:(id)vc withAssignMode:(BOOL)assignMode;
- (UIImage*) takeScreenshot; 
@end
