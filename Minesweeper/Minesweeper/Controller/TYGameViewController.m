//
//  TYMainViewController.m
//  Minesweeper
//
//  Created by rimi on 14-7-16.
//  Copyright (c) 2014年 Leo. All rights reserved.
//

#import "TYGameViewController.h"
#import "TYButton.h"
#import "TYScoreInfo.h"
#import <AVFoundation/AVFoundation.h>

#define WIDTH 10

/*
 1.点击事件：
 双击、单击、判断是否button，转化坐标
 2.block简化代码
 3.递归逻辑（空格展开，数字展开）
 4.通过tag值得到想要操作的对象
 5.归档，数据持久化 （NSUserDefaults）
 6.开场界面（开门动画）
 7.系统音效
 */

/*
 2.雷量选择，网格选择
 3.游戏动画
 4.分享
 */

/**
 * 雷量选择，网格选择
 */

// 获取屏幕尺寸
#define SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

@interface TYGameViewController () <UIAlertViewDelegate, UIGestureRecognizerDelegate> {
    
    NSMutableArray *_positon; // 存放地雷分布位置
    NSInteger _numberOfRemandingGrid; // 剩余未被点击的网格数
    NSInteger _numberOfMarkedGird; // 标记的地雷数
    UIScrollView *_scrollView; // 显示雷区的scrollview
    
    // 接受当前屏幕点击位置
    UITouch *_touch;
    
    // 计时器
    NSTimer *_timer;
    double _currentTime;
    NSInteger _currentSecond;
    
    // 三个记录成绩label
    UILabel *_goldLabel;
    UILabel *_silverLabel;
    UILabel *_bronzeLabel;
    
    // 记录成绩的字典
    NSMutableDictionary *_allScore;
    NSMutableDictionary *_currentLevelScore;
    NSString *_key;
    
    // 当前游戏行数
    NSInteger _lines;
    NSInteger _numberOfMines;
    
    // 声明音效ID
    SystemSoundID _successSoundID;
    SystemSoundID _failureSoundID;
    BOOL _soundsOff;
}


- (void)initializeDataSoure;
- (void)initializeAppearance;

- (void)layMines;
- (void)initializeGrids;

- (void)buttonPressed:(TYButton *)sender;
- (void)processgestureReconizer:(UIGestureRecognizer *)gesture;
- (void)shareScore;
- (void)dealGridClick:(TYButton *)sender;
- (void)selectedGridClick:(TYButton *)sender;
- (void)operateOnSurroundGridsOfButton:(TYButton *)sender operation:(void (^)(TYButton *button))block;
- (void)updateCurrentTimeImage;
- (void)updateCurrentRemandingMinesImage;
- (void)updateImageViewWithTag:(NSInteger)tag numberOfCalculate:(NSInteger)num;
- (void)updateCurrentScoreLeader;
    
- (void)gameOver;
- (void)gameRestart;

@end

@implementation TYGameViewController

#pragma mark - 生命周期方法

- (id)initWithLines:(NSInteger)lines numberOfMines:(NSInteger)mines {
    
    self = [super init];
    if (self) {
        _lines = lines;
        _numberOfMines = mines;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initializeDataSoure];
    [self initializeAppearance];
    // Do any additional setup after loading the view.
}

#pragma mark - 延展方法

/**
 *  数据初始化
 */
- (void)initializeDataSoure {
    
    _positon = [[NSMutableArray alloc] init];
    
    // 所有成绩初始化（数据持久化）
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    _allScore = [NSMutableDictionary dictionaryWithDictionary:[userDefaults valueForKey:@"allScore"]];
    _key = [NSString stringWithFormat:@"%ld_%ld", _lines, _numberOfMines];
    _currentLevelScore = _allScore[_key];
    if (!_currentLevelScore) {
        _currentLevelScore = [[NSMutableDictionary alloc] init];
        for (int i = 0; i < 3; i++) {
            NSString *key = i == 0 ? @"gold" : i == 1 ? @"silver" : @"bronze";
            TYScoreInfo *info = [[TYScoreInfo alloc] initWithName:@"Leo" score:10000];
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:info];;
            [_currentLevelScore setObject:data forKey:key];
        }
    }
    
    // 关联音效ID
    NSURL *url = [[NSBundle mainBundle] URLForAuxiliaryExecutable:@"music_success.mp3"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_successSoundID);
    
    url = [[NSBundle mainBundle] URLForAuxiliaryExecutable:@"mine_explode.mp3"];
    AudioServicesCreateSystemSoundID((__bridge CFURLRef)url, &_failureSoundID);
}

