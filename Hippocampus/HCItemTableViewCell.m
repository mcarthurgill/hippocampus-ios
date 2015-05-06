//
//  HCItemTableViewCell.m
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 3/16/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "HCItemTableViewCell.h"

#define IMAGE_FADE_IN_TIME 0.4f
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
    if ([item croppedMediaURLs]) {
        for (NSString* url in [item croppedMediaURLs]) {
            
            if ([url isImageUrl]) {
                UIImageView* iv = [self.contentView viewWithTag:(200+i)] ? (UIImageView*)[self.contentView viewWithTag:(200+i)] : [[UIImageView alloc] init];
                [iv setBackgroundColor:[UIColor clearColor]];
                [iv setFrame:CGRectMake(20, note.frame.origin.y+note.frame.size.height+PICTURE_MARGIN_TOP+(PICTURE_MARGIN_TOP+PICTURE_HEIGHT)*i, self.contentView.frame.size.width-40.0f, PICTURE_HEIGHT)];
                [iv setTag:(200+i)];
                ++i;
                
                [iv setContentMode:UIViewContentModeScaleAspectFill];
                [iv setClipsToBounds:YES];
                [iv.layer setCornerRadius:8.0f];
                
                UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                activityIndicator.alpha = 1.0;
                [activityIndicator setFrame:CGRectMake(iv.frame.size.width/2, iv.frame.size.height/2, activityIndicator.frame.size.width, activityIndicator.frame.size.height)];
                [iv addSubview:activityIndicator];
                [activityIndicator startAnimating];
                
                if ([item hasID]) {
                    
                    if ([SGImageCache haveImageForURL:url]) {
                        iv.image = [SGImageCache imageForURL:url];
                        [iv setAlpha:1.0f];
                        activityIndicator.alpha = 0.0;
                    } else if (![iv.image isEqual:[SGImageCache imageForURL:url]]) {
                        iv.image = nil;
                        [iv setAlpha:1.0f];
                        [SGImageCache getImageForURL:url thenDo:^(UIImage* image) {
                            if (image) {
                                float curAlpha = [iv alpha];
                                [iv setAlpha:0.0f];
                                iv.image = image;
                                [UIView animateWithDuration:IMAGE_FADE_IN_TIME animations:^(void){
                                    [iv setAlpha:curAlpha];
                                    activityIndicator.alpha = 0.0;
                                }];
                            }
                        }];
                    }
                    
                } else {
                    if ([NSData dataWithContentsOfFile:url] && ![iv.image isEqual:[UIImage imageWithData:[NSData dataWithContentsOfFile:url]]]) {
                        [iv setAlpha:0.0f];
                        iv.image = [UIImage imageWithData:[NSData dataWithContentsOfFile:url]];
                        [UIView animateWithDuration:IMAGE_FADE_IN_TIME animations:^(void) {
                            [iv setAlpha:1.0f];
                            activityIndicator.alpha = 0.0;
                        }];
                    }
                }
                
                if (!iv.superview) {
                    [self.contentView addSubview:iv];
                }
            }
        }
    }
    
    UIImageView* alarmClock = (UIImageView*) [self.contentView viewWithTag:32];
    if ([item hasReminder]) {
        [alarmClock setHidden:NO];
    } else {
        [alarmClock setHidden:YES];
    }
    
    while ([self.contentView viewWithTag:(200+i)]) {
        [[self.contentView viewWithTag:(200+i)] removeFromSuperview];
        ++i;
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
