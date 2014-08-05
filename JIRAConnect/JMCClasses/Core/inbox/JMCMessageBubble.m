/**
   Copyright 2011 Atlassian Software

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
**/
//
//  Created by nick on 7/05/11.
//
//  To change this template use File | Settings | File Templates.
//
#import "JMCMessageBubble.h"
#import "JMCComment.h"

//these values depend on the geometry of an image used as bubble's background (Balloon_1 and Balloon_2)
#define BUBBLE_MIN_HEIGHT 32.f
#define BUBBLE_CAP_WIDTH 20.f
#define BUBBLE_CAP_HEIGHT 15.f

#define BUBBLE_L_MARGIN_X 12.f
#define BUBBLE_R_MARGIN_X 8.f
#define BUBBLE_Y_OFFSET 4.f
#define BUBBLE_WIDTH_RATIO 0.7f


@interface JMCMessageBubble ()

@property (nonatomic, strong) UIImageView *bubble;
@property (nonatomic, strong) UITextView *textView;
@property (nonatomic, strong) UILabel *detailLabel;

@end

@implementation JMCMessageBubble

#pragma mark text attributes and sizing

+(UIFont *)fontBubble{
    return [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
}

+(UIFont *)fontDetailLabel{
    return [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
}


+ (CGSize)detailLabelSizeForComment:(JMCComment *)comment withWidthConstraint:(CGFloat) widthConstraint {

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    dateFormatter.timeStyle = NSDateFormatterShortStyle;

    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode=NSLineBreakByClipping;

    CGSize size;

    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 7)
        size = [[dateFormatter stringFromDate:comment.date]
                boundingRectWithSize:CGSizeMake(widthConstraint, 20.f)
                             options:NSStringDrawingTruncatesLastVisibleLine | NSStringDrawingUsesLineFragmentOrigin
                          attributes:@{NSFontAttributeName:[JMCMessageBubble fontDetailLabel], NSParagraphStyleAttributeName:paragraphStyle}
                             context:nil
        ].size;
    else //if iOS version is below 6, use the method deprected in iOS 7
        size = [[dateFormatter stringFromDate:comment.date]
                sizeWithFont:[JMCMessageBubble fontDetailLabel]
           constrainedToSize:CGSizeMake(widthConstraint, 20.f)
               lineBreakMode:NSLineBreakByClipping
        ];


    return CGSizeMake(ceilf(size.width), ceilf(size.height));

}

+ (CGSize)bubbleSizeForComment:(JMCComment *) comment withWidthConstraint:(CGFloat) widthConstraint {

    UITextView *uiTextView = [JMCMessageBubble textView];
    uiTextView.text = [comment.body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    CGSize size = [uiTextView sizeThatFits:CGSizeMake(widthConstraint, MAXFLOAT)];

    if(size.height < BUBBLE_MIN_HEIGHT) //avoid that the frame height is lower than the image's height
            size.height = BUBBLE_MIN_HEIGHT;


    return CGSizeMake(ceilf(size.width), ceilf(size.height));
}

+ (CGSize) cellSizeForComment:(JMCComment *) comment widthConstraint:(CGFloat) widthConstraint{

    CGSize bubbleSize = [JMCMessageBubble bubbleSizeForComment:comment withWidthConstraint:widthConstraint*BUBBLE_WIDTH_RATIO];
    CGSize detailLabelSize = [JMCMessageBubble detailLabelSizeForComment:comment withWidthConstraint:widthConstraint];

    return CGSizeMake(widthConstraint, detailLabelSize.height+BUBBLE_Y_OFFSET+bubbleSize.height);

}

+ (UITextView *)textView {

    UITextView *uiTextView = [[UITextView alloc] initWithFrame:CGRectZero];

    uiTextView.tag = 2;
    uiTextView.backgroundColor = [UIColor clearColor];
    uiTextView.dataDetectorTypes = UIDataDetectorTypeAll;
    uiTextView.editable = NO;
    uiTextView.scrollEnabled = NO;
    uiTextView.font =  [JMCMessageBubble fontBubble];
    uiTextView.textAlignment= NSTextAlignmentLeft;
    uiTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    return uiTextView;
}

#pragma mark Methods

- (id)initWithReuseIdentifier:(NSString *)cellIdentifierComment {

    if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifierComment])) {

        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.autoresizesSubviews = YES;

        // this is a work-around for self.backgroundColor = [UIColor clearColor]; appearing black on iOS < 4.3 .
//        UIView *transparentBackground = [[UIView alloc] initWithFrame:CGRectZero];
//        transparentBackground.backgroundColor = [UIColor clearColor];
//        self.backgroundView = transparentBackground;

        _bubble = [[UIImageView alloc] initWithFrame:CGRectZero];
        _bubble.clipsToBounds=YES;

        _textView = [JMCMessageBubble textView];


        _detailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _detailLabel.tag = 3;
        _detailLabel.numberOfLines = 1;
        _detailLabel.lineBreakMode = NSLineBreakByClipping;
        _detailLabel.font = [JMCMessageBubble fontDetailLabel];;
        _detailLabel.textColor = [UIColor darkGrayColor];
        _detailLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        _detailLabel.backgroundColor = [UIColor clearColor];
        _detailLabel.textAlignment = NSTextAlignmentCenter;

        [self.contentView addSubview:_detailLabel];
        [self.contentView addSubview:_bubble];
        [self.bubble addSubview:_textView];
        self.contentView.autoresizesSubviews = YES;

    }
    return self;
}