/**
 *  界面初始化
 */
- (void)initializeAppearance {
    
    self.view.backgroundColor = [UIColor colorWithRed:192 / 255.0 green:192 / 255.0 blue:192 / 255.0 alpha:1];
    
    /**
     *  界面初始化
     */
    
    // 初始化游戏头部背景
    UIImageView *topBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"top_bg"]];
    topBackground.bounds = CGRectMake(0, 0, 310, 80);
    topBackground.center = CGPointMake(160, 80);
    topBackground.tag = -11;
    
    [self.view addSubview:topBackground];
    
    // 初始化剩余地雷数背景
    UIView *remandingMinesBackground = [[UIView alloc] init];
    remandingMinesBackground.backgroundColor = [UIColor blackColor];
    remandingMinesBackground.bounds = CGRectMake(0, 0, 90, 50);
    remandingMinesBackground.center = CGPointMake(65, 80);
    remandingMinesBackground.tag = -12;
    
    [self.view addSubview:remandingMinesBackground];
    
    // 初始化当前游戏时间背景
    UIView *currentTimeBackground = [[UIView alloc] init];
    currentTimeBackground.backgroundColor = [UIColor blackColor];
    currentTimeBackground.bounds = CGRectMake(0, 0, 90, 50);
    currentTimeBackground.center = CGPointMake(255, 80);
    currentTimeBackground.tag = -13;
    
    [self.view addSubview:currentTimeBackground];
    
    // 初始化剩余地雷数字图案
    for (int i = 0; i < 3; i++) {
        UIImageView *imageView = [[UIImageView alloc] init];
        
        imageView.bounds = CGRectMake(0, 0, 20, 40);
        imageView.center = CGPointMake(35 + i * 30, 80);
        imageView.tag = 1000 + i;
        
        [self.view addSubview:imageView];
    }
    
    // 初始化当前时间数字图案
    for (int i = 0; i < 3; i++) {
        UIImageView *imageView = [[UIImageView alloc] init];
        
        imageView.bounds = CGRectMake(0, 0, 20, 40);
        imageView.center = CGPointMake(225 + i * 30, 80);
        imageView.tag = 1003 + i;
        
        [self.view addSubview:imageView];
    }
    
    // 初始化游戏笑脸button
    UIButton *faceButton = [UIButton buttonWithType:UIButtonTypeCustom];
    faceButton.bounds = CGRectMake(0, 0, 50, 50);
    faceButton.center = CGPointMake(160, 80);
    [faceButton setImage:[UIImage imageNamed:@"facesmile"] forState:UIControlStateNormal];
    faceButton.tag = -1;
    [faceButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:faceButton];
    
    // 初始化游戏中部背景
    UIImageView *midBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"mid_bg"]];
    midBackground.bounds = CGRectMake(0, 0, 310, 310);
    midBackground.center = CGPointMake(160, 284);
    midBackground.tag = -14;
    
    [self.view addSubview:midBackground];
    
    // 初始化地雷区
    _scrollView = [[UIScrollView alloc] init];
    _scrollView.bounds = CGRectMake(0, 0, 300, 300);
    _scrollView.center = CGPointMake(160, 284);
    _scrollView.tag = -20;
    
    [self.view addSubview:_scrollView];
    
    // 初始化游戏底部背景
    UIImageView *bottomBackground = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bottom_bg"]];
    bottomBackground.bounds = CGRectMake(0, 0, 310, 100);
    bottomBackground.center = CGPointMake(160, 498);
    bottomBackground.tag = -15;
    
    [self.view addSubview:bottomBackground];
    
    // 初始化音效button
    UIButton *soundButton = [UIButton buttonWithType:UIButtonTypeSystem];
    soundButton.bounds = CGRectMake(0, 0, 100, 33);
    soundButton.center = CGPointMake(269.5, 480);
    soundButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [soundButton setTitle:@"关闭音效" forState:UIControlStateNormal];
    soundButton.tag = -6;
    [soundButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:soundButton];
    
    // 重置难度
    UIButton *levelButton = [UIButton buttonWithType:UIButtonTypeSystem];
    levelButton.bounds = CGRectMake(0, 0, 100, 33);
    levelButton.center = CGPointMake(269.5, 515);
    levelButton.titleLabel.font = [UIFont systemFontOfSize:13];
    [levelButton setTitle:@"重置难度" forState:UIControlStateNormal];
    levelButton.tag = -7;
    [levelButton addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:levelButton];
    
    // 初始化游戏底部分数标题
    UILabel *scoreTitle = [[UILabel alloc] init];
    scoreTitle.bounds = CGRectMake(0, 0, 150, 15);
    scoreTitle.center = CGPointMake(67, 463);
    scoreTitle.textColor = [UIColor blackColor];
    scoreTitle.font = [UIFont systemFontOfSize:13];
    scoreTitle.textAlignment = 1;
    scoreTitle.text = @"当前难度下记录：";
    scoreTitle.tag = -16;
    
    [self.view addSubview:scoreTitle];
    
    // 初始化三个奖牌图案
    for (int i = 0; i < 3; i++) {
        NSString *name = i == 0 ? @"gold" : i == 1 ? @"silver" : @"bronze";
        UIImageView *medalView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@", name]]];
        medalView.bounds = CGRectMake(0, 0, 20, 20);
        medalView.center = CGPointMake(21, 484 + i * 23);
        medalView.tag = -17 - i;
        [self.view addSubview:medalView];
    }
    
    // 初始化三个记录label
    _goldLabel = [[UILabel alloc] init];;
    _goldLabel.bounds = CGRectMake(0, 0, 200, 15);
    _goldLabel.center = CGPointMake(133, 484);
    _goldLabel.textColor = [UIColor blackColor];
    _goldLabel.font = [UIFont systemFontOfSize:10];
    _goldLabel.textAlignment = 0;
    _goldLabel.tag = -3;
    
    [self.view addSubview:_goldLabel];
    
    _silverLabel = [[UILabel alloc] init];;
    _silverLabel.bounds = CGRectMake(0, 0, 200, 15);
    _silverLabel.center = CGPointMake(133, 507);
    _silverLabel.textColor = [UIColor blackColor];
    _silverLabel.font = [UIFont systemFontOfSize:10];
    _silverLabel.textAlignment = 0;
    _silverLabel.tag = -4;
    
    [self.view addSubview:_silverLabel];
    
    _bronzeLabel = [[UILabel alloc] init];;
    _bronzeLabel.bounds = CGRectMake(0, 0, 200, 15);
    _bronzeLabel.center = CGPointMake(133, 530);
    _bronzeLabel.textColor = [UIColor blackColor];
    _bronzeLabel.font = [UIFont systemFontOfSize:10];
    _bronzeLabel.textAlignment = 0;
    _bronzeLabel.tag = -5;
    
    [self.view addSubview:_bronzeLabel];
    
    /**
     *  手势
     */
    
    // 单击
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]
                                         initWithTarget:self
                                         action:@selector(processgestureReconizer:)];
    singleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:singleTap];
    
    // 长按
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                               initWithTarget:self
                                               action:@selector(processgestureReconizer:)];
    longPress.minimumPressDuration = 0.5;
    longPress.delegate = self;
    [self.view addGestureRecognizer:longPress];
    
    [self initializeGrids];
}

