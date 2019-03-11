//
//  MHWhiteboardView.h
//  MHWhiteboard
//
//  Created by MakeHui on 10/1/19.
//  Copyright © 2019年 MakeHui. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_OPTIONS(NSUInteger, MHPathModelAction) {
    MHPathModelActionNone = 0,
    
    MHPathModelActionUndo = 1 << 0,
    MHPathModelActionRepeat = 1 << 1,
    MHPathModelActionInsertImage = 1 << 2,
    MHPathModelActionBackgroundImage = 1 << 3,
    
    MHPathModelActionLine = 1 << 16,
    MHPathModelActionStraightLine = 1 << 17,
    MHPathModelActionCircle = 1 << 18,
    MHPathModelActionRectangle = 1 << 19,
    MHPathModelActionPolygon = 1 << 20,
    MHPathModelActionText = 1 << 21,
    MHPathModelActionSmear = 1 << 22,
    MHPathModelActionMosaic = 1 << 23,
};

@interface MHPathModel : NSObject

+ (instancetype)initWithAction:(MHPathModelAction)action path:(CGPathRef)path lineWidth:(CGFloat)lineWidth color:(UIColor *)color sides:(NSUInteger)sides;

+ (instancetype)initWithAction:(MHPathModelAction)action image:(UIImage *)image drawInRect:(CGRect)rect;

@property(assign, nonatomic)MHPathModelAction action;
@property(strong, nonatomic)UIBezierPath *path;
@property(strong, nonatomic)UIColor *color;

@property(strong, nonatomic)UIImage *image;
@property(assign, nonatomic)CGRect drawImageRect;

@property(strong, nonatomic)NSString *text;
@property(strong, nonatomic)UIFont *font;

@end

@interface MHWhiteboardView : UIView

@property(assign, nonatomic)MHPathModelAction pathModelAction;
@property(assign, nonatomic)IBInspectable CGFloat brushWidth;
@property(strong, nonatomic)IBInspectable UIColor *brushColor;

@property(assign, nonatomic)IBInspectable NSUInteger sides;

@property(strong, nonatomic)IBInspectable UIFont *textFont;

- (void)insertImage:(UIImage *)image;
- (void)setBackgroundImage:(UIImage *)image;

- (void)undo;
- (void)repeat;
- (void)clearAll;
- (void)clearBackgroundImage;

@end

NS_ASSUME_NONNULL_END
