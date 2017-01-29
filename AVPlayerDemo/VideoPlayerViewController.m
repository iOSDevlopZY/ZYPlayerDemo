//
//  VideoPlayerViewController.m
//  AVPlayerDemo
//
//  Created by Developer_Yi on 2017/1/22.
//  Copyright © 2017年 mac. All rights reserved.
//

#import "VideoPlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MBProgressHUD+NJ.h"
#import <UShareUI/UShareUI.h>
@interface VideoPlayerViewController ()
//定义播放器顶部视图高度
#define TopViewHeight 55
//定义播放器底部视图高度
#define BottomViewHeight 72
//主屏幕宽度
#define mainWidth [UIScreen mainScreen].bounds.size.width
//主屏幕高度
#define mainHeight [UIScreen mainScreen].bounds.size.height
//是否收藏
@property (nonatomic,assign)BOOL isCollect;
//顶部视图的控件
@property (nonatomic,strong)UIView *topView;
@property (nonatomic,strong)UIButton *backBtn;
@property (nonatomic,strong)UIButton *fullScreenBtn;
@property (nonatomic,strong)UILabel *titleLabel;
@property (nonatomic,strong)UIButton *settingsBtn;
@property (nonatomic,strong)UIButton *collectBtn;
@property (nonatomic,strong)UIButton *widthBtn;
//TODO:设置按钮
@property (nonatomic,strong)UIView *settingsView;
@property (nonatomic,strong)UIView *rightView;
@property (nonatomic,strong)UIButton *setTestBtn;
//播放器核心
@property (nonatomic,strong)AVPlayer *player;
@property (nonatomic,strong)AVPlayerItem *playerItem;
@property (nonatomic,strong)AVPlayerLayer *playerLayer;
//播放器底部的控件
@property (nonatomic,strong)UIView *bottomView;
@property (nonatomic,strong)UIButton *playBtn;
@property (nonatomic,strong)UIButton *shareBtn;
@property (nonatomic,strong)UILabel *textLabel;
//底部控件所需的数据
@property (nonatomic,assign)BOOL isPlay;
@property (nonatomic,strong)UISlider *movieProgressSlider;//进度条
@property (nonatomic,assign)CGFloat ProgressBeginToMove;
@property (nonatomic,assign)CGFloat totalMovieDuration;//视频总时间
@property (nonatomic,strong)UISlider *volumeViewSlider;
@property (nonatomic,assign)float systemVolume;//系统音量值
@property (nonatomic,assign)float systemBrightness;//系统亮度
@property (nonatomic,assign)CGPoint startPoint;//起始位置坐标
@property (nonatomic,assign)BOOL isTouchBeganLeft;//起始位置方向
@property (nonatomic,copy)NSString *isSlideDirection;//滑动方向
@property (nonatomic,assign)float startProgress;//起始进度条
@property (nonatomic,assign)float NowProgress;//进度条当前位置
//触控事件
@property (nonatomic,assign)BOOL isShowView;
//TODO：设置是否显示设置界面
@property (nonatomic,assign)BOOL isSettingsViewShow;
@property (nonatomic,assign)BOOL isSlideOrClick;
//监控进度
@property (nonatomic,strong)NSTimer *avTimer;
//上下两个view消失的时间计时器
@property (nonatomic,strong) NSTimer *autoDismissTimer;
//是否全屏
@property (nonatomic,assign)BOOL isFullScreen;
@end

@implementation VideoPlayerViewController
#pragma mark -懒加载

