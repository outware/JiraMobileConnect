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
#import "JMCSketchViewController.h"
#import "JMC.h"

#define kAnimationKey @"transitionViewAnimation"

@implementation JMCSketchViewController
@synthesize scrollView = _scrollView, delegate = _delegate, imageId = _imageId;
@synthesize image = _image, mainView = _mainView, toolbar = _toolbar;
@synthesize shapeView;


- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
    UIBarButtonItem *undo = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemUndo target:self action:@selector(undoAction:)] ;
    UIBarButtonItem *redo = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRedo target:self action:@selector(redoAction:)];
    UIBarButtonItem *trash = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteAction:)];
    UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    self.toolbar.translucent = YES;
    self.toolbar.barStyle = UIBarStyleBlackTranslucent;
    [self.toolbar setItems:[NSArray arrayWithObjects:trash, space, undo, redo, done, nil]];
    
    
    [self.scrollView setCanCancelContentTouches:NO];
    self.scrollView.clipsToBounds = YES;    // default is NO, we want to restrict drawing within our scrollview
    self.scrollView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
    self.scrollView.maximumZoomScale = 8.0;
    self.scrollView.minimumZoomScale = self.view.frame.size.width/self.image.size.width;
    self.scrollView.delaysContentTouches = YES;
    self.scrollView.scrollEnabled = YES;
    
    // make sketchView proportional to image
    double scale = 1.0;// self.view.frame.size.width/self.image.size.width;
    CGSize sketchSize = CGSizeMake((CGFloat) (scale * self.image.size.width), (CGFloat) (scale * self.image.size.height));
    
    // if width > height, then center the image in the middle of the view?
    
    JMCShapeView * shapeViewTmp = [[JMCShapeView alloc] initWithFrame:CGRectMake(0, 0, sketchSize.width, sketchSize.height)];
    self.shapeView = shapeViewTmp;
    
    self.shapeView.backgroundColor = [UIColor clearColor];
    NSMutableArray* shapes = [[NSMutableArray alloc] init];
    self.shapeView.shapes = shapes;
    NSMutableArray* history = [[NSMutableArray alloc] init];
    self.shapeView.history = history;
    
    UIImageView* imageView = [[UIImageView alloc] initWithImage:self.image];
    
    JMCSketchContainerView * container = [[JMCSketchContainerView alloc] initWithFrame:shapeView.frame];
    self.mainView = container;
    [self.mainView addSubview:imageView];
    [self.mainView addSubview:self.shapeView];
    [self.scrollView addSubview:self.mainView];
    
    
    // a swipe to draw a line
    UIPanGestureRecognizer *swipe = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(triggerVector:)];
    [swipe setMaximumNumberOfTouches:1];
    [self.mainView addGestureRecognizer:swipe];
    
    // a double tap to enable pan and zoom
    UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    [doubleTap setNumberOfTapsRequired:2];
    [self.mainView addGestureRecognizer:doubleTap];
    
}

-(void) viewDidAppear:(BOOL)animated
{
    [self.scrollView setZoomScale:self.scrollView.minimumZoomScale animated:YES];
    
}
- (void)viewWillAppear:(BOOL)animated {
    
    [self.scrollView setScrollEnabled:YES];
    [self.scrollView setContentOffset:CGPointMake(0, 0)];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scView {
    
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scView {
    
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scView withView:(UIView *)view atScale:(float)scale {
    
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    CGFloat offsetX = (scrollView.bounds.size.width > scrollView.contentSize.width)? 
    (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0;
    CGFloat offsetY = (scrollView.bounds.size.height > scrollView.contentSize.height)? 
    (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0;
    self.mainView.center = CGPointMake(scrollView.contentSize.width * 0.5 + offsetX, 
                                       scrollView.contentSize.height * 0.5 + offsetY);
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scView {
    // this needs to be wrapped.
    return self.mainView;
}
#pragma mark end

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}


- (void)redoAction:(id)sender {
    [self.shapeView redo];
    [self.shapeView setNeedsDisplay];
}

- (void)undoAction:(id)sender {
    [self.shapeView undo];
    [self.shapeView setNeedsDisplay];
}

- (IBAction)deleteAction:(id)sender {
    [self.delegate sketchController:self didDeleteImageWithId:self.imageId];
}

- (IBAction)doneAction:(id)sender {
    UIImage *image = [self createImageScaledBy:1];
    [self.delegate sketchController:self didFinishSketchingImage:image withId:self.imageId];
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

- (void)triggerVector:(UIPanGestureRecognizer *)trigger
{
    
    if ([trigger state] == UIGestureRecognizerStateBegan) {
        vector = [[JMCVector alloc] init];
        [self.shapeView.shapes addObject:vector];
        CGPoint start = [trigger locationInView:self.shapeView];
        [vector addPoint:start];
    } else if ([trigger state] == UIGestureRecognizerStateEnded || [trigger state] == UIGestureRecognizerStateChanged) {
        CGPoint end = [trigger locationInView:self.shapeView];
        [vector addPoint:end];
    }
    [self.shapeView setNeedsDisplay];
    
}

- (void)disableZoom:(UITapGestureRecognizer *)singleTap
{    
    if ([self.mainView.superview respondsToSelector:@selector(setScrollEnabled:)]) {
        [(UIScrollView *)self.mainView.superview setScrollEnabled:NO];
    }
}

- (void)doubleTap:(UITapGestureRecognizer *)doubleTap
{
    CGPoint point = [doubleTap locationInView:self.mainView];
    [self.mainView zoom:point];
}

- (UIImage *)createImageScaledBy:(float)dx {
    CGRect rect = self.mainView.bounds;
    UIGraphicsBeginImageContext(rect.size);
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), dx, dx);
    CGContextSetRGBFillColor(UIGraphicsGetCurrentContext(), 0, 0, 0, 1);
    CGContextFillRect(UIGraphicsGetCurrentContext(), rect);
    [self.image drawInRect:rect];
    [self.shapeView drawRect:rect];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
