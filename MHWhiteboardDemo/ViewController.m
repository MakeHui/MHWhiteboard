//
//  ViewController.m
//  MHWhiteboardDemo
//
//  Created by MakeHui on 10/1/19.
//  Copyright © 2019年 MakeHui. All rights reserved.
//

#import "ViewController.h"

#import <MHWhiteboard/MHWhiteboard.h>

@interface ViewController ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>
{
    UIImagePickerController *_foregroundPicker;
    UIImagePickerController *_backgroundPicker;
}

@property (weak, nonatomic) IBOutlet MHWhiteboardView *whiteboardView;
@property (weak, nonatomic) IBOutlet UIStackView *toolsView;
@property (weak, nonatomic) IBOutlet UIStackView *darwWidthView;
@property (weak, nonatomic) IBOutlet UIStackView *colorsView;
@property (weak, nonatomic) IBOutlet UIStackView *clearView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _foregroundPicker = ({
        UIImagePickerController *picker = [UIImagePickerController new];
        [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        picker.delegate = self;
        picker;
    });
    
    _backgroundPicker = ({
        UIImagePickerController *picker = [UIImagePickerController new];
        [picker setSourceType:UIImagePickerControllerSourceTypePhotoLibrary];
        picker.delegate = self;
        picker;
    });
}

- (IBAction)onOpenColorViewTouchUpInside:(id)sender
{
    [self showToolsView:self.colorsView];
}

- (IBAction)onOpenWidthViewTouchUpInside:(id)sender
{
    [self showToolsView:self.darwWidthView];
}

- (IBAction)onSelectForegroundImageTouchUpInside:(id)sender
{
    [self presentViewController:_foregroundPicker animated:YES completion:nil];
}

- (IBAction)onSelectBackgroundImageTouchUpInside:(id)sender
{
    [self presentViewController:_backgroundPicker animated:YES completion:nil];
}

- (IBAction)onEraserTouchUpInside:(id)sender
{
    self.whiteboardView.brushColor = self.whiteboardView.backgroundColor;
}

- (IBAction)onUndoTouchUpInside:(id)sender
{
    [self.whiteboardView undo];
}

- (IBAction)onClearTouchUpInside:(id)sender
{
    [self.whiteboardView clearAll];
}

- (IBAction)onClearBackgroundImageTouchUpInside:(id)sender
{
    [self.whiteboardView clearBackgroundImage];
}

- (IBAction)onSelectWidthTouchUpInside:(UIButton *)sender
{
    if (sender.tag == 105) {
        [self showToolsView:self.toolsView];
    }
    else {
        self.whiteboardView.brushWidth = (sender.tag - 100) * 5;
    }
}

- (IBAction)onSelectColorTouchUpInside:(UIButton *)sender
{
    if (sender.tag == 105) {
        [self showToolsView:self.toolsView];
    }
    else {
        self.whiteboardView.brushColor = sender.preferredFocusedView.backgroundColor;
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info
{
    UIImage *image = info[UIImagePickerControllerOriginalImage];

    if (picker == _foregroundPicker) {
        [self.whiteboardView setForegroundImage:image];
    }
    else if (picker == _backgroundPicker) {
        [self.whiteboardView setBackgroundImage:image];
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showToolsView:(UIView *)view
{
    self.toolsView.hidden = true;
    self.colorsView.hidden = true;
    self.darwWidthView.hidden = true;
    view.hidden = false;
}

@end
