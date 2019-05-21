//
//  MHDrawView.m
//  MHWhiteboard
//
//  Created by MakeHui on 21/5/2019.
//  Copyright © 2019 MakeHui. All rights reserved.
//

#import "MHDrawView.h"
#import "MHPathModel.h"

#define MHGetImage(imageName)  [UIImage imageNamed:[@"Frameworks/MHWhiteboard.framework/MHWhiteboard.bundle" stringByAppendingPathComponent:imageName]]

@interface MHDrawView ()<UITextFieldDelegate>

@end

@implementation MHDrawView
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
    self.polygonSides = 6;
    self.textFont = [UIFont systemFontOfSize:24];
    
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
    for(MHPathModel *pathModel in _pathModelArray) {
        if (pathModel.action & MHPathModelActionUndo) continue;
        
        if (pathModel.action & MHPathModelActionText) {
            NSDictionary *attributes = @{NSForegroundColorAttributeName: pathModel.color, NSFontAttributeName: pathModel.font};
            NSAttributedString *text=[[NSAttributedString alloc] initWithString:pathModel.text attributes:attributes];
            NSArray<NSValue *> *pathPoints = [MHPathModel pathPointsWithCGPath:pathModel.path.CGPath];
            CGPoint point = pathPoints.firstObject.CGPointValue;
            
            [text drawAtPoint:point];
        }
        else {
            [pathModel.color set];
            [pathModel.path stroke];
        }
    }
    
    if (_currentPath) {
        if (self.pathModelAction & MHPathModelActionText) { return; }
        
        MHPathModel *pathModel = [MHPathModel pathModelWithAction:self.pathModelAction path:_currentPath lineWidth:self.brushWidth color:self.brushColor sides:self.polygonSides];
        
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
    
    if (self.pathModelAction & MHPathModelActionText) {
        if (_textField) { [_textField removeFromSuperview]; }
        
        static const CGFloat rightMargin = 8.0f;
        static const CGFloat topMargin = 4.0f;
        static const CGFloat bottomMargin = 4.0f;
        static const CGFloat innerMargin = 7.0f;
        
        CGSize textSize = [[NSAttributedString alloc] initWithString:@"文字/words" attributes: @{NSFontAttributeName: self.textFont}].size;
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
    if (self.pathModelAction & MHPathModelActionText) { return; }
    
    MHPathModel *pathModel = [MHPathModel pathModelWithAction:self.pathModelAction path:_currentPath lineWidth:self.brushWidth color:self.brushColor sides:self.polygonSides];
    [self addPathModelToArray:pathModel];
    
    CGPathRelease(_currentPath);
    _currentPath = nil;
    
    [self setNeedsDisplay];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    if (textField.text.length) {
        MHPathModel *pathModel = [MHPathModel pathModelWithAction:self.pathModelAction path:_currentPath text:textField.text color:self.brushColor font:self.textFont];
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

@end
