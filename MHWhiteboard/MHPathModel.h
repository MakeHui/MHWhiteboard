//
//  MHPathModel.h
//  MHWhiteboard
//
//  Created by MakeHui on 21/5/2019.
//  Copyright © 2019 MakeHui. All rights reserved.
//

#import "MHWhiteboardView.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHPathModel : NSObject

+ (instancetype)pathModelWithAction:(MHPathModelAction)action path:(CGPathRef)path lineWidth:(CGFloat)lineWidth color:(UIColor *)color;

+ (instancetype)pathModelWithAction:(MHPathModelAction)action path:(CGPathRef)path lineWidth:(CGFloat)lineWidth color:(UIColor *)color sides:(NSUInteger)sides;

+ (instancetype)pathModelWithAction:(MHPathModelAction)action path:(CGPathRef)path text:(NSString *)text color:(UIColor *)color font:(UIFont *)font;

+ (NSArray<NSValue *> *)pathPointsWithCGPath:(CGPathRef)path;

@property(assign, nonatomic)MHPathModelAction action;
@property(strong, nonatomic)UIBezierPath *path;
@property(strong, nonatomic)UIColor *color;

@property(strong, nonatomic)NSString *text;
@property(strong, nonatomic)UIFont *font;

@end

NS_ASSUME_NONNULL_END