-(void) layoutSubviews
{
    [super layoutSubviews];

    if (self.bubble.frame.origin.x > 0.f) {   // only views that are right justified require relayout.

        // set the correct x coord of the right aligned bubble
        self.bubble.frame = CGRectMake(
                self.contentView.frame.size.width - self.bubble.frame.size.width,
                self.bubble.frame.origin.y,
                self.bubble.frame.size.width,
                self.bubble.frame.size.height);
        [self.bubble layoutSubviews];
    }
}


-(void) setComment:(JMCComment *)comment leftAligned:(BOOL)leftAligned{

    //detailLabel setup
    CGSize detailSize = [JMCMessageBubble detailLabelSizeForComment:comment withWidthConstraint:self.bounds.size.width];
    self.detailLabel.frame = CGRectMake(0.f, 0.f, self.bounds.size.width, detailSize.height);

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    self.detailLabel.text = [dateFormatter stringFromDate:comment.date];


    //bubble setup

    self.textView.text = [comment.body stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    CGFloat fixedWidth = self.bounds.size.width * BUBBLE_WIDTH_RATIO;
    CGSize textSize = [_textView sizeThatFits:CGSizeMake(fixedWidth, MAXFLOAT)];

    float bubbleY = BUBBLE_Y_OFFSET + self.detailLabel.bounds.size.height;
    UIImage *balloon;
    CGRect textFrame, bubbleFrame;


    if (leftAligned) {
        textFrame = CGRectMake(BUBBLE_L_MARGIN_X, 0.f, textSize.width, textSize.height);
        bubbleFrame = CGRectMake(0.f, bubbleY, textFrame.origin.x+ textFrame.size.width+ BUBBLE_R_MARGIN_X, textFrame.size.height);


        balloon = [ [[[UIDevice currentDevice] systemVersion] floatValue] >= 7 ?
                [UIImage imageNamed:@"Balloon_2_ios7"] : [UIImage imageNamed:@"Balloon_2"]
                stretchableImageWithLeftCapWidth:BUBBLE_CAP_WIDTH topCapHeight:BUBBLE_CAP_HEIGHT];
        _bubble.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
    } else {
        textFrame = CGRectMake(BUBBLE_R_MARGIN_X, 0.f, textSize.width, textSize.height);
        bubbleFrame = CGRectMake(2.f, bubbleY, textFrame.origin.x+ textFrame.size.width+ BUBBLE_R_MARGIN_X+ BUBBLE_CAP_WIDTH, textFrame.size.height);
        balloon = [[[[UIDevice currentDevice] systemVersion] floatValue] >= 7 ?
                [UIImage imageNamed:@"Balloon_1_ios7"] : [UIImage imageNamed:@"Balloon_1"]
                stretchableImageWithLeftCapWidth:BUBBLE_CAP_WIDTH topCapHeight:BUBBLE_CAP_HEIGHT];
        _bubble.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    }
    self.bubble.frame = bubbleFrame;
    self.bubble.image = balloon;
    self.textView.frame = textFrame;
}

@end
