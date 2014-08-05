//
//  JMCVector.m
//  AngryNerds2
//
//  Created by Theodora Tse on 12/01/12.
//  Copyright (c) 2012 Nick Pellow. All rights reserved.
//

#import "JMCVector.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

@implementation JMCVector

@synthesize ctx;
@synthesize points;

- (id)init
{
    self = [super init];
    if (self) {
        points = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)drawWithContext:(CGContextRef)context
{
    [self visitPoints];
    
    [self findArrowHeadPoints];
    [self findArrowBodyPoints];
    
    CGContextSetLineWidth(context, 4.0);

    CGContextSetRGBStrokeColor(context, 1.0, 0.0, 0.0, 0.6);
    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 0.4);
    
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, lastPoint.x, lastPoint.y);
    CGContextAddLineToPoint(context, leftPoint.x, leftPoint.y);
    CGContextAddLineToPoint(context, b.x, b.y);
    CGContextAddLineToPoint(context, firstPoint.x, firstPoint.y);
    CGContextAddLineToPoint(context, a.x, a.y);
    CGContextAddLineToPoint(context, rightPoint.x, rightPoint.y);
    CGContextAddLineToPoint(context, lastPoint.x, lastPoint.y);
    
    CGContextDrawPath(context, kCGPathFillStroke);
}

- (void)addPoint:(CGPoint)point
{
    [points addObject:[NSValue valueWithCGPoint:point]];
}

- (void)visitPoints
{
    for (JMCVector *vector in points) {
        firstValue = [points objectAtIndex:0];
        firstPoint = [firstValue CGPointValue];
        
        int i = [points count];
        lastValue = [points objectAtIndex:i - 1];
        lastPoint = [lastValue CGPointValue];
    }
}

- (void)extendPoint
{
    firstValue = [points objectAtIndex:0];
    firstPoint = [firstValue CGPointValue];
    lastValue = [points lastObject];
    lastPoint = [lastValue CGPointValue];
    
    gradient = (lastPoint.y - firstPoint.y) / (lastPoint.x - firstPoint.x);
    
    magnitude = sqrtf(1 + gradient * gradient);
    
    n.x = 1 / magnitude;
    n.y = gradient / magnitude;
    
    [self lengthOfArrowHead];
    
    if (firstPoint.x == lastPoint.x) {
        extend.x = lastPoint.x;
        if (lastPoint.y < firstPoint.y) {
            extend.y = lastPoint.y + length;
        } else {
            extend.y = lastPoint.y - length;
        }
    } else {
        extend.x = lastPoint.x + length * n.x;
        extend.y = lastPoint.y + length * n.y;
    }
}

- (void)lengthOfArrowHead
{
    CGFloat x = lastPoint.x - firstPoint.x;
    CGFloat y = lastPoint.y - firstPoint.y;
    
    length = sqrtf((x * x) + (y * y));
    
    length = length / 4;
}

- (void)calculateAngle
{
    angle = atan2f(-(lastPoint.y - firstPoint.y), lastPoint.x - firstPoint.x);
    
    leftAngle = - (M_PI_4 / 2);
    rightAngle = (M_PI_4 / 2);
}

// http://stackoverflow.com/questions/7440900/function-to-rotate-a-point-around-another-point
- (CGPoint)rotatePoint:(CGPoint)point with:(float)radian at:(CGPoint)origin
{
    float s = sinf(radian);
    float c = cosf(radian);
    
    
    point.x -= origin.x;
    point.y -= origin.y;
    
    CGPoint new;
    new.x = point.x * c - point.y * s;
    new.y = point.x * s + point.y * c;
    
    CGPoint rotate;
    rotate.x = new.x + lastPoint.x;
    rotate.y = new.y + lastPoint.y;
    
    return rotate;
}

- (void)findArrowHeadPoints
{
    [self extendPoint];
    [self calculateAngle];
    
    if ((angle > -M_PI && angle < -M_PI_2) || (angle <= M_PI && angle > M_PI_2)) {
        leftPoint = [self rotatePoint:extend with:leftAngle at:lastPoint];
        rightPoint = [self rotatePoint:extend with:rightAngle at:lastPoint];
    } else {
        // arrow head points in opposite direction so adjust it by flipping it
        leftPoint = [self rotatePoint:extend with:leftAngle - M_PI at:lastPoint];
        rightPoint = [self rotatePoint:extend with:rightAngle + M_PI at:lastPoint];
    }
}

- (void)findArrowBodyPoints
{
    // use internal division of line segment
    float k = 0.3;
    float j = 0.7;
    
    a.x = k * leftPoint.x + j * rightPoint.x;
    a.y = k * leftPoint.y + j * rightPoint.y;
    
    b.x = j * leftPoint.x + k * rightPoint.x;
    b.y = j * leftPoint.y + k * rightPoint.y;
}


@end
