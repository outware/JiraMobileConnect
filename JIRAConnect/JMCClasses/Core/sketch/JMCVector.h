//
//  JMCVector.h
//  AngryNerds2
//
//  Created by Theodora Tse on 12/01/12.
//  Copyright (c) 2012 Nick Pellow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JMCShape.h"

@interface JMCVector : NSObject <JMCShapeDrawing> {
    NSMutableArray *points;
    
    NSValue *firstValue;
    CGPoint firstPoint;
    NSValue *lastValue;
    CGPoint lastPoint;
    CGFloat gradient;
    CGFloat magnitude;
    CGPoint n;
    CGPoint extend;
    
    CGFloat length;
    
    CGFloat angle;
    CGFloat leftAngle;
    CGFloat rightAngle;
    
    CGPoint leftPoint;
    CGPoint rightPoint;
    
    CGPoint a;
    CGPoint b;
}

@property (nonatomic) CGContextRef ctx;
@property (nonatomic, strong) NSMutableArray *points;

- (void)addPoint:(CGPoint)point;
- (void)visitPoints;

- (void)extendPoint;
- (void)lengthOfArrowHead;
- (void)calculateAngle;
- (CGPoint)rotatePoint:(CGPoint)point with:(float)radian at:(CGPoint)origin;
- (void)findArrowHeadPoints;
- (void)findArrowBodyPoints;

@end