/**
 *  初始化网格
 */
- (void)initializeGrids {
    
    // 重置排行榜数据
    _key = [NSString stringWithFormat:@"%ld_%ld", _lines, _numberOfMines];
    _currentLevelScore = _allScore[_key];
    if (!_currentLevelScore) {
        _currentLevelScore = [[NSMutableDictionary alloc] init];
        for (int i = 0; i < 3; i++) {
            NSString *key = i == 0 ? @"gold" : i == 1 ? @"silver" : @"bronze";
            TYScoreInfo *info = [[TYScoreInfo alloc] initWithName:@"Leo" score:10000];
            NSData *data = [NSKeyedArchiver archivedDataWithRootObject:info];;
            [_currentLevelScore setObject:data forKey:key];
        }
    }
    
    // 调整雷区大小
    _scrollView.contentOffset = CGPointZero;
    _scrollView.contentSize = CGSizeMake(300, 30 * _lines);
    
    // 清除之前的地雷
    for (UIView *view in [_scrollView subviews]) {
        [view removeFromSuperview];
    }
    
    // 初始化地雷网格
    for (int i = 0; i < _lines; i++) {
        for (int j = 0; j < WIDTH; j++) {
            TYButton *button = [TYButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake(j * 30,i * 30, 30, 30);
            button.tag = i * 10 + j + 1;
            
            [button addTarget:self action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
            
            [_scrollView addSubview:button];
        }
    }
    
    // 重新布雷
    [self layMines];
}


/**
 *  布雷
 */
- (void)layMines {
    
    // 重置全局变量
    _numberOfRemandingGrid = _lines * WIDTH;
    _currentSecond = 0;
    _currentTime = 0;
    _numberOfMarkedGird = 0;
    
    // 重置时间和地雷计数
    [self updateCurrentTimeImage];
    [self updateCurrentRemandingMinesImage];
    
    // 更新分数排行榜
    [self updateCurrentScoreLeader];
    
    // 布雷
    [_positon removeAllObjects];
    for (int i = 0; i < _numberOfMines; i++) {
        BOOL isExsit = NO;
        NSInteger position = arc4random() % (WIDTH * _lines) + 1;
        for (NSNumber *key  in _positon) {
            if (key.integerValue == position) {
                isExsit = YES;
                break;
            }
        }
        if (isExsit) {
            i--;
        } else {
            [_positon addObject:[NSNumber numberWithInteger:position]];
        }
    }
    
    UIButton *faceButton = (UIButton *)[self.view viewWithTag:-1];
    [faceButton setImage:[UIImage imageNamed:@"facesmile"] forState:UIControlStateNormal];
    
    for (int i = 0; i < _lines; i++) {
        for (int j = 0; j < WIDTH; j++) {
            TYButton *button = (TYButton *)[_scrollView viewWithTag:i * 10 + j + 1];
            [button setImage:[UIImage imageNamed:@"blank"] forState:UIControlStateNormal];
            [button setImage:[UIImage imageNamed:@"blank_hl"] forState:UIControlStateHighlighted];
            button.isMine = NO;
            button.isMarked = NO;
            button.selected = NO;
            button.userInteractionEnabled = YES;
            button.numberOfsurroundMines = 0;
        }
    }
    
    for (NSNumber *key in _positon) {
        TYButton *button = (TYButton *)[_scrollView viewWithTag:key.integerValue];
        UIImage *image = [UIImage imageNamed:@"bombrevealed"];
        [button setImage:image forState:UIControlStateSelected];
        button.isMine = YES;
        
        [self operateOnSurroundGridsOfButton:button operation:^(TYButton *button) {
            
            button.numberOfsurroundMines++;
        }];
    }
    
    for (int i = 0; i < _lines; i++) {
        for (int j = 0; j < WIDTH; j++) {
            TYButton *button = (TYButton *)[_scrollView viewWithTag:i * 10 + j + 1];
            if (!button.isMine) {
                UIImage *image = [UIImage imageNamed:
                                  [NSString stringWithFormat:@"open%ld", button.numberOfsurroundMines]];
                [button setImage:image forState:UIControlStateSelected];
            }
        }
    }
}

/**
 *  响应button点击事件
 *
 *  @param sender 调用该方法的button对象本身
 */
- (void)buttonPressed:(TYButton *)sender{
    
    switch (sender.tag) {
        case -1:
            [self gameRestart];
            break;
            
        case -3:
            [self shareScore];
            break;
            
        case -6:
            _soundsOff = !_soundsOff;
            if (_soundsOff) {
                [sender setTitle:@"打开音效" forState:UIControlStateNormal];
            } else {
                [sender setTitle:@"关闭音效" forState:UIControlStateNormal];
            }
            break;
            
        case -7:
            [self resetGameLevel];
            break;
            
        default:
            [self dealGridClick:sender];
            break;
    }
    
}

/**
 *  重置游戏难度
 */
- (void)resetGameLevel {
    
    // 停止时间
    [self stopTimer];
    
    // 弹出框
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:@"改变游戏难度" message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"初级" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        _lines = 10;
        _numberOfMines = 10;
        [self initializeGrids];
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"中级" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        _lines = 25;
        _numberOfMines = 40;
        [self initializeGrids];
    }]];
    [alertVC addAction:[UIAlertAction actionWithTitle:@"高级" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        _lines = 48;
        _numberOfMines = 99;
        [self initializeGrids];
    }]];
    
    [self presentViewController:alertVC animated:YES completion:nil];
}

