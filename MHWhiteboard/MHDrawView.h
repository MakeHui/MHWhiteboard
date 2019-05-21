//
//  MHDrawView.h
//  MHWhiteboard
//
//  Created by MakeHui on 21/5/2019.
//  Copyright © 2019 MakeHui. All rights reserved.
//

#import "MHWhiteboardView.h"

NS_ASSUME_NONNULL_BEGIN

@interface MHDrawView : UIView

@property(assign, nonatomic)MHPathModelAction pathModelAction;
@property(assign, nonatomic)CGFloat brushWidth;
@property(strong, nonatomic)UIColor *brushColor;

@property(assign, nonatomic)NSUInteger polygonSides;

@property(strong, nonatomic)UIFont *textFont;

- (void)undo;
- (void)repeat;
- (void)clearAll;

@end

NS_ASSUME_NONNULL_END
