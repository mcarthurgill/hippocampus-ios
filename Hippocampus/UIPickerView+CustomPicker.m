//
//  UIPickerView+CustomPicker.m
//  Hippocampus
//
//  Created by Will Schreiber on 3/18/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "UIPickerView+CustomPicker.h"

@implementation UIPickerView (CustomPicker)

- (BOOL) isDayPicker
{
    return self.tag == 0;
}

- (BOOL) isTypePicker
{
    return self.tag == 1;
}

@end
