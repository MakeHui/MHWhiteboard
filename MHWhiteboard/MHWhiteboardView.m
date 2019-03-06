//
//  MHWhiteboardView.m
//  MHWhiteboard
//
//  Created by MakeHui on 10/1/19.
//  Copyright © 2019年 MakeHui. All rights reserved.
//

#import "MHWhiteboardView.h"

@implementation MHPathModel

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

+ (NSArray<NSValue *> *)pathPointsWithCGPath:(CGPathRef)path
{
    NSMutableArray *points = [NSMutableArray array];
    CGPathApply(path, (__bridge void *)(points), MyCGPathApplierFunc);
    return points;
}

+ (CGFloat)distance:(CGPoint)point point:(CGPoint)point2
{
    CGFloat xDist = point.x - point2.x;
    CGFloat yDist = point.y - point2.y;
    return sqrt(xDist * xDist + yDist * yDist);
}

+ (instancetype)initWithAction:(MHPathModelAction)action path:(CGPathRef)path lineWidth:(CGFloat)lineWidth color:(UIColor *)color sides:(NSUInteger)sides
{
    MHPathModel *pathModel = [MHPathModel new];
    
    pathModel.action = action;
    pathModel.color = color;
    
    if (action & MHPathModelActionLine ||
        action & MHPathModelActionStraightLine) {
        pathModel.path = [UIBezierPath bezierPathWithCGPath:path];
        pathModel.path.lineWidth = lineWidth;
        pathModel.path.lineCapStyle = kCGLineCapRound;
        pathModel.path.lineJoinStyle = kCGLineJoinRound;
    }
    else if (action & MHPathModelActionCircle) {
        NSArray<NSValue *> *pathPoints = [self.class pathPointsWithCGPath:path];
        
        CGPoint firstPoint = pathPoints.firstObject.CGPointValue;
        CGPoint lastPoint = pathPoints.lastObject.CGPointValue;
        
        CGPoint arcCenter = CGPointMake((firstPoint.x + lastPoint.x) / 2, (firstPoint.y + lastPoint.y) / 2);
        CGFloat radius = [MHPathModel distance:firstPoint point:lastPoint] / 2;
        
        pathModel.path = [UIBezierPath bezierPathWithArcCenter:arcCenter radius:radius startAngle:0 endAngle:120 clockwise:YES];
        pathModel.path.lineWidth = lineWidth;
        pathModel.path.lineCapStyle = kCGLineCapRound;
        pathModel.path.lineJoinStyle = kCGLineJoinRound;
    }
    else if (action & MHPathModelActionRectangle) {
        NSArray<NSValue *> *pathPoints = [self.class pathPointsWithCGPath:path];
        
        CGPoint firstPoint = pathPoints.firstObject.CGPointValue;
        CGPoint lastPoint = pathPoints.lastObject.CGPointValue;
        
        pathModel.path = [UIBezierPath bezierPathWithRect:CGRectMake(firstPoint.x, firstPoint.y, lastPoint.x - firstPoint.x, lastPoint.y - firstPoint.y)];
        pathModel.path.lineWidth = lineWidth;
        pathModel.path.lineCapStyle = kCGLineCapRound;
        pathModel.path.lineJoinStyle = kCGLineJoinRound;
    }
    else if (action & MHPathModelActionPolygon) {
        NSArray<NSValue *> *pathPoints = [self.class pathPointsWithCGPath:path];
        
        CGPoint firstPoint = pathPoints.firstObject.CGPointValue;
        CGPoint lastPoint = pathPoints.lastObject.CGPointValue;
        
        // Code from: https://stackoverflow.com/revisions/24770675/7
        pathModel.path = [UIBezierPath bezierPath];
        
        CGRect rect = CGRectMake(firstPoint.x, firstPoint.y, lastPoint.x - firstPoint.x, lastPoint.y - firstPoint.y);
        
        CGFloat theta       = 2.0 * M_PI / sides;
        CGFloat squareWidth = MAX(rect.size.width, rect.size.height);
        
        CGFloat length      = squareWidth - lineWidth;
        if (sides % 4 != 0) {
            length = length * cosf(theta / 2.0);
        }
        CGFloat sideLength = length * tanf(theta / 2.0);
        
        CGPoint point = CGPointMake(rect.origin.x + rect.size.width / 2.0 + sideLength / 2.0, rect.origin.y + rect.size.height / 2.0 + length / 2.0);
        CGFloat angle = M_PI;
        [pathModel.path moveToPoint:point];
        
        for (NSInteger side = 0; side < sides; side++) {
            point = CGPointMake(point.x + (sideLength) * cosf(angle), point.y + (sideLength) * sinf(angle));
            [pathModel.path addLineToPoint:point];
            angle += theta;
        }
        
        pathModel.path.lineWidth = lineWidth;
        pathModel.path.lineCapStyle = kCGLineCapRound;
        pathModel.path.lineJoinStyle = kCGLineJoinRound;
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
    self.sides = 6;
    
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
            pathModel.action & MHPathModelActionStraightLine ||
            pathModel.action & MHPathModelActionCircle ||
            pathModel.action & MHPathModelActionRectangle ||
            pathModel.action & MHPathModelActionPolygon) {
            [pathModel.color set];
            [pathModel.path stroke];
        }
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
        MHPathModel *pathModel = [MHPathModel initWithAction:self.pathModelAction path:_currentPath lineWidth:self.brushWidth color:self.brushColor sides:self.sides];
        
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
    
    if (self.pathModelAction & MHPathModelActionStraightLine ||
        self.pathModelAction & MHPathModelActionCircle ||
        self.pathModelAction & MHPathModelActionRectangle ||
        self.pathModelAction & MHPathModelActionPolygon) {
        CGPoint firstPoint = [[MHPathModel pathPointsWithCGPath:_currentPath] firstObject].CGPointValue;
        CGPathRelease(_currentPath);
        _currentPath = CGPathCreateMutable();
        CGPathMoveToPoint(_currentPath, NULL, firstPoint.x, firstPoint.y);
    }
    
    CGPathAddLineToPoint(_currentPath, NULL, location.x, location.y);
    
    [self setNeedsDisplay];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    MHPathModel *pathModel = [MHPathModel initWithAction:self.pathModelAction path:_currentPath lineWidth:self.brushWidth color:self.brushColor sides:self.sides];
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

@end
