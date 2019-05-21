//
//  MHWhiteboardView.m
//  MHWhiteboard
//
//  Created by MakeHui on 10/1/19.
//  Copyright © 2019年 MakeHui. All rights reserved.
//

#import "MHWhiteboardView.h"
#import "MHDrawView.h"
#import "MHPathModel.h"

#define MHGetImage(imageName)  ([UIImage imageNamed:[@"Frameworks/MHWhiteboard.framework/MHWhiteboard.bundle" stringByAppendingPathComponent:imageName]] ?: [UIImage imageNamed:[@"MHWhiteboard.bundle" stringByAppendingPathComponent:imageName]])

@interface MHWhiteboardView ()<UITextFieldDelegate>

@end

@implementation MHWhiteboardView
{
    UIImageView *_backgroundImageView;
    MHDrawView *_drawView;
    UITextField *_textField;
    UIImageView *_selectedImageView;
    NSMutableArray<UIImageView *> *_insertImageViewArray;
    
    CGMutablePathRef _currentPath;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self customInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self customInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self customInit];
    }
    return self;
}

- (void)customInit
{
    _backgroundImageContentMode = UIViewContentModeScaleAspectFill;
    
    _backgroundImageView = ({
        UIImageView *backgroundImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 10, 100)];
        backgroundImageView.contentMode = self.backgroundImageContentMode;
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false;
        
        [self addSubview:backgroundImageView];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[subview]-0-|"
                                                                     options:NSLayoutFormatAlignAllTrailing
                                                                     metrics:nil
                                                                       views:@{ @"subview": backgroundImageView }]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[subview]-0-|"
                                                                     options:NSLayoutFormatAlignAllTrailing
                                                                     metrics:nil
                                                                       views:@{ @"subview": backgroundImageView }]];
        
        backgroundImageView;
    });
    
    _drawView = ({
        MHDrawView *drawView = [MHDrawView new];
        drawView.backgroundColor = UIColor.clearColor;
        drawView.translatesAutoresizingMaskIntoConstraints = false;
        
        [self addSubview:drawView];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[subview]-0-|"
                                                                     options:NSLayoutFormatAlignAllTrailing
                                                                     metrics:nil
                                                                       views:@{ @"subview": drawView }]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[subview]-0-|"
                                                                     options:NSLayoutFormatAlignAllTrailing
                                                                     metrics:nil
                                                                       views:@{ @"subview": drawView }]];
        
        drawView;
    });
    
    _selectedImageView = ({
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveViewWithGestureRecognizer:)];
        UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchWithGestureRecognizer:)];
        UIRotationGestureRecognizer *rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotationWithGestureRecognizer:)];
        UIImageView *selectedImageView = [[UIImageView alloc] init];
        selectedImageView.userInteractionEnabled = true;
        selectedImageView.hidden = true;
        [selectedImageView addGestureRecognizer:panGestureRecognizer];
        [selectedImageView addGestureRecognizer:pinchGestureRecognizer];
        [selectedImageView addGestureRecognizer:rotationGestureRecognizer];
        
        UIImageView *borderView = [[UIImageView alloc] initWithImage:MHGetImage(@"border.png")];
        borderView.layer.shadowOpacity = 0.5;
        borderView.layer.shadowColor = [UIColor grayColor].CGColor;
        borderView.layer.shadowRadius = 3;
        borderView.layer.shadowOffset = CGSizeMake(1, 1);
        
        [selectedImageView addSubview:borderView];
        [self addSubview:selectedImageView];
        
        selectedImageView;
    });
    
    _insertImageViewArray = @[].mutableCopy;
}

#pragma mark - Touches Event

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    
    if (self.pathModelAction & MHPathModelActionInsertImage) {
        if (_selectedImageView.image && CGRectContainsPoint(_selectedImageView.frame, point)) {
            return _selectedImageView;
        }
        
        return self;
    }

    return view;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint location = [touches.anyObject locationInView:self];
    
    if (!(self.pathModelAction & MHPathModelActionInsertImage) ||
        (_selectedImageView.image &&
         CGRectContainsPoint(_selectedImageView.frame, location))) {
        return;
    }
    
    for (NSInteger i = _insertImageViewArray.count - 1; i >= 0; --i) {
        UIImageView *imageView = _insertImageViewArray[i];
        
        if (!CGRectContainsPoint(imageView.frame, location)) { continue; }
        if (_selectedImageView.image == imageView.image) { continue; }
        
        [_insertImageViewArray removeObjectAtIndex:i];
        [imageView removeFromSuperview];
        [self addImageViewToInsertImageViewArray];
        [self insertImageWithImageView:imageView];
        
        return;
    }
    
    [self addImageViewToInsertImageViewArray];
}

