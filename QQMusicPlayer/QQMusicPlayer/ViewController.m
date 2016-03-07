//
//  ViewController.m
//  QQMusicPlayer
//
//  Created by mac on 15/12/30.
//  Copyright (c) 2015年 WXHL. All rights reserved.
//

#import "ViewController.h"
#import <MediaPlayer/MediaPlayer.h>

#define kScreenWidth [UIScreen mainScreen].bounds.size.width
#define kScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController () {
    
    NSInteger _index;           //计数
    
    UILabel *_songLabel;        //歌名
    UILabel *_singerLabel;      //歌手名
    UIImageView *_posterView;   //海报
    
    UIButton *_playButton;      //播放按钮
    UISlider *_proSlider;       //滑动条
    
    UILabel *_rightTime;        //右边的时间
    UILabel *_leftTime;         //左边的时间
    
    
    NSTimer *_timer;            //定时器对象
    
    UIButton *_loveButton;    //收藏按钮
    
    AVAudioPlayer *_player;     //播放器
    
    BOOL _isLove;
    BOOL isLove[10];
    
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //计数值
    _index = 0;
    
    //创建海报视图
    [self _createPosterView];
    
    //创建导航视图
    [self _createNavigationView];
    
    //创建底部视图
    [self _createBottomView];
    
    //解析歌曲信息并且播放
    [self readSongInfo];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePlayStatus:) name:@"receivedEventSubtype" object:@"AppDelegate"];
}

- (void)changePlayStatus:(NSNotification *)notification{
    UIEventSubtype subtype = [notification.userInfo[@"receivedEventSubtype"] integerValue];
    
    switch (subtype) {
            
        case UIEventSubtypeRemoteControlPlay:
            [self playAction:_playButton];
            
            break;
            
        case UIEventSubtypeRemoteControlPause:
            [self playAction:_playButton];
            
            break;
            
        case UIEventSubtypeRemoteControlNextTrack:
            [self nextSongAction:_playButton];
            
            break;
            
        case UIEventSubtypeRemoteControlPreviousTrack:
            [self preSongAction:_playButton];
            
            break;
            
        default:
            break;
    }
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"receivedEventSubtype" object:@"AppDelegate"];
}

#pragma mark - 解析歌曲信息并且播放
- (void)readSongInfo {
    
    //拿到歌曲信息文件路径
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"music" ofType:@"plist"];
   
    //arrayWithContentsOfFile:把路径转换成数组
    NSArray *infoArr = [NSArray arrayWithContentsOfFile:filePath];
    
    //根据下标获取数组里面的字典
    NSDictionary *dic = infoArr[_index];
    
    //获取字典里的信息
    _songLabel.text = dic[@"song"];
    _singerLabel.text = dic[@"singer"];
    _posterView.image = [UIImage imageNamed:dic[@"image"]];
    
    NSString *songStr = dic[@"url"];
    
    //----------------播放器-------------------
    //拿到本地播放器的路径：把本地路径转换成NSString样式
    NSString *songPath = [[NSBundle mainBundle] pathForResource:songStr ofType:nil];
    //把字符串路径转换成url路径 加载本地音乐路径：fileURLWithPath:
    NSURL *songUrl = [NSURL fileURLWithPath:songPath];
    
    //加载网络路径：URLWithString:
//    NSURL *url = [NSURL URLWithString:(NSString *)];
    
    
    
    //判断播放器存不存在
    if (_player) {
        //停止播放器并且销毁
        [_player stop];
        _player = nil;
        
        //停止定时器并且销毁
        [_timer invalidate];
        _timer = nil;
        
        //设置左边时间标签和滑块的初始值
        _leftTime.text = @"00:00";
        _proSlider.value = 0;
    
    }
    
    //初始化播放器
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:songUrl error:nil];
    //设置代理
    _player.delegate = self;
    
    //准备播放
    [_player prepareToPlay];
    
    //获取歌曲的总时长
    _proSlider.maximumValue = _player.duration;
    
    //右边时间表签得值
    _rightTime.text = [self covertTimeToString:_player.duration];
    
    //切换歌曲
    [self playAction:_playButton];
    
    //根据下标判断歌的收藏状态
    if (isLove[_index]) { //YES就是收藏状态
        
        [_loveButton setImage:[UIImage imageNamed:@"player_btn_favorited_normal"] forState:UIControlStateNormal];

        //把_isLove = YES 保证切换歌曲时能继续收藏
        _isLove = YES;
        
    } else {
        
        [_loveButton setImage:[UIImage imageNamed:@"player_btn_favorite_normal"] forState:UIControlStateNormal];
        
        _isLove = NO;
    }
    
    [self setLockScreenNowPlayingInfo];
}