/**
 *  分享成绩
 */
- (void)shareScore {
    
}

/**
 *  处理网格点击
 *
 *  @param sender 调用该方法的网格TYButton对象
 */
- (void)dealGridClick:(TYButton *)sender {
    
    if (sender.isMarked) {
        return;
    }
    
    if (sender.isMine) {
        [sender setImage:[UIImage imageNamed:@"bombdeath"] forState:UIControlStateSelected];
        [self gameOver];
        return;
    }
    
    if (sender.selected) {
        return;
    }
    sender.selected = YES;
    sender.userInteractionEnabled = NO;
    _numberOfRemandingGrid--;
    
    if (_numberOfRemandingGrid == _numberOfMines) {
        [self gameOver];
        return;
    }
    
    [self startTimer];
    
    if (sender.numberOfsurroundMines == 0) {
        
        [self operateOnSurroundGridsOfButton:sender operation:^(TYButton *button) {
            if (button.numberOfsurroundMines == 0 && button.isMarked) {
                button.isMarked = NO;
                _numberOfMarkedGird--;
                [self updateCurrentRemandingMinesImage];
            }
            [self buttonPressed:button];
        }];
    }
    
}

/**
 *  数字匹配周围的标记展开周围网格
 *
 *  @param sender 调用该方法的网格TYButton对象本身
 */
