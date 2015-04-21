//
//  LXSetup.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 4/17/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "LXSetup.h"

static LXSetup* theSetup = nil;

@implementation LXSetup

@synthesize questions;
@synthesize prompted;

# pragma mark - Initializers
//constructor
-(id) init
{
    if (theSetup) {
        return theSetup;
    }
    self = [super init];
    return self;
}

//singleton instance
+(LXSetup*) theSetup
{
    if (!theSetup) {
        theSetup = [[super allocWithZone:NULL] init];
    }
    return theSetup;
}

//prevent creation of additional instances
+(id)allocWithZone:(NSZone *)zone
{
    return [self theSetup];
}


# pragma mark - Questions

-(void) getSetupQuestions
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        [[LXServer shared] getSetupQuestionsForPercentage:[[[HCUser loggedInUser] setupCompletion] formattedString] success:^(id responseObject) {
            if ([responseObject objectForKey:@"questions"]) {
                self.questions = [[responseObject objectForKey:@"questions"] mutableCopy];
            }
        }failure:^(NSError *error) {
            NSLog(@"error");
        }];
    });
}

- (BOOL) shouldPromptForCompletion
{
    if ([[[LXSession thisSession] user] completedSetup] || prompted || self.questions.count == 0) {
        return NO;
    }
    [self setPrompted:YES]; 
    return YES;
}

- (NSString*) questionTextToShow
{
    if ([self questionsLeft]) {
        return [[[LXSetup theSetup] currentQuestion] objectForKey:@"question"];
    }
    return nil; 
}

- (NSDictionary*) currentQuestion
{
    return [self questionsLeft] ? [[[LXSetup theSetup] questions] firstObject] : nil;
}

- (void) removeCurrentQuestion
{
    if ([self.questions containsObject:[self currentQuestion]]) {
        [self.questions removeObject:[self currentQuestion]];
    }
}

- (BOOL) questionsLeft
{
    return self.questions.count > 0;
}
@end
