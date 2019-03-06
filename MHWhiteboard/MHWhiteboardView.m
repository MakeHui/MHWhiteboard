//
//  MHWhiteboardView.m
//  MHWhiteboard
//
//  Created by MakeHui on 10/1/19.
//  Copyright © 2019年 MakeHui. All rights reserved.
//

#import "MHWhiteboardView.h"

@implementation MHPathModel

+ (instancetype)initWithAction:(MHPathModelAction)action path:(CGPathRef)path lineWidth:(CGFloat)lineWidth color:(UIColor *)color
{
    MHPathModel *pathModel = [MHPathModel new];
    
    pathModel.action = action;
    pathModel.path = [UIBezierPath bezierPathWithCGPath:path];
    pathModel.path.lineWidth = lineWidth;
    pathModel.color = color;
    
    switch (action) {
        case MHPathModelActionLine:
        {
            pathModel.path.lineCapStyle = kCGLineCapRound;
            pathModel.path.lineJoinStyle = kCGLineJoinRound;
        }
            break;
        case MHPathModelActionForegroundImage:
        {
            // pass...
        }
            break;
        case MHPathModelActionBackgroundImage:
        {
            // pass...
        }
            break;
        default:
            break;
    }
    
    return pathModel;
}

+ (instancetype)initWithAction:(MHPathModelAction)action image:(UIImage *)image drawInRect:(CGRect)rect
{
    MHPathModel *pathModel = [MHPathModel new];
    
    pathModel.action = action;
    pathModel.image = image;
    pathModel.drawImageRect = rect;
    
    return pathModel;
}

@end

@implementation MHWhiteboardView
{
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
    self.pathModelAction = MHPathModelActionLine;
    self.brushWidth = 5.0f;
    self.brushColor = [UIColor redColor];
    
    _pathModelArray = [NSMutableArray array];
}

- (void)addPathModelToArray:(MHPathModel *)pathModel
{
    for (int i = 0; i < _pathModelArray.count; ++i) {
        if (_pathModelArray[i].action & MHPathModelActionUndo) {
            [_pathModelArray removeObject:_pathModelArray[i]];
        }
    }
    [_pathModelArray addObject:pathModel];
}

#pragma mark - Draw UI

- (void)drawRect:(CGRect)rect
{
    for (MHPathModel *pathModel in _pathModelArray) {
        if (pathModel.action & MHPathModelActionUndo) continue;
        if (pathModel.action & MHPathModelActionBackgroundImage) {
            [pathModel.image drawInRect:self.bounds];
            break;
        }
    }
    
    for(MHPathModel *pathModel in _pathModelArray) {
        if (pathModel.action & MHPathModelActionUndo) continue;
        
        if (pathModel.action & MHPathModelActionLine ||
            pathModel.action & MHPathModelActionStraightLine) {
            [pathModel.color set];
            [pathModel.path stroke];
        }
//        else if (pathModel.action & MHPathModelActionCircle) {
//
//        }
//        else if (pathModel.action & MHPathModelActionRectangle) {
//
//        }
//        else if (pathModel.action & MHPathModelActionRriangle) {
//
//        }
        else if (pathModel.action & MHPathModelActionForegroundImage) {
            [pathModel.image drawInRect:self.bounds];
        }
        else if (pathModel.action & MHPathModelActionBackgroundImage) {
            // pass..
        }
//        else if (pathModel.action & MHPathModelActionText) {
//
//        }
//        else if (pathModel.action & MHPathModelActionSmear) {
//
//        }
//        else if (pathModel.action & MHPathModelActionMosaic) {
//
//        }
    }

    if (_currentPath) {
        MHPathModel *pathModel = [MHPathModel initWithAction:self.pathModelAction path:_currentPath lineWidth:self.brushWidth color:self.brushColor];
        if (pathModel.action & MHPathModelActionLine ||
            pathModel.action & MHPathModelActionStraightLine) {
            [pathModel.color set];
            [pathModel.path stroke];
        }
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
    
    if (self.pathModelAction & MHPathModelActionStraightLine) {
        CGPoint firstPoint = [[self pathPoints] firstObject].CGPointValue;
        CGPathRelease(_currentPath);
        _currentPath = CGPathCreateMutable();
        CGPathMoveToPoint(_currentPath, NULL, firstPoint.x, firstPoint.y);
    }
    CGPathAddLineToPoint(_currentPath, NULL, location.x, location.y);
    
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    MHPathModel *pathModel = [MHPathModel initWithAction:self.pathModelAction path:_currentPath lineWidth:self.brushWidth color:self.brushColor];
    [self addPathModelToArray:pathModel];
    
    CGPathRelease(_currentPath);
    _currentPath = nil;
    
    [self setNeedsDisplay];
}

#pragma mark - Function

- (void)undo
{
    for (MHPathModel *pathModel in [_pathModelArray reverseObjectEnumerator]) {
        if (! (pathModel.action & MHPathModelActionUndo)) {
            pathModel.action |= MHPathModelActionUndo;
            break;
        }
    }

    [self setNeedsDisplay];
}

- (void)repeat
{
    for (MHPathModel *pathModel in _pathModelArray) {
        if (pathModel.action & MHPathModelActionUndo) {
            pathModel.action ^= MHPathModelActionUndo;
            break;
        }
    }
    
    [self setNeedsDisplay];
}

- (void)clearAll
{
    for (MHPathModel *pathModel in _pathModelArray) {
        pathModel.action |= MHPathModelActionUndo;
    }
    
    [self setNeedsDisplay];
}

- (void)clearBackgroundImage
{
    if (! _pathModelArray.firstObject) return;
    _pathModelArray.firstObject.action |= MHPathModelActionUndo;
    
    [self setNeedsDisplay];
}

- (void)setForegroundImage:(UIImage *)foregroundImage
{
    MHPathModel *pathModel = [MHPathModel initWithAction:MHPathModelActionForegroundImage image:foregroundImage drawInRect:self.bounds];
    [self addPathModelToArray:pathModel];
    
    [self setNeedsDisplay];
}

- (void)setBackgroundImage:(UIImage *)backgroundImage
{
    [self clearBackgroundImage];
    
    MHPathModel *pathModel = [MHPathModel initWithAction:MHPathModelActionBackgroundImage image:backgroundImage drawInRect:self.bounds];
    [self addPathModelToArray:pathModel];
    
    [self setNeedsDisplay];
}

void MyCGPathApplierFunc (void *info, const CGPathElement *element) {
    NSMutableArray *pathPoints = (__bridge NSMutableArray *)info;
    CGPoint *points = element->points;
    CGPathElementType type = element->type;
    
    switch(type) {
        case kCGPathElementMoveToPoint: // contains 1 point
            [pathPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            break;
            
        case kCGPathElementAddLineToPoint: // contains 1 point
            [pathPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            break;
            
        case kCGPathElementAddQuadCurveToPoint: // contains 2 points
            [pathPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            [pathPoints addObject:[NSValue valueWithCGPoint:points[1]]];
            break;
            
        case kCGPathElementAddCurveToPoint: // contains 3 points
            [pathPoints addObject:[NSValue valueWithCGPoint:points[0]]];
            [pathPoints addObject:[NSValue valueWithCGPoint:points[1]]];
            [pathPoints addObject:[NSValue valueWithCGPoint:points[2]]];
            break;
            
        case kCGPathElementCloseSubpath: // contains no point
            break;
    }
}

- (NSArray<NSValue *> *)pathPoints
{
    NSMutableArray *points = [NSMutableArray array];
    CGPathApply(_currentPath, (__bridge void *)(points), MyCGPathApplierFunc);
    return points;
}

@end
