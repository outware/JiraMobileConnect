//
//  LineView.h
//  TouchCircle
//
//  Created by Theodora Tse on 3/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface VectorView : UIView
{
    CGContextRef context;
    CGPoint begin;
    CGPoint finish;
}

@property (assign) CGPoint begin;
@property (assign) CGPoint finish;
@property (assign) int counter;

- (void)setStartPoint:(CGPoint)start;

- (void)setEndPoint:(CGPoint)end;

- (void)drawArrow;

@end