- (void)viewDidLoad {
    [super viewDidLoad];
    //初始化视频都是未收藏的
    self.isCollect=false;
    [self prepareInit];
    //添加进入前台通知
    [self addNotification];
    //创建播放器
    [self createAvPlayer];
    //创建播放器头部视图
    [self createTopView];
    //创建播放器底部视图
    [self createBottomView];
    //获取系统音量
    [self getSysVolume];
    //获取系统亮度
    _systemBrightness = [UIScreen mainScreen].brightness;
    //隐藏顶部状态栏
    [self prefersStatusBarHidden];
    self.view.backgroundColor = [UIColor blackColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark - 准备初始化
- (void)prepareInit
{
    NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
    NSString *STATS=[defaults objectForKey:[NSString stringWithFormat:@"%@",self.url]];
    if([STATS isEqualToString:@"YES"])
    {
        self.isCollect=YES;
    }
    else if([STATS isEqualToString:@"NO"])
    {
        self.isCollect=NO;
    }
    else
    {
        self.isCollect=NO;
    }
    if([self.url isKindOfClass:[NSNull class]]||self.url==nil)
    {
        [MBProgressHUD showError:@"URL不合法" toView:self.view ];
        
    }
    else{
        [MBProgressHUD showMessage:@"加载视频中" toView:self.view ];
    }
}
#pragma mark -添加通知
- (void)addNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notice)
                                                 name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backgroundPause)
                                                 name:UIApplicationWillResignActiveNotification object:nil];
}
#pragma mark - 获取系统音量
- (void)getSysVolume
{
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    _volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]){
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]){
            _volumeViewSlider = (UISlider *)view;
            break;
        }
    }
}
#pragma mark - 创建播放器
- (void)createAvPlayer{
    //设置静音状态也可播放声音
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayback error:nil];
    [audioSession setActive:YES error:nil];
    CGRect playerFrame = CGRectMake(0, 0, self.view.layer.bounds.size.height, self.view.layer.bounds.size.width);
   
    AVURLAsset *asset = [AVURLAsset assetWithURL: _url];
    //获取视频总时长,异步防止卡顿
    dispatch_async(dispatch_get_main_queue(), ^{
        Float64 duration = CMTimeGetSeconds(asset.duration);
        _totalMovieDuration = duration;
         _textLabel.text = [self convertMovieTimeToText:_totalMovieDuration];
    });
    
    
    
    
    _playerItem = [AVPlayerItem playerItemWithAsset: asset];
    
    _player = [[AVPlayer alloc]initWithPlayerItem:_playerItem];
    
   _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
   _playerLayer.frame = playerFrame;
    //视频放大方式
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    // 监听播放器状态变化
    [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    [self.view.layer addSublayer:_playerLayer];
}
#pragma mark - 创建头部View
- (void)createTopView{
    
    _topView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.bounds.size.height, TopViewHeight)];
    _topView.backgroundColor = [UIColor blackColor];
    _topView.alpha=0.7f;
    //返回按钮
    [self createBackBtn];
    //标题按钮
    [self createTitleLabel];
    //收藏按钮
    [self createCollectBtn];
    //TODO:视频设置
    [self createSettingBtn];
    [self.view addSubview:_topView];
}
#pragma mark - 创建返回按钮 
- (void)createBackBtn
{
    _backBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50, TopViewHeight)];
    [_backBtn setImage:[UIImage imageNamed:@"ico_back"] forState:UIControlStateNormal];
    _backBtn.titleLabel.font  = [UIFont systemFontOfSize: 11];
    [_backBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_backBtn addTarget:self action:@selector(backClick) forControlEvents:UIControlEventTouchUpInside];
    [_topView addSubview:_backBtn];
}
#pragma mark - 创建标题标签
- (void)createTitleLabel
{
    CGFloat titleLableWidth = 400;
    _titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(self.view.bounds.size.height/2-titleLableWidth/2, 0, titleLableWidth, TopViewHeight)];
    _titleLabel.backgroundColor = [UIColor clearColor];
    [_titleLabel setFont:[UIFont systemFontOfSize:10.0f]];
    _titleLabel.text = [NSString stringWithFormat:@"%@",self.url];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    [_topView addSubview:_titleLabel];
}
#pragma mark - 创建收藏按钮
- (void)createCollectBtn
{
    CGFloat titleLableWidth = 400;
    _collectBtn = [[UIButton alloc]initWithFrame:CGRectMake(self.view.bounds.size.height/2+titleLableWidth/2+20, 0, 50, TopViewHeight)];
    if(self.isCollect==NO)
    {
        [_collectBtn setImage:[UIImage imageNamed:@"love"] forState:UIControlStateNormal];
        [_collectBtn setImage:[UIImage imageNamed:@"like_yes_3x-1"] forState:UIControlStateSelected];
    }
    else
    {
        [_collectBtn setImage:[UIImage imageNamed:@"like_yes_3x-1"] forState:UIControlStateNormal];
        [_collectBtn setImage:[UIImage imageNamed:@"love"] forState:UIControlStateSelected];
    }
    if([self.url isKindOfClass:[NSNull class]]||self.url==nil)
    {
        
        self.collectBtn.enabled=false;
        self.collectBtn.userInteractionEnabled=false;
    }
    if(_totalMovieDuration==0.0f)
    {
        self.collectBtn.enabled=false;
        self.collectBtn.userInteractionEnabled=false;
    }
    [_collectBtn addTarget:self action:@selector(collect:) forControlEvents:UIControlEventTouchUpInside];
    
     [_topView addSubview:_collectBtn];
}
#pragma mark - 创建设置按钮
- (void)createSettingBtn
{
    //    _settingsBtn = [[UIButton alloc]initWithFrame:CGRectMake(mainHeight - 50, 0, 50, TopViewHeight)];
    //    [_settingsBtn setTitle:@"设置" forState:UIControlStateNormal];
    //    [_settingsBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    //    [_settingsBtn addTarget:self action:@selector(settingsClick:) forControlEvents:UIControlEventTouchUpInside];
    //    [_topView addSubview:_settingsBtn];
}
#pragma mark - 收藏按钮点击事件
- (void)collect:(UIButton*)btn
{
    btn.selected=!btn.selected;
    self.isCollect=!self.isCollect;
    NSString *status=@"";
    if(self.isCollect==YES)
    {
        [MBProgressHUD showSuccess:@"收藏成功" toView:self.view];
        status=@"YES";
    }
    else
    {
        [MBProgressHUD showError:@"取消收藏" toView:self.view];
        status=@"NO";
    }
    //存储收藏状态
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    [defaults setObject:status forKey:[NSString stringWithFormat:@"%@",self.url]];
    [defaults synchronize];
}
#pragma mark - 返回按钮点击响应事件
- (void)backClick{

    //防止循环引用
    __weak typeof(self) weakSelf = self;
    [self dismissViewControllerAnimated:YES completion:^{
        //do someing
        [weakSelf PlayOrStop:NO];
        [weakSelf.avTimer invalidate];
        weakSelf.avTimer = nil;
    }];
}
#pragma mark - 设置按钮点击响应事件
//- (void)settingsClick:(UIButton *)btn{
//    
//    _isShowView = NO;
//    _isSettingsViewShow = YES;
//    _settingsView.alpha = 1;
//    [UIView animateWithDuration:0.5 animations:^{
//        _topView.alpha = 0;
//        _bottomView.alpha = 0;
//    }];
//}
#pragma mark - 创建底部View
- (void)createBottomView{
    _bottomView = [[UIView alloc]initWithFrame:CGRectMake(0, mainWidth - TopViewHeight, mainHeight, TopViewHeight)];
    _bottomView.backgroundColor = [UIColor blackColor];
    _bottomView.alpha=0.7f;
    //创建播放按钮
    [self createPlayBtn];
    //创建进度条
    [self createSlider];
    //创建屏幕宽度按钮
    [self createWidthBtn];
    //创建时间标签
    [self createTextLabel];
    //分享按钮
    [self createShareBtn];
    [self.view addSubview:_bottomView];
    
    
}
#pragma mark - 创建播放按钮
- (void)createPlayBtn
{
    _playBtn = [[UIButton alloc]initWithFrame:CGRectMake(0, 7, 40, TopViewHeight-14)];
    [_playBtn setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
    _playBtn.imageView.alpha=0.5f;
    [_playBtn.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [_playBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    _playBtn.userInteractionEnabled=NO;
    [_playBtn addTarget:self action:@selector(playClick:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_playBtn];
}
#pragma mark - 创建滑块
- (void)createSlider
{
    _movieProgressSlider = [[UISlider alloc]initWithFrame:CGRectMake(0, 0, _bottomView.frame.size.width, 10)];
    [_movieProgressSlider setMinimumTrackTintColor:[UIColor whiteColor]];
    
    [_movieProgressSlider setMaximumTrackTintColor:[UIColor colorWithRed:0.49f green:0.48f blue:0.49f alpha:1.00f]];
    [_movieProgressSlider setThumbImage:[UIImage imageNamed:@"progressThumb.png"] forState:UIControlStateNormal];
    
    [_movieProgressSlider addTarget:self action:@selector(scrubbingDidBegin) forControlEvents:UIControlEventTouchDown];
    [_movieProgressSlider addTarget:self action:@selector(scrubbingDidEnd) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchCancel)];
    if(_totalMovieDuration==0.0f)
    {
        _movieProgressSlider.enabled=NO;
        _movieProgressSlider.userInteractionEnabled=NO;
        
    }
    [_bottomView addSubview:_movieProgressSlider];
}
#pragma mark - 创建视频宽度按钮
- (void)createWidthBtn
{
    _widthBtn = [[UIButton alloc]initWithFrame:CGRectMake(350, 7, 60, TopViewHeight-14)];
    [_widthBtn setTitle:@"80%" forState:UIControlStateNormal];
    [_widthBtn setTitle:@"100%" forState:UIControlStateSelected];
    _widthBtn.userInteractionEnabled=NO;
    _widthBtn.selected=NO;
    [_widthBtn addTarget:self action:@selector(widthClick:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:_widthBtn];
}
#pragma mark - 创建时间标签
- (void)createTextLabel
{
    _textLabel = [[UILabel alloc]initWithFrame:CGRectMake(450, 0, 100, TopViewHeight)];
    
    _textLabel.backgroundColor = [UIColor clearColor];
    _textLabel.textColor = [UIColor whiteColor];
    _textLabel.textAlignment = NSTextAlignmentRight;
    _textLabel.font=[UIFont systemFontOfSize:12.0f];
    //在totalTimeLabel上显示总时间
    _textLabel.text = [self convertMovieTimeToText:_totalMovieDuration];
    [_bottomView addSubview:_textLabel];
}
#pragma mark - 创建分享按钮
- (void)createShareBtn
{
    _shareBtn=[[UIButton alloc]initWithFrame:CGRectMake(410, 14, 30, TopViewHeight-28)];
    [_shareBtn setImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
    [_shareBtn addTarget:self action:@selector(share) forControlEvents:UIControlEventTouchUpInside];
    _shareBtn.imageView.alpha=0.5f;
    [_shareBtn.imageView setContentMode:UIViewContentModeScaleAspectFit];
    [_bottomView addSubview:_shareBtn];
}
#pragma mark - 宽度点击按钮
- (void)widthClick:(UIButton*)btn
{
    btn.selected=!btn.selected;
    if(btn.selected==YES)
    {
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    }
    else{
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    }
}
#pragma mark - 视频分享
-(void)share
{
    [UMSocialUIManager setPreDefinePlatforms:@[@(UMSocialPlatformType_QQ),@(UMSocialPlatformType_WechatSession)]];
    [UMSocialUIManager showShareMenuViewInWindowWithPlatformSelectionBlock:^(UMSocialPlatformType platformType, NSDictionary *userInfo) {
        //TODO: 根据获取的platformType确定所选平台进行下一步操作
    }];
}
#pragma mark - 时间文字转换
-(NSString*)convertMovieTimeToText:(CGFloat)time{
    if(time<=0)
    {
        return [NSString stringWithFormat:@"0:0/0:0"];
    }
    else if (time<60.f) {
        return [NSString stringWithFormat:@"%.0f秒",time];
    }else{
        float dragedSeconds = floorf(_totalMovieDuration * _NowProgress);
        return [NSString stringWithFormat:@"%d:%d/%d:%d",(int)dragedSeconds/60,(int)dragedSeconds%60,(int)_totalMovieDuration/60,(int)_totalMovieDuration%60];
    }
}
#pragma mark - 播放按钮点击事件
- (void)playClick:(UIButton *)btn{
    if (!_isPlay) {
        [self PlayOrStop:YES];
    }else{
        [self PlayOrStop:NO];
    }
}
#pragma mark - 播放、暂停
- (void)PlayOrStop:(BOOL)isPlay{
    if (isPlay) {
         [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
        //play 并且重启timer
        [_player play];
        _isPlay = YES;
        [_playBtn setImage:[UIImage imageNamed:@"Pause"] forState:UIControlStateNormal];
        self.avTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
    }else{
        
        [_player pause];
        _isPlay = NO;
        [_playBtn setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
        [self.avTimer invalidate];
    }
}
#pragma mark - 更新滑块和时间Label UI
-(void)updateUI{
    //1.根据播放进度与总进度计算出当前百分比。
    float new = CMTimeGetSeconds(_player.currentItem.currentTime) / CMTimeGetSeconds(_player.currentItem.duration);
    if(new==1.0f)
    {
        _isPlay=NO;
        CMTime newCMTime = CMTimeMake(0,1);
         [_player seekToTime:newCMTime];
        [_playBtn setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
    }
    //2.计算当前百分比与实际百分比的差值，
    float DValue = new - _NowProgress;
//    //3.实际百分比更新到当前百分比
    _NowProgress = new;
    //4.当前百分比加上差值更新到实际进度条
    self.movieProgressSlider.value = self.movieProgressSlider.value+DValue ;
    _textLabel.text = [self convertMovieTimeToText:_totalMovieDuration];
}
#pragma mark -按住滑块
-(void)scrubbingDidBegin{
    _ProgressBeginToMove = _movieProgressSlider.value;
}
#pragma mark - 释放滑块
-(void)scrubbingDidEnd{
    [self UpdatePlayer];
}

#pragma mark - 拖动停止后更新播放器
-(void)UpdatePlayer{
    //1.暂停播放
    [self PlayOrStop:NO];
    //2.存储实际百分比值
    _NowProgress = _movieProgressSlider.value;
    //3.重新开始播放
    [self dragReplay];
   
}
#pragma mark -滑块点击重新播放时更新UI
- (void)dragReplay
{
    float dragedSeconds = _totalMovieDuration * _NowProgress;
    CMTime newCMTime = CMTimeMake(dragedSeconds,1);
    [_player seekToTime:newCMTime];
    [_player play];
    _isPlay = YES;
    if(_totalMovieDuration!=0.0f)
    {
    [_playBtn setImage:[UIImage imageNamed:@"Pause"] forState:UIControlStateNormal];
    }
    self.avTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(updateUI) userInfo:nil repeats:YES];
}
#pragma mark - 触控事件
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    _isSlideOrClick = YES;
    //右半区调整音量
    CGPoint location = [[touches anyObject] locationInView:self.view];
    CGFloat changeY = location.y - _startPoint.y;
    CGFloat changeX = location.x - _startPoint.x;
    
    if (_isShowView) {
        //上下View为显示状态，此时点击上下View直接return
        CGPoint point = [[touches anyObject] locationInView:self.view];
        if ((point.y>CGRectGetMinY(self.topView.frame)&&point.y< CGRectGetMaxY(self.topView.frame))||(point.y<CGRectGetMaxY(self.bottomView.frame)&&point.y>CGRectGetMinY(self.bottomView.frame))) {
            _isSlideOrClick = NO;
            return;
        }
    }
    
    //初次滑动没有滑动方向，进行判断。已有滑动方向，直接进行操作
    if ([_isSlideDirection isEqualToString:@"横向"]) {
        int index = location.x - _startPoint.x;
        if(index>0){
            _movieProgressSlider.value = _startProgress + abs(index)/10 * 0.008;
        }else{
            _movieProgressSlider.value = _startProgress - abs(index)/10 * 0.008;
        }
    }else if ([_isSlideDirection isEqualToString:@"纵向"]){
        if (_isTouchBeganLeft) {
            int index = location.y - _startPoint.y;
            if(index>0){
                [UIScreen mainScreen].brightness = _systemBrightness - abs(index)/10 * 0.1;
            }else{
                [UIScreen mainScreen].brightness = _systemBrightness + abs(index)/10 * 0.1;
            }
            
        }else{
            int index = location.y - _startPoint.y;
            if(index>0){
                [_volumeViewSlider setValue:_systemVolume - (abs(index)/10 * 0.05) animated:YES];
                [_volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
            }else{
                [_volumeViewSlider setValue:_systemVolume + (abs(index)/10 * 0.05) animated:YES];
                [_volumeViewSlider sendActionsForControlEvents:UIControlEventTouchUpInside];
            }
        }
        
    }else{
        //"第一次"滑动
        if(fabs(changeX) > fabs(changeY)){
            _isSlideDirection = @"横向";//设置为横向
        }else if(fabs(changeY)>fabs(changeX)){
            _isSlideDirection = @"纵向";//设置为纵向
        }else{
            _isSlideOrClick = NO;
           
        }
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    if(event.allTouches.count == 1){
        
        //保存当前触摸的位置
        CGPoint point = [[touches anyObject] locationInView:self.view];
        _startPoint = point;
        _startProgress = _movieProgressSlider.value;
        _systemVolume = _volumeViewSlider.value;
        if(point.x < self.view.frame.size.width/2){
            _isTouchBeganLeft = YES;
        }else{
            _isTouchBeganLeft = NO;
        }
    }
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    
    CGPoint point = [[touches anyObject] locationInView:self.view];
    if (!_isSettingsViewShow) {
        
        if (_isSlideOrClick) {
            _isSlideDirection = @"";
            _isSlideOrClick = NO;
            
            CGFloat changeY = point.y - _startPoint.y;
            CGFloat changeX = point.x - _startPoint.x;
            //如果位置改变 刷新进度条
            if(fabs(changeX) > fabs(changeY)){
                [self UpdatePlayer];
            }
            return;
        }
        
        if (_isShowView) {
            //上下View为显示状态，此时点击上下View直接return
            if ((point.y>CGRectGetMinY(self.topView.frame)&&point.y< CGRectGetMaxY(self.topView.frame))||(point.y<CGRectGetMaxY(self.bottomView.frame)&&point.y>CGRectGetMinY(self.bottomView.frame))) {
                return;
            }
            _isShowView = NO;
            [UIView animateWithDuration:0.5 animations:^{
                _topView.alpha = 0;
                _bottomView.alpha = 0;
            }];
        }else{
            _isShowView = YES;
            [UIView animateWithDuration:0.5 animations:^{
                _topView.alpha = 0.7;
                _bottomView.alpha = 0.7;
            }];
        }
        
    }else{
        if (point.x>CGRectGetMinX(_rightView.frame)&&point.x< CGRectGetMaxX(_rightView.frame)) {
            return;
        }
        _settingsView.alpha = 0;
        _isSettingsViewShow = NO;
    }
    
}
#pragma mark -监听播放的属性
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"])
    {
        AVPlayerItemStatus statues = [change[NSKeyValueChangeNewKey] integerValue];
        switch (statues) {
                // 监听到这个属性的时候，理论上视频就可以进行播放了
            case AVPlayerItemStatusReadyToPlay:
                [MBProgressHUD hideHUDForView:self.view];
                self.playBtn.userInteractionEnabled=YES;
                self.collectBtn.userInteractionEnabled=YES;
                self.widthBtn.userInteractionEnabled=YES;
                self.collectBtn.enabled=YES;
                _movieProgressSlider.enabled=YES;
                self.movieProgressSlider.userInteractionEnabled=YES;
                // 启动定时器 5秒自动隐藏
                if (!self.autoDismissTimer)
                {
                    self.autoDismissTimer = [NSTimer timerWithTimeInterval:8.0 target:self selector:@selector(autoDismissView:) userInfo:nil repeats:YES];
                    [[NSRunLoop currentRunLoop] addTimer:self.autoDismissTimer forMode:NSDefaultRunLoopMode];
                }
                break;
                
            case AVPlayerItemStatusUnknown:
                 [MBProgressHUD hideHUD];
                [self failureOp:@"未知错误发生了"];
                break;
                // 这个就是不能播放喽，加载失败了
            case AVPlayerItemStatusFailed:
                 [MBProgressHUD hideHUDForView:self.view];
                [self failureOp:@"加载失败，请退出重试"];
                // 这时可以通过`self.player.error.description`属性来找出具体的原因
//                NSLog(@"xxxxxxxx%@",self.player.error.description);
                break;
                
            default:
                break;
        }
    }
}
#pragma mark - 视频状态失败时操作
-(void)failureOp:(NSString*)text
{
    [MBProgressHUD showError:text toView:self.view];
    self.playBtn.userInteractionEnabled=NO;
     self.widthBtn.userInteractionEnabled=NO;
    _movieProgressSlider.enabled=NO;
    _movieProgressSlider.userInteractionEnabled=NO;
}
#pragma mark - 播放器上下view消失计时器事件
- (void)autoDismissView:(NSTimer *)timer
{
    // player的属性rate
    /* indicates the current rate of playback; 0.0 means "stopped", 1.0 means "play at the natural rate of the current item" */
    if (self.player.rate == 0)
    {
        // 暂停状态就不隐藏
    }
    else if (self.player.rate == 1)
    {
      
        
        if (self.bottomView.alpha == 0.7f)
        {
            [UIView animateWithDuration:1.0 animations:^{
                
                self.bottomView.alpha = 0;
                self.topView.alpha = 0;
                
            }];
        }
        
      
    }
}
#pragma mark - 后台进入前台响应事件
-(void)notice
{
    [[UIDevice currentDevice]performSelector:@selector(setOrientation:)
                                  withObject:[NSNumber numberWithInteger:UIInterfaceOrientationLandscapeRight]];
}
#pragma mark - 前台进入后台响应事件
-(void)backgroundPause
{
    [_player pause];
    _isPlay = NO;
    [_playBtn setImage:[UIImage imageNamed:@"Play"] forState:UIControlStateNormal];
    [self.avTimer invalidate];
}
-(void)dealloc
{
    if (self.playerItem && self.player) {
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [self.playerItem removeObserver:self forKeyPath:@"status"];
    }

    
}
#pragma mark - 状态栏与横屏设置
//隐藏状态栏
- (BOOL)prefersStatusBarHidden{
    return YES;
}

//允许横屏旋转
- (BOOL)shouldAutorotate{
    return YES;
}

//支持左右旋转
- (UIInterfaceOrientationMask)supportedInterfaceOrientations{
    return UIInterfaceOrientationMaskLandscapeRight|UIInterfaceOrientationMaskLandscapeLeft|UIInterfaceOrientationMaskPortrait;
}

//默认为右旋转
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation{
    return UIInterfaceOrientationLandscapeRight;
}
@end
