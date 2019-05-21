//
//  MHPathModel.m
//  MHWhiteboard
//
//  Created by MakeHui on 21/5/2019.
//  Copyright © 2019 MakeHui. All rights reserved.
//

#import "MHPathModel.h"


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

+ (instancetype)pathModelWithAction:(MHPathModelAction)action path:(CGPathRef)path lineWidth:(CGFloat)lineWidth color:(UIColor *)color
{
    return [MHPathModel pathModelWithAction:action path:path lineWidth:lineWidth color:color sides:0];
}

+ (instancetype)pathModelWithAction:(MHPathModelAction)action path:(CGPathRef)path lineWidth:(CGFloat)lineWidth color:(UIColor *)color sides:(NSUInteger)sides
{
    MHPathModel *pathModel = [MHPathModel new];
    
    pathModel.action = action;
    pathModel.color = color;
    
    if (action & MHPathModelActionLine ||
        action & MHPathModelActionStraightLine) {
        pathModel.path = [UIBezierPath bezierPathWithCGPath:path];
    }
    else if (action & MHPathModelActionCircle) {
        NSArray<NSValue *> *pathPoints = [self.class pathPointsWithCGPath:path];
        
        CGPoint firstPoint = pathPoints.firstObject.CGPointValue;
        CGPoint lastPoint = pathPoints.lastObject.CGPointValue;
        
        CGPoint arcCenter = CGPointMake((firstPoint.x + lastPoint.x) / 2, (firstPoint.y + lastPoint.y) / 2);
        CGFloat radius = [MHPathModel distance:firstPoint point:lastPoint] / 2;
        
        pathModel.path = [UIBezierPath bezierPathWithArcCenter:arcCenter radius:radius startAngle:0 endAngle:120 clockwise:YES];
    }
    else if (action & MHPathModelActionRectangle) {
        NSArray<NSValue *> *pathPoints = [self.class pathPointsWithCGPath:path];
        
        CGPoint firstPoint = pathPoints.firstObject.CGPointValue;
        CGPoint lastPoint = pathPoints.lastObject.CGPointValue;
        
        pathModel.path = [UIBezierPath bezierPathWithRect:CGRectMake(firstPoint.x, firstPoint.y, lastPoint.x - firstPoint.x, lastPoint.y - firstPoint.y)];
    }
    else if (action & MHPathModelActionPolygon) {
        NSArray<NSValue *> *pathPoints = [self.class pathPointsWithCGPath:path];
        
        CGPoint firstPoint = pathPoints.firstObject.CGPointValue;
        CGPoint lastPoint = pathPoints.lastObject.CGPointValue;
        
        // Code from: https://stackoverflow.com/revisions/24770675/7
        pathModel.path = [UIBezierPath bezierPath];
        CGRect rect = CGRectMake(MIN(firstPoint.x, lastPoint.x), MIN(firstPoint.y, lastPoint.y), fabs(lastPoint.x - firstPoint.x), fabs(lastPoint.y - firstPoint.y));
        
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
    }
    
    pathModel.path.lineWidth = lineWidth;
    pathModel.path.lineCapStyle = kCGLineCapRound;
    pathModel.path.lineJoinStyle = kCGLineJoinRound;
    
    return pathModel;
}

+ (instancetype)pathModelWithAction:(MHPathModelAction)action path:(CGPathRef)path text:(NSString *)text color:(UIColor *)color font:(UIFont *)font
{
    MHPathModel *pathModel = [MHPathModel new];
    
    pathModel.action = action;
    pathModel.text = text;
    pathModel.color = color;
    pathModel.path = [UIBezierPath bezierPathWithCGPath:path];
    pathModel.font = font ?: [UIFont systemFontOfSize:24];
    
    return pathModel;
}

@end