#pragma mark - 转换时间格式
- (NSString *)covertTimeToString:(NSTimeInterval)seconds {
    
    NSInteger min = seconds / 60;             //分钟
    NSInteger sec = (NSInteger)seconds % 60;  //秒
    
    //%02d 表示显示两位数的整数且十位用0占位
    NSString *string = [NSString stringWithFormat:@"%02ld:%02ld",min, sec];
    return string;
}

#pragma mark - 自定义视图
//创建海报视图
- (void)_createPosterView {
    
    //创建图片视图
    UIImageView *posterView = [[UIImageView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    //允许接受用户交互操作(接受响应事件)
    posterView.userInteractionEnabled = YES;

    //创建图片对象
    UIImage *image = [UIImage imageNamed:@"gem.jpg"];
    
    posterView.image = image;
    
    [self.view addSubview:posterView];
    
    _posterView = posterView;
    
    //设置隐藏按钮
    UIButton *hiddenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    hiddenButton.frame = CGRectMake(0, 80, kScreenWidth, kScreenHeight - 80 - 150);
    
    //设置 button 背景为透明的颜色
    hiddenButton.backgroundColor = [UIColor clearColor];
    
    //TODO:隐藏按钮事件
    [hiddenButton addTarget:self action:@selector(hiddenView:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [_posterView addSubview:hiddenButton];
    
}

//创建导航视图
- (void)_createNavigationView {

    //创建导航视图
    UIView *navigationView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kScreenWidth, 80)];
    
    navigationView.backgroundColor = [UIColor blackColor];
    
    //修改透明度
    navigationView.alpha = 0.7;
    
    //设置tag值
    navigationView.tag = 1000;
    
    //添加到父视图上显示
    [self.view addSubview:navigationView];
    
    
    //左边的按钮
    UIButton *leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    //设置frame
    leftButton.frame = CGRectMake(10,30, 60, 44);
    
    //设置图片
    [leftButton setImage:[UIImage imageNamed:@"player_btn_close_normal.png"] forState:UIControlStateNormal];
    
    //TODO:左边按钮事件
    [navigationView addSubview:leftButton];
    
    //右边的图片
    UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    rightButton.frame = CGRectMake(kScreenWidth - 60 - 10, 30, 60, 44);
    
    //设置图片
    [rightButton setImage:[UIImage imageNamed:@"player_btn_more_normal.png"] forState:UIControlStateNormal];
    
    //TODO:右边按钮的事件
    [navigationView addSubview:rightButton];
    
    //设置歌名 Label
    UILabel *songLabel = [[UILabel alloc] initWithFrame:CGRectMake((kScreenWidth - 200)/2, 20, 200, 35)];
    songLabel.text = @"多远都要在一起";
    songLabel.textColor = [UIColor whiteColor];
    //设置居中
    songLabel.textAlignment = NSTextAlignmentCenter;
    songLabel.font = [UIFont boldSystemFontOfSize:20];
    [navigationView addSubview:songLabel];
    
    _songLabel = songLabel;
    
    //设置歌手 label
    UILabel *singerLabel = [[UILabel alloc] initWithFrame:CGRectMake((kScreenWidth - 200)/2, 55, 200, 25)];
    singerLabel.text = @"邓紫棋";
    singerLabel.textColor = [UIColor whiteColor];
    //设置居中
    singerLabel.textAlignment = NSTextAlignmentCenter;
    singerLabel.font = [UIFont systemFontOfSize:16];
    [navigationView addSubview:singerLabel];
    
    _singerLabel = singerLabel;
    
}

//创建底部视图
- (void)_createBottomView {
   
    //创建底部视图
    UIView *bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, kScreenHeight - 150, kScreenWidth, 150)];
    //设置背景颜色
    bottomView.backgroundColor = [UIColor blackColor];
    
    //设置tag值
    bottomView.tag = 2000;
    
    //设置透明度
    bottomView.alpha = 0.7;

    [self.view addSubview:bottomView];
    
    //创建滑块视图
    [self _createSlider:bottomView];
    
    //播放按钮
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    _playButton.frame = CGRectMake((kScreenWidth - 64)/2, (150 - 64)/2 , 64, 64);
    
//    NSLog(@"%@",NSStringFromCGPoint(bottomView.center));
    //中心点坐标
//    playButton.center = bottomView.center;
    
    //设置图片
    [_playButton setImage:[UIImage imageNamed:@"player_btn_play_normal@2x.png"] forState:UIControlStateNormal];
    
    //TODO:播放
    [_playButton addTarget:self action:@selector(playAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [bottomView addSubview:_playButton];
    
    //上一首
    UIButton *preButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    //播放按钮_playButton的 X 坐标
    CGFloat playButtonX = _playButton.frame.origin.x;
    
    preButton.frame = CGRectMake(playButtonX - 64 - 20, (150 - 64)/2, 64, 64);
    
    [preButton setImage:[UIImage imageNamed:@"player_btn_pre_normal@2x.png"] forState:UIControlStateNormal];
    
    //TODO:上一曲
    [preButton addTarget:self action:@selector(preSongAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [bottomView addSubview:preButton];
    
    //下一首
    UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    
    nextButton.frame = CGRectMake(playButtonX + 64 + 20, (150 - 64)/2, 64, 64);
    
    [nextButton setImage:[UIImage imageNamed:@"player_btn_next_normal@2x.png"] forState:UIControlStateNormal];
    
    //TODO:下一曲
    [nextButton addTarget:self action:@selector(nextSongAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [bottomView addSubview:nextButton];
    
    //创建标签视图
    [self _createTabBarButton:bottomView];
}

//创建滑块视图
- (void)_createSlider:(UIView *)bottomView {
    
    //创建滑块视图
    _proSlider = [[UISlider alloc] initWithFrame:CGRectMake(50, 0, kScreenWidth - 100, 30)];
    
    //设置图片
    [_proSlider setMinimumTrackImage:[UIImage imageNamed:@"player_slider_playback_left.png"] forState:UIControlStateNormal];
    [_proSlider setMaximumTrackImage:[UIImage imageNamed:@"player_slider_playback_right.png"] forState:UIControlStateNormal];
    [_proSlider setThumbImage:[UIImage imageNamed:@"player_slider_playback_thumb.png"] forState:UIControlStateNormal];
    
    //TODO:滑块事件
    [_proSlider addTarget:self action:@selector(dragSliderChangeValue:) forControlEvents:UIControlEventValueChanged];
    
    [bottomView addSubview:_proSlider];
    
    //左边的时间 label
    _leftTime = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 30)];
    _leftTime.text = @"00:00";
    _leftTime.textColor = [UIColor whiteColor];
    _leftTime.font = [UIFont systemFontOfSize:14];
    _leftTime.textAlignment = NSTextAlignmentCenter;
    [bottomView addSubview:_leftTime];
    
    //右边的时间
    _rightTime = [[UILabel alloc] initWithFrame:CGRectMake(kScreenWidth - 50, 0, 50, 30)];
    _rightTime.text = @"04:00";
    _rightTime.textColor = [UIColor whiteColor];
    _rightTime.font = [UIFont systemFontOfSize:14];
    _rightTime.textAlignment = NSTextAlignmentCenter;
    [bottomView addSubview:_rightTime];
   
}

//创建标签视图
- (void)_createTabBarButton:(UIView *)bottomView {
    
    //创建图片数组
    NSArray *images = @[
                        @"player_btn_download_normal",
                        @"player_btn_favorite_normal",
                        @"player_btn_playlist_normal",
                        @"player_btn_random_normal",
                        @"player_btn_share_normal"
                        ];
    
    //根据图片数组，循环创建五个button
    for (int i = 0; i < images.count; i++) {
        
        UIButton *item = [UIButton buttonWithType:UIButtonTypeCustom];
        
        //循环设置每个 button 的 frame
        item.frame = CGRectMake(i * (kScreenWidth / 5) , 100, kScreenWidth / 5, 50);
        
        //设置每张图片
        [item setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
        
        //设置 tag 值
        item.tag = i + 200;
        
        //TODO:每个标签的点击事件
        [item addTarget:self action:@selector(favoriteAction:) forControlEvents:UIControlEventTouchUpInside];

        [bottomView addSubview:item];
    }
    
    //隐藏按钮
    _loveButton = [bottomView viewWithTag:201];
  
}

#pragma mark - 响应事件
//隐藏导航视图和底部视图
- (void)hiddenView:(UIButton *)sender {
    
    //通过tag值获取到上下两个视图
    UIView *navigationView = [self.view viewWithTag:1000];
    UIView *bottomView = [self.view viewWithTag:2000];
    
//    navigationView.hidden = !navigationView.hidden;
//    bottomView.hidden = !bottomView.hidden;
    
    //三目运算符
    navigationView.hidden = navigationView.isHidden ? NO : YES;
    bottomView.hidden = bottomView.isHidden ? NO : YES;

}

//下一曲
- (void)nextSongAction:(UIButton *)sender {
    
     //下标加一
    _index++;
    //如果大于大于4，下标就换成0
    if (_index > 4) {
        _index = 0;
    }
    
    //读取歌曲信息
    [self readSongInfo];

}

//上一曲
- (void)preSongAction:(UIButton *)sender {
    
    //下标减一
    _index--;
    
    //如果大于小于0，下标就换成4
    if (_index < 0) {
        _index = 4;
    }
    //读取歌曲信息
    [self readSongInfo];

}

//播放、暂停
- (void)playAction:(UIButton *)sender {
    
    if (!_player.isPlaying) {//如过没有播放
        
        //播放
        [_player play];
        
        //如果定时器不存在
        if (!_timer) {
            //开启定时器
            _timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                      target:self
                                                    selector:@selector(changeSliderValue)
                                                    userInfo:nil repeats:YES];
        }
 
        //如果正在播放，图片换成暂停
        [sender setImage:[UIImage imageNamed:@"player_btn_pause_normal.png"] forState:UIControlStateNormal];
        
    } else {

        //如果定时器存在
        if (_timer) {
            
            //停止定时器
            [_timer invalidate];
            _timer = nil;
            
        }
        
        //暂停
        [_player pause];

        //如果暂停图片换成播放
        [sender setImage:[UIImage imageNamed:@"player_btn_play_normal.png"] forState:UIControlStateNormal];

    }

}

//拖拽改变进度条的值
- (void)dragSliderChangeValue:(UISlider *)slider {
    
    //根据进度求出需要播放的时间点
    NSTimeInterval currentTime =  slider.value;
    
    //根据进度条的值改变播放的进度
    _player.currentTime = currentTime;
    
}

//根据播放进度改变进度条的值和显示的播放时间,每隔1秒变化一次
- (void)changeSliderValue {
    
    //获取歌曲当前的时间
    NSTimeInterval time = _player.currentTime;
    
    //改变播放时间的显示
    _leftTime.text = [self covertTimeToString:time];
    
    //修改 slider 的值
    _proSlider.value = time;
    
}

//收藏
- (void)favoriteAction:(UIButton *)sender {
    

    NSInteger index = sender.tag - 200;
    switch (index) {
        case 1: {
            
            //判断是否收藏 _isLove 默认为 NO
            if (!_isLove) { //此时为YES
                
                [sender setImage:[UIImage imageNamed:@"player_btn_favorited_normal"] forState:UIControlStateNormal];
                
                //保存这首歌收藏的状态
                isLove[_index] = YES;
                
                //让_isLove 的值设为YES
                _isLove = YES;
                
            } else {
                
                 [sender setImage:[UIImage imageNamed:@"player_btn_favorite_normal"] forState:UIControlStateNormal];
                //保存这首歌收藏的状态
                isLove[_index] = NO;
                //让_isLove 的值设为YES
                _isLove = NO;
            }
       
        }
 
            break;
            
        default:
            break;
    }
    
}

#pragma mark - AVAudioPlayerDelegate
//自动播放下一曲
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    
    [self nextSongAction:nil];
    
}

- (void)setLockScreenNowPlayingInfo{
    
    //更新锁屏时的歌曲信息
    if (NSClassFromString(@"MPNowPlayingInfoCenter")) {
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        
        [dict setObject:_songLabel.text forKey:MPMediaItemPropertyAlbumTitle];
        [dict setObject:_singerLabel.text forKey:MPMediaItemPropertyArtist];
        [dict setObject:@"专辑名" forKey:MPMediaItemPropertyAlbumTitle];
        
        UIImage *newImage = _posterView.image;
        [dict setObject:[[MPMediaItemArtwork alloc] initWithImage:newImage] forKey:MPMediaItemPropertyArtwork];
        
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:dict];
    }
}

@end
