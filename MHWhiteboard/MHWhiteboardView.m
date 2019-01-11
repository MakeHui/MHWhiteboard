//
//  MHWhiteboardView.m
//  MHWhiteboard
//
//  Created by MakeHui on 10/1/19.
//  Copyright © 2019年 MakeHui. All rights reserved.
//

#import "MHWhiteboardView.h"

@implementation MHPathModel

+ (instancetype)initWithType:(MHPathModelType)type path:(CGPathRef)path lineWidth:(CGFloat)lineWidth color:(UIColor *)color
{
    MHPathModel *pathModel = [MHPathModel new];
    
    pathModel.type = type;
    pathModel.path = [UIBezierPath bezierPathWithCGPath:path];
    pathModel.path.lineWidth = lineWidth;
    pathModel.color = color;
    
    switch (type) {
        case MHPathModelTypeLine:
        {
            pathModel.path.lineCapStyle = kCGLineCapRound;
            pathModel.path.lineJoinStyle = kCGLineJoinRound;
        }
            break;
        case MHPathModelTypeImage:
        {
            // pass...
        }
            break;
        default:
            break;
    }
    
    return pathModel;
}

+ (instancetype)initWithType:(MHPathModelType)type image:(UIImage *)image drawInRect:(CGRect)rect
{
    MHPathModel *pathModel = [MHPathModel new];
    
    pathModel.type = type;
    pathModel.image = image;
    pathModel.drawImageRect = rect;
    
    return pathModel;
}

@end

@implementation MHWhiteboardView
{
    UIImage *_backgroundImage;
    CGMutablePathRef _currentPath;
    NSMutableArray<MHPathModel *> *_pathModelArray;
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
    self.backgroundColor = [UIColor whiteColor];
    self.pathModelType = MHPathModelTypeLine;
    self.brushWidth = 5.0f;
    self.brushColor = [UIColor redColor];
    
    _pathModelArray = [NSMutableArray array];
}

#pragma mark - Draw UI

- (void)drawRect:(CGRect)rect
{
    UIGraphicsGetCurrentContext();
    for(MHPathModel *pathModel in _pathModelArray) {
        switch (pathModel.type) {
            case MHPathModelTypeLine:
            {
                [pathModel.color set];
                [pathModel.path stroke];
            }
                break;
            case MHPathModelTypeImage:
            {
                [pathModel.image drawInRect:self.bounds];
            }
                break;
            default:
                break;
        }
    }
    
    if (_currentPath) {
        MHPathModel *pathModel = [MHPathModel initWithType:self.pathModelType path:_currentPath lineWidth:self.brushWidth color:self.brushColor];
        [pathModel.color set];
        [pathModel.path stroke];
    }
}

#pragma mark - Touches Event

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint location = [touches.anyObject locationInView:self];
    
    _currentPath = CGPathCreateMutable();
    
    CGPathMoveToPoint(_currentPath, NULL, location.x, location.y);
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint location = [touches.anyObject locationInView:self];
    
    CGPathAddLineToPoint(_currentPath, NULL, location.x, location.y);
    
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    MHPathModel *pathModel = [MHPathModel initWithType:self.pathModelType path:_currentPath lineWidth:self.brushWidth color:self.brushColor];
    [_pathModelArray addObject:pathModel];
    
    CGPathRelease(_currentPath);
    _currentPath = nil;
    
    [self setNeedsDisplay];
}

#pragma mark - Function

- (void)undo
{
    [_pathModelArray removeLastObject];
    
    [self setNeedsDisplay];
}

- (void)clearAll
{
    [_pathModelArray removeAllObjects];
    
    [self setNeedsDisplay];
}

- (void)clearBackgroundImage
{
    if (_backgroundImage) {
        [_pathModelArray removeObjectAtIndex:0];
        _backgroundImage = nil;
        [self setNeedsDisplay];
    }
}

- (void)setForegroundImage:(UIImage *)foregroundImage
{
    MHPathModel *pathModel = [MHPathModel initWithType:MHPathModelTypeImage image:foregroundImage drawInRect:self.bounds];
    [_pathModelArray addObject:pathModel];
    
    [self setNeedsDisplay];
}

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
    [self clearBackgroundImage];
    
    _backgroundImage = backgroundImage;
    MHPathModel *pathModel = [MHPathModel initWithType:MHPathModelTypeImage image:backgroundImage drawInRect:self.bounds];
    [_pathModelArray insertObject:pathModel atIndex:0];
    
    [self setNeedsDisplay];
}

@end
