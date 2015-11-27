//
//  TYScoreInfo.h
//  Minesweeper
//
//  Created by rimi on 14-7-23.
//  Copyright (c) 2014年 Leo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TYScoreInfo : NSObject <NSCoding>

@property (nonatomic, copy) NSString *name;
@property (nonatomic, retain) NSNumber *score;
@property (nonatomic, copy, readonly) NSString *date;

- (id)initWithName:(NSString *)name score:(double)score;

@end
