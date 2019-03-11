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

+ (instancetype)initWithAction:(MHPathModelAction)action image:(UIImage *)image drawInRect:(CGRect)rect
{
    MHPathModel *pathModel = [MHPathModel new];
    
    pathModel.action = action;
    pathModel.image = image;
    pathModel.drawImageRect = rect;
    
    return pathModel;
}

+ (instancetype)initWithAction:(MHPathModelAction)action path:(CGPathRef)path text:(NSString *)text color:(UIColor *)color font:(UIFont *)font
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

@interface MHWhiteboardView ()<UITextFieldDelegate>

@end

@implementation MHWhiteboardView
{
    UITextField *_textField;
    UIImageView *_selectedImageView;
    
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
    self.textFont = [UIFont systemFontOfSize:24];
    
    _pathModelArray = [NSMutableArray array];
    
    _selectedImageView = ({
        UIPanGestureRecognizer *panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveViewWithGestureRecognizer:)];
        UIPinchGestureRecognizer *pinchGestureRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchWithGestureRecognizer:)];
//        UIRotationGestureRecognizer *rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotationWithGestureRecognizer:)];
        _selectedImageView = [[UIImageView alloc] init];
        _selectedImageView.userInteractionEnabled = true;
        _selectedImageView.layer.borderColor = [UIColor grayColor].CGColor;
        _selectedImageView.layer.borderWidth = 1.0;
        [_selectedImageView addGestureRecognizer:panGestureRecognizer];
        [_selectedImageView addGestureRecognizer:pinchGestureRecognizer];
//        [_selectedImageView addGestureRecognizer:rotationGestureRecognizer];
        _selectedImageView;
    });
    
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
        else if (pathModel.action & MHPathModelActionInsertImage) {
            [pathModel.image drawInRect:pathModel.drawImageRect];
        }
        else if (pathModel.action & MHPathModelActionText) {
            NSDictionary *attributes = @{NSForegroundColorAttributeName: pathModel.color, NSFontAttributeName: pathModel.font};
            NSAttributedString *text=[[NSAttributedString alloc] initWithString:pathModel.text attributes:attributes];
            NSArray<NSValue *> *pathPoints = [MHPathModel pathPointsWithCGPath:pathModel.path.CGPath];
            CGPoint point = pathPoints.firstObject.CGPointValue;
            
            [text drawAtPoint:point];
        }
//        else if (pathModel.action & MHPathModelActionSmear) {
//
//        }
//        else if (pathModel.action & MHPathModelActionMosaic) {
//
//        }
    }

    if (_currentPath) {
        if (self.pathModelAction & MHPathModelActionText) { return; }
        
        MHPathModel *pathModel = [MHPathModel initWithAction:self.pathModelAction path:_currentPath lineWidth:self.brushWidth color:self.brushColor sides:self.sides];
        
        [pathModel.color set];
        [pathModel.path stroke];
    }
}

#pragma mark - Touches Event

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    CGPoint location = [touches.anyObject locationInView:self];
    
    if (self.pathModelAction & MHPathModelActionInsertImage) {
        if (CGRectContainsPoint(_selectedImageView.frame, location)) {
            return;
        }
        for (NSInteger i = _pathModelArray.count - 1; i >= 0; --i) {
            MHPathModel *pathModel = _pathModelArray[i];
            if (pathModel.action & MHPathModelActionInsertImage && CGRectContainsPoint(pathModel.drawImageRect, location)) {
                if (_selectedImageView.image != pathModel.image) {
                    [_pathModelArray removeObjectAtIndex:i];
                    [self insertImage:pathModel.image rect:pathModel.drawImageRect];
                }
                break;
            }
        }
        return;
    }
    
    _currentPath = CGPathCreateMutable();
    
    CGPathMoveToPoint(_currentPath, NULL, location.x, location.y);
    
    if (self.pathModelAction & MHPathModelActionText) {
        if (_textField) { [_textField removeFromSuperview]; }
        
        static const CGFloat rightMargin = 8.0f;
        static const CGFloat topMargin = 4.0f;
        static const CGFloat bottomMargin = 4.0f;
        static const CGFloat innerMargin = 7.0f;
        
        CGSize textSize = [[NSAttributedString alloc] initWithString:@"文字-words" attributes: @{NSFontAttributeName: self.textFont}].size;
        _textField = [[UITextField alloc] initWithFrame:CGRectMake(location.x - innerMargin, location.y - topMargin, self.frame.size.width - location.x - rightMargin, textSize.height + topMargin + bottomMargin)];
        _textField.borderStyle = UITextBorderStyleRoundedRect;
        _textField.delegate = self;
        _textField.font = self.textFont;
        [_textField becomeFirstResponder];
        
        [self addSubview:_textField];
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    if (self.pathModelAction & MHPathModelActionInsertImage) { return; }
    if (self.pathModelAction & MHPathModelActionText) { return; }
    
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
    if (self.pathModelAction & MHPathModelActionInsertImage) { return; }
    if (self.pathModelAction & MHPathModelActionText) { return; }
    
    MHPathModel *pathModel = [MHPathModel initWithAction:self.pathModelAction path:_currentPath lineWidth:self.brushWidth color:self.brushColor sides:self.sides];
    [self addPathModelToArray:pathModel];
    
    CGPathRelease(_currentPath);
    _currentPath = nil;
    
    [self setNeedsDisplay];
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

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    if (textField.text.length) {
        MHPathModel *pathModel = [MHPathModel initWithAction:self.pathModelAction path:_currentPath text:textField.text color:self.brushColor font:self.textFont];
        [self addPathModelToArray:pathModel];
    }
    
    CGPathRelease(_currentPath);
    _currentPath = nil;
    
    [textField removeFromSuperview];
    [self setNeedsDisplay];
    
    return true;
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

- (void)insertImage:(UIImage *)image rect:(CGRect)rect
{
    self.pathModelAction = MHPathModelActionInsertImage;
    [self setInsertImage];
    _selectedImageView.image = image;
    _selectedImageView.frame = rect;
    [self addSubview:_selectedImageView];
}

- (void)insertImage:(UIImage *)image
{
    CGSize size = CGSizeMake(150, image.size.height / image.size.width * 150);
    CGRect rect = CGRectMake((self.bounds.size.width - 155) / 2, (self.bounds.size.height - size.height) / 2, size.width, size.height);
    
    [self insertImage:image rect:rect];
}

- (void)setInsertImage
{
    if (_selectedImageView.image) {
        MHPathModel *pathModel = [MHPathModel initWithAction:MHPathModelActionInsertImage image:_selectedImageView.image drawInRect:_selectedImageView.frame];
        [_selectedImageView setImage:nil];
        [_selectedImageView removeFromSuperview];
        [self addPathModelToArray:pathModel];
        [self setNeedsDisplay];
    }
}

- (void)setBackgroundImage:(UIImage *)image
{
    [self clearBackgroundImage];
    
    MHPathModel *pathModel = [MHPathModel initWithAction:MHPathModelActionBackgroundImage image:image drawInRect:self.bounds];
    [self addPathModelToArray:pathModel];
    
    [self setNeedsDisplay];
}

- (void)setPathModelAction:(MHPathModelAction)pathModelAction
{
    if (_pathModelAction & MHPathModelActionInsertImage && !(pathModelAction & MHPathModelActionInsertImage)) {
        [self setInsertImage];
    }
    
    _pathModelAction = pathModelAction;
}

@end
