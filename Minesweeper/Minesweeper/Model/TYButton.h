//
//  TYButton.h
//  Minesweeper
//
//  Created by rimi on 14-7-16.
//  Copyright (c) 2014年 Leo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TYButton : UIButton

@property (nonatomic, assign) BOOL isMine;
@property (nonatomic, assign) NSInteger numberOfsurroundMines;
@property (nonatomic, assign) BOOL isMarked;

@end