- (void)selectedGridClick:(TYButton *)sender {
    
    __block NSInteger flag = 0;
    
    [self operateOnSurroundGridsOfButton:sender operation:^(TYButton *button) {
        
        if (button.isMarked) {
            flag++;
        }
    }];
    
    if (flag == sender.numberOfsurroundMines) {
        
        [self operateOnSurroundGridsOfButton:sender operation:^(TYButton *button) {
            [self buttonPressed:button];
        }];
    }
}

/**
 *  判断一个网格四周是否有其他网格，有就进行相关操作
 *
 *  @param sender 调用该方法的网格TYButton对象本身
 *  @param block  需要进行的操作代码块
 */
- (void)operateOnSurroundGridsOfButton:(TYButton *)sender operation:(void (^)(TYButton *button))block {
    
    BOOL up = NO;
    BOOL down = NO;
    BOOL left = NO;
    BOOL right = NO;
    
    // 判断上面是否有方块
    if (sender.tag - WIDTH >= 1) {
        TYButton *upButton = (TYButton *)[self.view viewWithTag:sender.tag - 10];
        block(upButton);
        up = YES;
    }
    // 判断下面是否有方块
    if (sender.tag + WIDTH <= WIDTH * _lines) {
        TYButton *downButton = (TYButton *)[self.view viewWithTag:sender.tag + 10];
        block(downButton);
        down = YES;
    }
    // 判断左边是否有方块
    if (sender.tag % WIDTH != 1) {
        TYButton *leftButton = (TYButton *)[self.view viewWithTag:sender.tag - 1];
        block(leftButton);
        left = YES;
    }
    // 判断右边是否有方块
    if (sender.tag % WIDTH != 0) {
        TYButton *rightButton = (TYButton *)[self.view viewWithTag:sender.tag + 1];
        block(rightButton);
        right = YES;
    }
    // 判断左上方是否有方块
    if (up && left) {
        TYButton *upLeftButton = (TYButton *)[self.view viewWithTag:sender.tag - 10 - 1];
        block(upLeftButton);
    }
    // 判断右上方是否有方块
    if (up && right) {
        TYButton *upRightButton = (TYButton *)[self.view viewWithTag:sender.tag - 10 + 1];
        block(upRightButton);
    }
    // 判断左下方是否有方块
    if (down && left) {
        TYButton *downLeftButton = (TYButton *)[self.view viewWithTag:sender.tag + 10 - 1];
        block(downLeftButton);
    }
    // 判断右下方是否有方块
    if (down && right) {
        TYButton *downRightButton = (TYButton *)[self.view viewWithTag:sender.tag + 10 + 1];
        block(downRightButton);
    }
}

/**
 *  更新当前时间图片显示
 */
- (void)updateCurrentTimeImage {
    
    [self updateImageViewWithTag:1003 numberOfCalculate:_currentSecond];
}

/**
 *  更新当前剩余地雷图片显示
 */
