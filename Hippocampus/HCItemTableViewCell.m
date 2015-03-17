//
//  HCItemTableViewCell.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/16/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCItemTableViewCell.h"

#define IMAGE_FADE_IN_TIME 0.3f
#define PICTURE_HEIGHT 280
#define PICTURE_MARGIN_TOP 8

@implementation HCItemTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) configureWithItem:(NSDictionary*)item {
    UILabel* note = (UILabel*)[self.contentView viewWithTag:1];
    UIFont* font = note.font;
    float leftMargin = note.frame.origin.x;
    float topMargin = note.frame.origin.y;
    
    [note removeFromSuperview];
    
    CGFloat width = self.contentView.frame.size.width - 10 - 25;
    
    note = [[UILabel alloc] initWithFrame:CGRectMake(leftMargin, topMargin, width, [self heightForText:[item truncatedMessage] width:width font:font]+4.0f)];

    [note setFont:font];
    [note setText:[item truncatedMessage]];
    [note setTag:1];
    [note setNumberOfLines:0];
    [note setLineBreakMode:NSLineBreakByWordWrapping];
    [self.contentView addSubview:note];
    
    UILabel* blueDot = (UILabel*) [self.contentView viewWithTag:4];
    
    if ([item isOutstanding] || ![item hasID]) {
        [blueDot setBackgroundColor:([item hasID] ? [UIColor blueColor] : [UIColor orangeColor])];
        [blueDot.layer setCornerRadius:4];
        [blueDot setClipsToBounds:YES];
        [blueDot setHidden:NO];
    } else {
        [blueDot setHidden:YES];
    }
    
    UILabel* timestamp = (UILabel*)[self.contentView viewWithTag:3];
    [timestamp setText:([item hasID] ? [NSString stringWithFormat:@"%@%@", ([item hasBucketsString] ? [NSString stringWithFormat:@"%@ - ", [item bucketsString]] : @""), [self dateToDisplayForItem:item]] : @"syncing with server")];
    
    int i = 0;
    while ([self.contentView viewWithTag:(200+i)]) {
        [[self.contentView viewWithTag:(200+i)] removeFromSuperview];
        ++i;
    }
    
    if ([item croppedMediaURLs]) {
        int j = 0;
        for (NSString* url in [item croppedMediaURLs]) {
            UIImageView* iv = [[UIImageView alloc] initWithFrame:CGRectMake(20, note.frame.origin.y+note.frame.size.height+PICTURE_MARGIN_TOP+(PICTURE_MARGIN_TOP+PICTURE_HEIGHT)*j, self.contentView.frame.size.width-40.0f, PICTURE_HEIGHT)];
            [iv setTag:(200+j)];
            [iv setContentMode:UIViewContentModeScaleAspectFill];
            [iv setClipsToBounds:YES];
            [iv.layer setCornerRadius:8.0f];
            if ([item hasID]) {
                [SGImageCache getImageForURL:url thenDo:^(UIImage* image) {
                    if (image) {
                        [iv setAlpha:0.0f];
                        iv.image = image;
                        [UIView animateWithDuration:IMAGE_FADE_IN_TIME animations:^(void) {
                            [iv setAlpha:1.0f];
                        }];
                    }
                }];
            } else {
                [iv setAlpha:0.0f];
                iv.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:url]];
                [UIView animateWithDuration:IMAGE_FADE_IN_TIME animations:^(void) {
                    [iv setAlpha:1.0f];
                }];
                
            }
            [self.contentView addSubview:iv];
            ++j;
        }
    }
}

- (CGFloat) heightForText:(NSString*)text width:(CGFloat)width font:(UIFont*)font
{
    if (!text || [text length] == 0) {
        return 0.0f;
    }
    NSDictionary *attributes = @{NSFontAttributeName: font};
    CGRect rect = [text boundingRectWithSize:CGSizeMake(width, 100000)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:attributes
                                     context:nil];
    return rect.size.height;
}

- (NSString*) dateToDisplayForItem:(NSDictionary*)item {
    if (item && [item hasNextReminderDate]) {
        return [NSString stringWithFormat:@"%@ - %@", [item itemType], [NSDate formattedDateFromString:[item nextReminderDate]]];
    } else {
        return [NSDate timeAgoInWordsFromDatetime:[item createdAt]];
    }
}
@end