#pragma mark - UIGestureRecognizer

- (void)moveViewWithGestureRecognizer:(UIPanGestureRecognizer *)panGestureRecognizer
{
    CGPoint location = [panGestureRecognizer locationInView:self];
    if (location.y < 0 || location.y > self.bounds.size.height) {
        return;
    }
    
    CGPoint translation = [panGestureRecognizer translationInView:self];
    panGestureRecognizer.view.center = CGPointMake(panGestureRecognizer.view.center.x + translation.x, panGestureRecognizer.view.center.y + translation.y);
    
    [panGestureRecognizer setTranslation:CGPointZero inView:self];
}

- (void)handlePinchWithGestureRecognizer:(UIPinchGestureRecognizer *)pinchGestureRecognizer
{
    pinchGestureRecognizer.view.transform = CGAffineTransformScale(pinchGestureRecognizer.view.transform, pinchGestureRecognizer.scale, pinchGestureRecognizer.scale);
    pinchGestureRecognizer.scale = 1.0;
}

- (void)handleRotationWithGestureRecognizer:(UIRotationGestureRecognizer *)rotationGestureRecognizer
{
    rotationGestureRecognizer.view.transform = CGAffineTransformRotate(rotationGestureRecognizer.view.transform, rotationGestureRecognizer.rotation);
    rotationGestureRecognizer.rotation = 0.0;
}

#pragma mark - Getter, Setter

- (MHPathModelAction)pathModelAction
{
    return _drawView.pathModelAction;
}

- (void)setPathModelAction:(MHPathModelAction)pathModelAction
{
    _drawView.pathModelAction = pathModelAction;
    
    [self addImageViewToInsertImageViewArray];
}

- (CGFloat)brushWidth
{
    return _drawView.brushWidth;
}

- (void)setBrushWidth:(CGFloat)brushWidth
{
    _drawView.brushWidth = brushWidth;
}

- (UIColor *)brushColor
{
    return _drawView.brushColor;
}

- (void)setBrushColor:(UIColor *)brushColor
{
    _drawView.brushColor = brushColor;
}

- (NSUInteger)polygonSides
{
    return _drawView.polygonSides;
}

- (void)setPolygonSides:(NSUInteger)polygonSides
{
    _drawView.polygonSides = polygonSides;
}

- (UIFont *)textFont
{
    return _drawView.textFont;
}

- (void)setTextFont:(UIFont *)textFont
{
    _drawView.textFont = textFont;
}

#pragma mark - Function

- (void)undo
{
    [_drawView undo];
}

- (void)repeat
{
    [_drawView repeat];
}

- (void)clearAll
{
    [self addImageViewToInsertImageViewArray];
    for (UIView *view in _insertImageViewArray) {
        [view removeFromSuperview];
    }
    [_insertImageViewArray removeAllObjects];
    [_drawView clearAll];
    [self clearBackgroundImage];
}

- (void)insertImage:(UIImage *)image
{
    CGSize size = CGSizeMake(150, image.size.height / image.size.width * 150);
    CGRect rect = CGRectMake((self.bounds.size.width - 155) / 2, (self.bounds.size.height - size.height) / 2, size.width, size.height);
    
    self.pathModelAction = MHPathModelActionInsertImage;
    _selectedImageView.image = image;
    _selectedImageView.frame = rect;
    _selectedImageView.subviews.firstObject.frame = _selectedImageView.bounds;
    _selectedImageView.hidden = false;
    [self bringSubviewToFront:_selectedImageView];
}

- (void)insertImageWithImageView:(UIImageView *)imageView
{
    _selectedImageView.center = imageView.center;
    _selectedImageView.bounds = imageView.bounds;
    _selectedImageView.transform = imageView.transform;
    _selectedImageView.image = imageView.image;
    _selectedImageView.hidden = false;
    [self bringSubviewToFront:_selectedImageView];
}

- (void)addImageViewToInsertImageViewArray
{
    if (_selectedImageView.image) {
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.center = _selectedImageView.center;
        imageView.bounds = _selectedImageView.bounds;
        imageView.transform = _selectedImageView.transform;
        imageView.image = _selectedImageView.image;
        
        [self addSubview:imageView];
        
        [_insertImageViewArray addObject:imageView];
        [_selectedImageView setImage:nil];
        _selectedImageView.transform = CGAffineTransformIdentity;
        _selectedImageView.hidden = true;
    }
}

- (void)setBackgroundImage:(UIImage *)image
{
    [self addImageViewToInsertImageViewArray];
    [self clearBackgroundImage];
    _backgroundImageView.image = image;
}

- (void)clearBackgroundImage
{
    _backgroundImageView.image = nil;
}

@end
