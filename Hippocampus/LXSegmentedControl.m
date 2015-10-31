//
//  LXSegmentedControl.m
//  Hippocampus
//
//  Created by Will Schreiber on 10/31/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "LXSegmentedControl.h"

@implementation LXSegmentedControl

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    NSInteger previousSelectedSegmentIndex = self.selectedSegmentIndex;
    [super touchesEnded:touches withEvent:event];
    if (previousSelectedSegmentIndex == self.selectedSegmentIndex) {
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

@end
