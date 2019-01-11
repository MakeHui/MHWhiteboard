# MHWhiteboard

A simple whiteboard library, based on `UIView`. (一个简洁的白板库, 基于`UIView`)

## Features

- [x] line (线条)
- [ ] straight line (直线)
- [ ] circle (圆)
- [ ] rectangle (矩形)
- [ ] triangle (三角形)
- [x] foreground image (前景图片)
- [x] background image (背景图图片)
- [ ] text (文字)
- [ ] smear (涂抹)
- [ ] mosaic (马赛克)
- [x] undo (撤销)
- [ ] repeat (回撤)

## Requirements

- iOS 8.0+
- Xcode 9.0+

## Installation

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```
$ brew update
$ brew install carthage
```

To integrate MHWhiteboard into your Xcode project using Carthage, specify it in your `Cartfile`:

```
github "MakeHui/MHWhiteboard"
```

Run `carthage update` to build the framework and drag the built `MHWhiteboard.framework` into your Xcode project.

## Usage

```
#import <MHWhiteboard/MHWhiteboard.h>

MHWhiteboardView *whiteboardView = [[MHWhiteboardView alloc] initWithFrame:CGRectMake(0, 0, 375, 500)];

[whiteboardView setBrushColor:[UIColor redColor]];	// 设置画笔颜色
[whiteboardView setBrushWidth:10.0f];	// 设置画笔宽度
[whiteboardView setForegroundImage:[UIImage new]];	// 设置前景图片
[whiteboardView setBackgroundImage:[UIImage new]];	// 设置背景图片
[whiteboardView undo];	// 撤销
[whiteboardView clearBackgroundImage];	// 清除背景图片
[whiteboardView clearAll];	// 清空白板

```

## License

MHWhiteboard is released under the MIT license. See LICENSE for details.
