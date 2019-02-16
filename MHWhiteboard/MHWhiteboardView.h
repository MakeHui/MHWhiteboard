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
    
    MHPathModelActionLine = 1 << 16,
//    MHPathModelActionStraightLine = 2 << 16,
//    MHPathModelActionCircle = 3 << 16,
//    MHPathModelActionRectangle = 4 << 16,
//    MHPathModelActionRriangle = 5 << 16,
    MHPathModelActionForegroundImage = 6 << 16,
    MHPathModelActionBackgroundImage = 7 << 16,
//    MHPathModelActionText = 8 << 16,
//    MHPathModelActionSmear = 9 << 16,
//    MHPathModelActionMosaic = 10 << 16,
};

@interface MHPathModel : NSObject

+ (instancetype)initWithAction:(MHPathModelAction)action path:(CGPathRef)path lineWidth:(CGFloat)lineWidth color:(UIColor *)color;

+ (instancetype)initWithAction:(MHPathModelAction)action image:(UIImage *)image drawInRect:(CGRect)rect;

@property(assign, nonatomic)MHPathModelAction action;
@property(strong, nonatomic)UIBezierPath *path;
@property(strong, nonatomic)UIColor *color;

@property(strong, nonatomic)UIImage *image;
@property(assign, nonatomic)CGRect drawImageRect;

@end

@interface MHWhiteboardView : UIView

@property(assign, nonatomic)MHPathModelAction pathModelAction;
@property(assign, nonatomic)IBInspectable CGFloat brushWidth;
@property(strong, nonatomic)IBInspectable UIColor *brushColor;

- (void)setForegroundImage:(UIImage *)foregroundImage;
- (void)setBackgroundImage:(UIImage *)backgroundImage;

- (void)undo;
- (void)repeat;
- (void)clearAll;
- (void)clearBackgroundImage;

@end

NS_ASSUME_NONNULL_END
