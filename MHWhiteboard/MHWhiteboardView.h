//
//  MHWhiteboardView.h
//  MHWhiteboard
//
//  Created by MakeHui on 10/1/19.
//  Copyright © 2019年 MakeHui. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MHPathModelType) {
    MHPathModelTypeNone,
    MHPathModelTypeImage,
    MHPathModelTypeLine
};

@interface MHPathModel : NSObject

+ (instancetype)initWithType:(MHPathModelType)type path:(CGPathRef)path lineWidth:(CGFloat)lineWidth color:(UIColor *)color;

+ (instancetype)initWithType:(MHPathModelType)type image:(UIImage *)image drawInRect:(CGRect)rect;

@property(assign, nonatomic)MHPathModelType type;
@property(strong, nonatomic)UIBezierPath *path;
@property(strong, nonatomic)UIColor *color;

@property(strong, nonatomic)UIImage *image;
@property(assign, nonatomic)CGRect drawImageRect;

@end

@interface MHWhiteboardView : UIView

@property(assign, nonatomic)MHPathModelType pathModelType;
@property(assign, nonatomic)IBInspectable CGFloat brushWidth;
@property(strong, nonatomic)IBInspectable UIColor *brushColor;

- (void)setForegroundImage:(UIImage *)foregroundImage;
- (void)setBackgroundImage:(UIImage *)backgroundImage;

- (void)undo;
- (void)clearAll;
- (void)clearBackgroundImage;

@end

NS_ASSUME_NONNULL_END
