//
//  SHLoadingTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/24/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHLoadingTableViewCell.h"
#import "SHMessagesViewController.h"

@implementation SHLoadingTableViewCell

@synthesize responseObject;
@synthesize label;

- (void)awakeFromNib
{
    // Initialization code
    inverted = NO;
    self.shouldInvert = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshedObject:) name:@"refreshedObject" object:nil];
    
    [self.label setFont:[UIFont secondaryFontWithSize:13.0f]];
    [self.label setTextColor:[UIColor SHFontLightGray]];
    
    [self setBackgroundColor:[UIColor slightBackgroundColor]];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) configureWithResponseObject:(NSMutableDictionary*)rO
{
    //NSLog(@"height: %f", self.frame.size.height);
    //NSLog(@"rO: %@", rO);
    if (!inverted && self.shouldInvert) {
        self.transform = CGAffineTransformMake(1, 0, 0, -1, 0, 0);
        inverted = YES;
    }
    [self setResponseObject:rO];
}


- (void) refreshedObject:(NSNotification*)notification
{
    //NSLog(@"%@|%@|", [[notification userInfo] objectForKey:@"local_key"], [self.responseObject localKey]);
    if ([[notification userInfo] objectForKey:@"local_key"] && NULL_TO_NIL([[notification userInfo] objectForKey:@"local_key"])) {
        if ([[notification userInfo] objectForKey:@"local_key"] && [self.responseObject localKey] && [[[notification userInfo] objectForKey:@"local_key"] isEqualToString:[self.responseObject localKey]]) {
            //this is a hit, a currently displaying talbeivewcell. reload it.
            if ([[self.responseObject objectForKey:@"vc"] respondsToSelector:@selector(tryToReload)]) {
                [(SHMessagesViewController*)[self.responseObject objectForKey:@"vc"] tryToReload];
            }
        }
    }
}



- (UITableView *)relatedTable
{
    if ([self.superview isKindOfClass:[UITableView class]])
        return (UITableView *)self.superview;
    else if ([self.superview.superview isKindOfClass:[UITableView class]])
        return (UITableView *)self.superview.superview;
    else if ([self.superview.superview.superview isKindOfClass:[UITableView class]])
        return (UITableView *)self.superview.superview.superview;
    else
        return nil;
}

- (void) invertIfUpsideDown
{
    if (inverted) {
        [self invert];
    }
}

- (void) invertIfRightSideUp
{
    if (!inverted) {
        [self invert];
    }
}

- (void) invert
{
    self.transform = CGAffineTransformMake(1, 0, 0, -1, 0, 0);
    inverted = !inverted;
}

@end
