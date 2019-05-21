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
    MHPathModelActionText = 1 << 21
};

@interface MHWhiteboardView : UIView

@property(assign, nonatomic)IBInspectable MHPathModelAction pathModelAction;
@property(assign, nonatomic)IBInspectable CGFloat brushWidth;
@property(strong, nonatomic)IBInspectable UIColor *brushColor;

@property(assign, nonatomic)IBInspectable NSUInteger polygonSides;

@property(strong, nonatomic)IBInspectable UIFont *textFont;

@property(assign, nonatomic)IBInspectable UIViewContentMode backgroundImageContentMode;

- (void)insertImage:(UIImage *)image;
- (void)setBackgroundImage:(UIImage *)image;
- (void)clearBackgroundImage;

- (void)undo;
- (void)repeat;
- (void)clearAll;

@end

NS_ASSUME_NONNULL_END
