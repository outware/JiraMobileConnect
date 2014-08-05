//
//  LineView.m
//  TouchCircle
//
//  Created by Theodora Tse on 3/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JMCVectorView.h"
#import <QuartzCore/QuartzCore.h>

@implementation VectorView

@synthesize begin;
@synthesize finish;
@synthesize counter;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.opaque = YES;
        self.hidden = NO;
        self.alpha = 1.0;
    }
    return self;
}

- (void)setStartPoint:(CGPoint)start
{
    begin = start;
}

- (void)setEndPoint:(CGPoint)end
{
    finish = end;
    //counter = 100;
}

- (void)drawRect:(CGRect)rect
{
    context = UIGraphicsGetCurrentContext();
    
    // Draw line with a red stroke color
    CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 1.0);
    
    // Draw line with a 4.0 stroke width
    CGContextSetLineWidth(context, 4.0);
    //if (counter != 0) {
        //CGContextBeginPath(context);
        CGContextMoveToPoint(context, begin.x, begin.y);
        CGContextAddLineToPoint(context, finish.x, finish.y);
        CGContextStrokePath(context);
    //}
}

- (void)drawArrow
{
    
}

@end
