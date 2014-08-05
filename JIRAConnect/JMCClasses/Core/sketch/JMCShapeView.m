//
//  JMCShapeView.m
//  AngryNerds2
//
//  Created by Theodora Tse on 12/01/12.
//  Copyright (c) 2012 Nick Pellow. All rights reserved.
//

#import "JMCShapeView.h"


@implementation JMCShapeView

@synthesize shapes, history;

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    ctx = UIGraphicsGetCurrentContext();
    
    for (JMCShape *s in shapes) {
        [s drawWithContext:ctx];
    }
}

- (void)clear
{
    [shapes removeAllObjects];
    [history removeAllObjects];
}

- (void)undo
{
    JMCShape *lastShape = [shapes lastObject];
    if (!lastShape) return;
    if ([shapes count] <= 0) return;
    [history addObject:lastShape];
    [shapes removeLastObject];
}

- (void)redo
{
    if (![history lastObject]) return;
    [shapes addObject:[history lastObject]];
    [history removeLastObject];
}


@end
