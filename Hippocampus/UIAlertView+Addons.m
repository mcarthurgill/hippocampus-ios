//
//  UIAlertView+Addons.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/15/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "UIAlertView+Addons.h"
#import <objc/runtime.h>

@implementation UIAlertView (Addons)

@dynamic indexPath;  //Must do this

-(void)setIndexPath:(NSIndexPath*)indexPath {
    objc_setAssociatedObject(self, @selector(indexPath), indexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
-(NSIndexPath*)indexPath {
    return objc_getAssociatedObject(self, @selector(indexPath));
}

@end
