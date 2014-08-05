//
//  JMCShape.h
//  AngryNerds2
//
//  Created by Theodora Tse on 12/01/12.
//  Copyright (c) 2012 Nick Pellow. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JMCShapeDrawing <NSObject>

- (void)drawWithContext:(CGContextRef)context;

@end

@interface JMCShape : NSObject <JMCShapeDrawing>

@end