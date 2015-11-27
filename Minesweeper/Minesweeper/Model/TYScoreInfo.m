//
//  TYScoreInfo.m
//  Minesweeper
//
//  Created by rimi on 14-7-23.
//  Copyright (c) 2014年 Leo. All rights reserved.
//

#import "TYScoreInfo.h"

@implementation TYScoreInfo

- (id)initWithName:(NSString *)name score:(double)score {
    self = [super init];
    if (self) {
        _name = name;
        _score = [NSNumber numberWithDouble:score];
        [self setDateWithCurrentDate];
    }
    return self;
}

- (void)setDateWithCurrentDate {
    
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init]; //创建日期格式器
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"]; //设定日期格式
    [formatter setTimeZone:[NSTimeZone localTimeZone]]; //设定日期时区
    
    _date = [formatter stringFromDate:date];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%.2f %@", self.score.doubleValue, self.date];
}

// 对象编码为NSData
- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_score forKey:@"score"];
    [aCoder encodeObject:_date forKey:@"date"];
}

// NSData解码为对象
- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super init];
    if (self) {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.score = [aDecoder decodeObjectForKey:@"score"];
        _date = [aDecoder decodeObjectForKey:@"date"];
    }
    return self;
}

@end
