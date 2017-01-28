//
//  ViewController.m
//  AVPlayerDemo
//
//  Created by Developer_Yi on 2017/1/22.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "ViewController.h"
#import "VideoPlayerViewController.h"

@interface ViewController ()
//网络视频播放按钮
@property (weak, nonatomic) IBOutlet UIButton *videoPlayBtn;
//本地视频播放按钮
@property (weak, nonatomic) IBOutlet UIButton *localVideoPlayBtn;
//收藏按钮
@property (weak, nonatomic) IBOutlet UIButton *collectBtn;

//获取视频URL文本输入框
@property (weak, nonatomic) IBOutlet UITextField *videoURLTextField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //界面UI设置
    [self.view setBackgroundColor:[UIColor blackColor]];
    [self.view setAlpha:0.7f];
    [self setBtnUI:self.videoPlayBtn withTitleString:@"播放网络视频"];
    [self setBtnUI:self.localVideoPlayBtn withTitleString:@"播放本地视频"];
    [self setBtnUI:self.collectBtn withTitleString:@"我的收藏"];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
#pragma mark -按钮UI设置
- (void)setBtnUI:(UIButton*)btn withTitleString:(NSString*)title
{
    [btn setTitle:title forState:UIControlStateNormal];
    [btn setTintColor:[UIColor whiteColor]];
    btn.layer.cornerRadius=3.0f;
    btn.layer.borderWidth=1.0f;
    CGColorRef reg=[UIColor whiteColor].CGColor;
    btn.layer.borderColor=reg;
}
#pragma mark -跳转页面
-(void)presentWithURL: (NSURL*)url
{
   
    VideoPlayerViewController *mainScreenMP = [[VideoPlayerViewController alloc]init];
     mainScreenMP.url = url;
    [self presentViewController:mainScreenMP animated:YES completion:nil];
   
}
#pragma mark -点击跳转播放器界面
- (IBAction)videoPlayBtnClick:(id)sender {
    
    //从输入框获取URL
    
    NSURL *url= [NSURL URLWithString:[NSString stringWithFormat:@"%@",self.videoURLTextField.text]];
    if(self.videoURLTextField.text==nil||[self.videoURLTextField.text isEqualToString:@""]||[self.videoURLTextField.text isKindOfClass:[NSNull class]])
    {
        url=[NSURL URLWithString:[NSString stringWithFormat:@"%@",self.videoURLTextField.placeholder]];
    }
    [self presentWithURL:url];
}
#pragma mark -点击跳转本地播放器界面
- (IBAction)localVideoPlayBtnClick:(id)sender {
   NSURL* url = [[NSBundle mainBundle] URLForResource:@"chenyifaer" withExtension:@"mp4"];
    [self presentWithURL:url];
}

@end