- (void)updateCurrentRemandingMinesImage {
    
    NSInteger remandingMines = _numberOfMines - _numberOfMarkedGird;
    [self updateImageViewWithTag:1000 numberOfCalculate:remandingMines];
}

/**
 *  更新数字图片
 */
- (void)updateImageViewWithTag:(NSInteger)tag numberOfCalculate:(NSInteger)num {
    
    NSInteger hundreds, decade, unit, number;
    hundreds = num / 100;
    decade = num % 100 / 10;
    unit = num % 100 % 10;
    
    for (int i = 0; i < 3; i++) {
        number = i == 0 ? hundreds :
        i == 1 ? decade :
        unit;
        UIImageView *imageView = (UIImageView *)[self.view viewWithTag:tag + i];
        imageView.image = [UIImage imageWithContentsOfFile:
                           [[NSBundle mainBundle] pathForAuxiliaryExecutable:
                            [NSString stringWithFormat:@"%ld.png", number]]];
    }
}

/**
 *  更新当前记录排行
 */
- (void)updateCurrentScoreLeader {
    
    // 解码
    NSData *gold = [_currentLevelScore valueForKey:@"gold"];
    TYScoreInfo *goldInfo = [NSKeyedUnarchiver unarchiveObjectWithData:gold];
    _goldLabel.text = [goldInfo description];
    
    NSData *silver = [_currentLevelScore valueForKey:@"silver"];
    TYScoreInfo *silverInfo = [NSKeyedUnarchiver unarchiveObjectWithData:silver];
    _silverLabel.text = [silverInfo description];
    
    NSData *bronze = [_currentLevelScore valueForKey:@"bronze"];
    TYScoreInfo *bronzeInfo = [NSKeyedUnarchiver unarchiveObjectWithData:bronze];
    _bronzeLabel.text = [bronzeInfo description];
}

/**
 *  游戏开场动画
 */

- (void)gameBeginAnimation {
    
    NSString *imagePath = [[NSBundle mainBundle] pathForAuxiliaryExecutable:@"app_begin.png"];
    UIImageView *beginImage = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:imagePath]];
    beginImage.frame = self.view.bounds;
    [self.view addSubview:beginImage];
    
    [UIView animateWithDuration:3.0 animations:^{
        beginImage.alpha = 0;
    } completion:^(BOOL finished) {
        [beginImage removeFromSuperview];
        [self initializeDataSoure];
        [self initializeAppearance];
    }];
}

/**
 *  游戏结束
 */
- (void)gameOver {
    
    for (int i = 1; i <= WIDTH * _lines; i++) {
        TYButton *button = (TYButton *)[_scrollView viewWithTag:i];
        if (button.isMarked && !button.isMine) {
            [button setImage:[UIImage imageNamed:@"bombmisflagged"] forState:UIControlStateSelected];
        }
        button.selected = YES;
        button.userInteractionEnabled = NO;
    }
    
    [self stopTimer];
    
    TYButton *button = (TYButton *)[self.view viewWithTag:-1];
    
    // 踩到地雷，游戏结束
    if (_numberOfRemandingGrid != _numberOfMines) {
        
        if (!_soundsOff) {
            // 失败音效播放
            AudioServicesPlaySystemSound(_failureSoundID);
        }
        
        [button setImage:[UIImage imageNamed:@"facedead"]forState:UIControlStateNormal];
    }
    // 排雷成功，游戏结束
    else {
        
        if (!_soundsOff) {
            // 成功音效播放
            AudioServicesPlaySystemSound(_successSoundID);
        }
        
        [button setImage:[UIImage imageNamed:@"facewin"]forState:UIControlStateNormal];
        [self judgeScore];
        [self updateCurrentScoreLeader];
        [_allScore setObject:_currentLevelScore forKey:_key];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setObject:_allScore forKey:@"allScore"];
        [userDefaults synchronize];
    }
    
}

/**
 *  判断当前成绩是否能进入前三
 */
- (void)judgeScore {
    
    TYScoreInfo *currentInfo = [[TYScoreInfo alloc] initWithName:@"Leo" score:_currentTime];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:currentInfo];
    
    NSData *gold = [_currentLevelScore valueForKey:@"gold"];
    TYScoreInfo *goldInfo = [NSKeyedUnarchiver unarchiveObjectWithData:gold];
    NSData *silver = [_currentLevelScore valueForKey:@"silver"];
    TYScoreInfo *silverInfo = [NSKeyedUnarchiver unarchiveObjectWithData:silver];
    NSData *bronze = [_currentLevelScore valueForKey:@"bronze"];
    TYScoreInfo *bronzeInfo = [NSKeyedUnarchiver unarchiveObjectWithData:bronze];
    
    if (_currentTime < goldInfo.score.doubleValue) {
        [_currentLevelScore setObject:silver forKey:@"bronze"];
        [_currentLevelScore setObject:gold forKey:@"silver"];
        [_currentLevelScore setObject:data forKey:@"gold"];
        return;
    }
    
    if (_currentTime < silverInfo.score.doubleValue) {
        [_currentLevelScore setObject:silver forKey:@"bronze"];
        [_currentLevelScore setObject:data forKey:@"silver"];
        return;
    }
    
    if (_currentTime < bronzeInfo.score.doubleValue) {
        [_currentLevelScore setObject:data forKey:@"bronze"];
    }
}

/**
 *  游戏重新开始
 */
- (void)gameRestart {
    
    [self stopTimer];
    [self layMines];
}

#pragma mark - UIAlertViewDelegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch (buttonIndex) {
        case 0:
            break;
        case 1:
            break;
            
        default:
            break;
    }
}

#pragma mark - 手势

- (void)processgestureReconizer:(UIGestureRecognizer *)gesture{
    
    CGPoint currentLocation = [_touch locationInView:_scrollView];
    
    // 点击事件
    if ([gesture isKindOfClass:[UITapGestureRecognizer class]]) {
        
        for (id object in [_scrollView subviews]) {
            
            if ([object isMemberOfClass:[TYButton class]]) {
                TYButton *button = (TYButton *)object;
                CGPoint point = button.center;
                if (ABS(point.x - currentLocation.x) < 15 &&
                    ABS(point.y - currentLocation.y) < 15) {
                    if (button.isSelected) {
                        [self selectedGridClick:button];
                    }
                }
            }
        }
    }
    // 长按事件
    else if ([gesture isKindOfClass:[UILongPressGestureRecognizer class]] &&
        gesture.state == UIGestureRecognizerStateBegan) {
        
        for (id object in [_scrollView subviews]) {
            
            if ([object isMemberOfClass:[TYButton class]]) {
                TYButton *button = (TYButton *)object;
                CGPoint point = button.center;
                if(!button.selected) {
                    if (ABS(point.x - currentLocation.x) < 15 &&
                        ABS(point.y - currentLocation.y) < 15) {
                        if (button.isMarked) {
                            [button setImage:[UIImage imageNamed:@"blank"] forState:UIControlStateNormal];
                            _numberOfMarkedGird--;
                        } else {
                            [button setImage:[UIImage imageNamed:@"bombflagged"] forState:UIControlStateNormal];
                            _numberOfMarkedGird++;
                        }
                        button.isMarked = !button.isMarked;
                        if (_numberOfMarkedGird <= _numberOfMines) {
                            [self updateCurrentRemandingMinesImage];
                        }
                    }
                }
            }
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    
    _touch = touch;
    return YES;
}

#pragma mark - Timer processing methods

/**
 *  开始计时
 */
- (void)startTimer {
    
    // 判断是否存在，若不存在则注册一个
    if (!_timer) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.01
                                                  target:self
                                                selector:@selector(timerFireMethod:)
                                                userInfo:nil
                                                 repeats:YES];
    }
    // 配置timer的首次触发时间
    _timer.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
}

/**
 *  暂停计时
 */
- (void)pauseTimer {
    
    // 若timer存在且激活，则暂停
    if (_timer && _timer.isValid) {
        _timer.fireDate = [NSDate distantFuture];
    }
}

/**
 *  停止计时
 */
- (void)stopTimer {
    
    // 若timer存在且激活，则停止注销
    if (_timer && _timer.isValid) {
        [_timer invalidate];
        _timer = nil;
    }
}

/**
 *  每隔特定时间就会调用的方法
 *
 *  @param timer 调用该方法的NSTimer对象本身
 */
- (void)timerFireMethod:(NSTimer *)timer {
    _currentTime += 0.01;
    if (_currentTime - 1 > _currentSecond) {
        _currentSecond++;
        if (_currentSecond < 1000) {
            [self updateCurrentTimeImage];
        }
    }
}

@end
