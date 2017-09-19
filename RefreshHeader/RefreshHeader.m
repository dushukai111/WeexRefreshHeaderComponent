//
//  RefreshHeader.m
//  AiPinChe
//
//  Created by 杜书凯 on 2017/9/15.
//  Copyright © 2017年 杜书凯. All rights reserved.
//

#import "RefreshHeader.h"
#define normal_text @"下拉刷新.."
#define prepareRefresh_text @"释放刷新.."
#define refreshing_text @"正在刷新.."
typedef NS_ENUM(NSInteger,WXComponentRefreshHeaderStatus){
    WXComponentRefreshHeaderStatusNormal,
    WXComponentRefreshHeaderStatusRefreshing,
    WXComponentRefreshHeaderStatusPrepare
};
typedef NS_ENUM(NSInteger,WXComponentRefreshType){
    WXComponentRefreshTypeNormal,
    WXComponentRefreshTypeGif
};
@interface RefreshHeader()
@property (nonatomic,strong) NSString *prepareRefreshText;
@property (nonatomic,strong) NSString *refreshingText;
@property (nonatomic,strong) NSString *normalText;
@property (nonatomic,strong) UIImageView *refreshImageView;
@property (nonatomic,strong) UILabel *refreshLabel;
@property (nonatomic,strong) UILabel *lastRefreshTimeLabel;
@property (nonatomic,strong) UIActivityIndicatorView *refreshIndicator;
@property (nonatomic,assign) WXComponentRefreshHeaderStatus status;
@property (nonatomic,assign) WXComponentRefreshType refreshType;
@property (nonatomic,assign) BOOL showTime;
@property (nonatomic,assign) BOOL showText;
@property (nonatomic,strong) NSDate *lastRefreshTime;
@property (nonatomic,assign) BOOL completeFirstRefresh;//完成第一次刷新，用于控制第一次刷新前是否显示time
@property (nonatomic,assign) BOOL finishUpdateTime;//完成时间更新
@property (nonatomic,strong) NSMutableArray<UIImage*> *images;
@end
@implementation RefreshHeader

- (instancetype)initWithRef:(NSString *)ref type:(NSString *)type styles:(NSDictionary *)styles attributes:(NSDictionary *)attributes events:(NSArray *)events weexInstance:(WXSDKInstance *)weexInstance{
    self=[super initWithRef:ref type:type styles:styles attributes:attributes events:events weexInstance:weexInstance];
    if (self) {
        self.prepareRefreshText = [WXConvert NSString:[attributes objectForKey:@"prepareRefreshText"]];
        self.refreshingText = [WXConvert NSString:[attributes objectForKey:@"refreshingText"]];
        self.normalText = [WXConvert NSString:[attributes objectForKey:@"normalText"]];
        _status=WXComponentRefreshHeaderStatusNormal;
        //是否显示上次刷新时间
        NSString *timeShow=[self.attributes objectForKey:@"showTime"];
        if (timeShow&&[timeShow isKindOfClass:[NSString class]]&&[timeShow isEqualToString:@"false"]) {
            self.showTime=NO;
        }else{
            self.showTime=YES;
        }
        NSString *showText=[self.attributes objectForKey:@"showText"];
        if (showText&&[showText isKindOfClass:[NSString class]]&&[showText isEqualToString:@"false"]) {
            self.showText=NO;
        }else{
            self.showText=YES;
        }
        NSString *refreshType=[self.attributes objectForKey:@"refreshType"];
        if (refreshType&&[refreshType isKindOfClass:[NSString class]]&&[refreshType isEqualToString:@"gif"]) {
            self.refreshType=WXComponentRefreshTypeGif;
        }else{
            self.refreshType=WXComponentRefreshTypeNormal;
        }
    }
    return self;
}
- (UIView *)loadView{
    return [[UIView alloc] init];
}
- (void)viewDidLoad{
    [super viewDidLoad];
    
    UIView *contentView=[[UIView alloc] init];
    [self.view addSubview:contentView];
    
    self.refreshImageView=[[UIImageView alloc] init];
    self.refreshImageView.translatesAutoresizingMaskIntoConstraints=NO;
    [contentView addSubview:self.refreshImageView];
    //判断当前是普通刷新还是gif刷新
    UIImage *image=nil;//主要用于下面布局时的图片尺寸
    if (self.refreshType==WXComponentRefreshTypeGif) {//gif
        NSString *gifImgPath=[[[NSBundle mainBundle] pathForResource:@"wx_refresh_header" ofType:@"bundle"] stringByAppendingPathComponent:@"gif"];
        NSFileManager *fileManager=[NSFileManager defaultManager];
        NSArray *subFiles=[fileManager subpathsAtPath:gifImgPath];
        if (subFiles.count>0) {
            NSRegularExpression *regular=[NSRegularExpression regularExpressionWithPattern:@"[\\d]+" options:NSRegularExpressionCaseInsensitive error:nil];
            NSArray *sortArray=[subFiles sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                NSString *str1=(NSString*)obj1;
                NSString *str2=(NSString*)obj2;
                NSInteger number1=[[str1 substringWithRange:[regular firstMatchInString:str1 options:NSMatchingReportCompletion range:NSMakeRange(0, str1.length)].range] integerValue];
                NSInteger number2=[[str2 substringWithRange:[regular firstMatchInString:str2 options:NSMatchingReportCompletion range:NSMakeRange(0, str2.length)].range] integerValue];
                return [[NSNumber numberWithInteger:number1] compare:[NSNumber numberWithInteger:number2]];
            }];
            self.images=[[NSMutableArray<UIImage*> alloc] init];
            for (NSString *fileName in sortArray) {
                NSString *imgPath=[gifImgPath stringByAppendingPathComponent:fileName];
                UIImage *img=[UIImage imageWithContentsOfFile:imgPath];
                if (img) {
                    [self.images addObject:img];
                }
            }
            if (self.images.count>0) {
                image=[self.images objectAtIndex:0];
                self.refreshImageView.image=image;
            }
            self.refreshImageView.animationImages=self.images;
        }
    }else{//普通
        NSString *imagePath=[[[NSBundle mainBundle] pathForResource:@"wx_refresh_header" ofType:@"bundle"] stringByAppendingPathComponent:@"normal/arrow"];
        image=[UIImage imageWithContentsOfFile:imagePath];
        self.refreshImageView.image=image;
    }
    
    self.refreshIndicator=[[UIActivityIndicatorView alloc] init];
    self.refreshIndicator.activityIndicatorViewStyle=UIActivityIndicatorViewStyleGray;
    self.refreshIndicator.hidden=YES;
    self.refreshIndicator.translatesAutoresizingMaskIntoConstraints=NO;
    [contentView addSubview:self.refreshIndicator];
    
    UIColor *timeColor=nil;
    NSLog(@"%@",self.styles);
//    if ([self.styles objectForKey:@"timeColor"]) {
//        NSString *colorStr=[self.styles objectForKey:@"timeColor"];
//        timeColor=[self colorWithHexString:colorStr];
//    }
    self.lastRefreshTimeLabel=[[UILabel alloc] init];
    self.lastRefreshTimeLabel.font=[UIFont systemFontOfSize:14.0];
    self.lastRefreshTimeLabel.textColor=timeColor?timeColor:[UIColor grayColor];
    self.lastRefreshTimeLabel.translatesAutoresizingMaskIntoConstraints=NO;
    self.lastRefreshTimeLabel.hidden=YES;
    [contentView addSubview:self.lastRefreshTimeLabel];
    
    UIColor *refreshColor=nil;
//    if ([self.styles objectForKey:@"refreshColor"]) {
//        NSString *colorStr=[self.styles objectForKey:@"refreshColor"];
//        refreshColor=[self colorWithHexString:colorStr];
//    }
    self.refreshLabel=[[UILabel alloc] init];
    self.refreshLabel.font=[UIFont systemFontOfSize:14.0];
    self.refreshLabel.text=self.normalText?self.normalText:normal_text;
    self.refreshLabel.textColor=refreshColor?refreshColor:[UIColor grayColor];
    self.refreshLabel.translatesAutoresizingMaskIntoConstraints=NO;
    [contentView addSubview:self.refreshLabel];
    
    //约束
      //contentView
    contentView.translatesAutoresizingMaskIntoConstraints=NO;
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:contentView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0]];
    
    if (self.showText) {
        //refreshImageView
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshImageView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0]];
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:30]];
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.refreshImageView attribute:NSLayoutAttributeHeight multiplier:image?image.size.width/image.size.height:1.0 constant:0]];
        
        //refreshIndicator
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.refreshImageView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.refreshImageView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        
        //refreshLabel
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.refreshImageView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:15]];
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0]];
    }else{
        self.refreshLabel.hidden=YES;
        //refreshImageView
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshImageView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0]];
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshImageView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshImageView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:30]];
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshImageView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.refreshImageView attribute:NSLayoutAttributeHeight multiplier:image?image.size.width/image.size.height:1.0 constant:0]];
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshImageView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:contentView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0]];
        
        //refreshIndicator
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.refreshImageView attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
        [contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.refreshImageView attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    }
    
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self.view.superview isKindOfClass:[UIScrollView class]]) {
            [self.view.superview addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
        }
    });
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"contentOffset"]) {
        if (self.status==WXComponentRefreshHeaderStatusRefreshing) {
            return;
        }
        UIScrollView *scrollview=(UIScrollView*)object;
        if (scrollview.contentOffset.y<-self.view.frame.size.height) {
            if (scrollview.tracking) {
                if (self.status!=WXComponentRefreshHeaderStatusPrepare) {
                    self.status=WXComponentRefreshHeaderStatusPrepare;
                }
            }else{
                self.status=WXComponentRefreshHeaderStatusRefreshing;
            }
        }else{
            if (!scrollview.tracking&&self.status==WXComponentRefreshHeaderStatusPrepare) {
                self.status=WXComponentRefreshHeaderStatusRefreshing;
            }else{
                if (self.status!=WXComponentRefreshHeaderStatusNormal) {
                    self.status=WXComponentRefreshHeaderStatusNormal;
                }
                
            }
            
        }
        if (self.showTime) {//更新时间label
            if (scrollview.contentOffset.y<=-10) {
                if (!self.finishUpdateTime) {
                    [self updateTime];
                    self.finishUpdateTime=YES;
                }
                
            }else{
                self.finishUpdateTime=NO;
            }
        }
        //图片随滚动不断切换gif中的图片
        if (self.refreshType==WXComponentRefreshTypeGif&&self.images.count>0&&scrollview.contentOffset.y<0) {
            NSUInteger imageIndex=-(NSInteger)scrollview.contentOffset.y%self.images.count;
            self.refreshImageView.image=[self.images objectAtIndex:imageIndex];
        }
    }
}
- (void)updateTime{
    NSString *timeStr=nil;
    NSInteger currentTimeInterval=[[NSDate date] timeIntervalSince1970];
    NSInteger lastRefreshTimeInterval=[self.lastRefreshTime timeIntervalSince1970];
    NSInteger duration=currentTimeInterval-lastRefreshTimeInterval;
    if (duration<=60) {//60以内(含)，显示上次刷新为刚刚
        timeStr=@"上次刷新:刚刚";
    }else{
        NSInteger currentDay=currentTimeInterval/60/60/24;
        NSInteger lastRefreshDay=lastRefreshTimeInterval/60/60/24;
        NSDateFormatter *format=[[NSDateFormatter alloc] init];
        [format setDateFormat:@"HH:mm:ss"];
        if (currentDay==lastRefreshDay) {
            timeStr=[NSString stringWithFormat:@"上次刷新:今天 %@",[format stringFromDate:self.lastRefreshTime]];
        }else if (currentDay-lastRefreshDay==1){
            timeStr=[NSString stringWithFormat:@"上次刷新:昨天 %@",[format stringFromDate:self.lastRefreshTime]];
        }else{
            [format setDateFormat:@"上次刷新:MM月dd日 HH:mm:ss"];
            timeStr=[format stringFromDate:self.lastRefreshTime];
        }
    }
    self.lastRefreshTimeLabel.text=timeStr;
    [self dealWithLayout];
}
- (void)setStatus:(WXComponentRefreshHeaderStatus)status{
    _status=status;
    UIScrollView *scrollview=(UIScrollView*)self.view.superview;
    if (status==WXComponentRefreshHeaderStatusNormal) {
        self.refreshLabel.text=self.normalText?self.normalText:normal_text;
        if (self.refreshType==WXComponentRefreshTypeGif) {
            return;
        }
        [UIView animateWithDuration:0.3 animations:^{
            self.refreshImageView.transform=CGAffineTransformMakeRotation(0);
        } completion:^(BOOL finished) {
            
        }];
    }else if (status==WXComponentRefreshHeaderStatusPrepare){
        self.refreshLabel.text=self.prepareRefreshText?self.prepareRefreshText:prepareRefresh_text;
        if (self.refreshType==WXComponentRefreshTypeGif) {
            return;
        }
        [UIView animateWithDuration:0.3 animations:^{
            self.refreshImageView.transform=CGAffineTransformMakeRotation(M_PI);
        } completion:^(BOOL finished) {
            
        }];
    }else if (status==WXComponentRefreshHeaderStatusRefreshing){
        self.refreshLabel.text=self.refreshingText?self.refreshingText:refreshing_text;
        scrollview.contentInset=UIEdgeInsetsMake(self.view.frame.size.height, 0, 0, 0);
        if (self.refreshType==WXComponentRefreshTypeGif) {
            [self.refreshImageView startAnimating];
        }else{
            self.refreshIndicator.hidden=NO;
            self.refreshImageView.hidden=YES;
            [self.refreshIndicator startAnimating];
            [UIView animateWithDuration:0.2 animations:^{
                scrollview.contentOffset=CGPointMake(0, -self.view.frame.size.height);
            }];
        }
        self.lastRefreshTime=[NSDate date];
        [self fireEvent:@"onRefresh" params:nil];
    }
    [self dealWithLayout];
}
WX_EXPORT_METHOD(@selector(endRefreshing))
- (void)endRefreshing{
    if ([self.view.superview isKindOfClass:[UIScrollView class]]) {
        [UIView animateWithDuration:0.2 animations:^{
            UIScrollView *scrollview=(UIScrollView*)self.view.superview;
            scrollview.contentInset=UIEdgeInsetsMake(0, scrollview.contentInset.left, scrollview.contentInset.bottom, scrollview.contentInset.right);
        } completion:^(BOOL finished) {
            self.status=WXComponentRefreshHeaderStatusNormal;
            if (self.refreshType==WXComponentRefreshTypeGif) {
                [self.refreshImageView stopAnimating];
            }else{
                [self.refreshIndicator stopAnimating];
                self.refreshIndicator.hidden=YES;
                self.refreshImageView.hidden=NO;
            }
            
            self.completeFirstRefresh=YES;//完成第一次刷新
            self.finishUpdateTime=NO;
            [self dealWithLayout];
        }];
    }
    
}
//处理上次刷新时间label的显示与布局
- (void)dealWithLayout{
    if (!self.completeFirstRefresh) {
        return;
    }
    if (self.showTime&&self.showText) {
        self.lastRefreshTimeLabel.hidden=NO;
        CGSize textSize1=[self.lastRefreshTimeLabel.text boundingRectWithSize:CGSizeMake(1000, 20) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:self.lastRefreshTimeLabel.font} context:nil].size;
        CGSize textSize2=[self.refreshLabel.text boundingRectWithSize:CGSizeMake(1000, 20) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:self.refreshLabel.font} context:nil].size;
        //先移除约束
        for (NSLayoutConstraint *cons in self.refreshLabel.superview.constraints) {
            if (cons.firstItem==self.refreshLabel||cons.firstItem==self.lastRefreshTimeLabel) {
                [self.refreshLabel.superview removeConstraint:cons];
            }
        }
        if (textSize1.width>textSize2.width) {
            //lastRefreshTimeLabel
            [self.refreshLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.lastRefreshTimeLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.refreshImageView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:15]];
            [self.refreshLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.lastRefreshTimeLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.refreshLabel.superview attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:-2]];
            [self.refreshLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.lastRefreshTimeLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.refreshLabel.superview attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0]];
            //refreshLabel
            self.refreshLabel.translatesAutoresizingMaskIntoConstraints=NO;
            [self.refreshLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.lastRefreshTimeLabel attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
            [self.refreshLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.refreshLabel.superview attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:2]];
        }else{
            //lastRefreshTimeLabel
            [self.refreshLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.lastRefreshTimeLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.refreshLabel attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
            [self.refreshLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.lastRefreshTimeLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.refreshLabel.superview attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:-2]];
            
            //refreshLabel
            self.refreshLabel.translatesAutoresizingMaskIntoConstraints=NO;
            [self.refreshLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.refreshImageView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:15]];
            [self.refreshLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.refreshLabel.superview attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:2]];
            [self.refreshLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.refreshLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.refreshLabel.superview attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0]];
        }
    }else if(self.showTime&&!self.showText){
        if (!self.lastRefreshTimeLabel.hidden) {
            return;
        }
        self.refreshLabel.hidden=YES;
        self.lastRefreshTimeLabel.hidden=NO;
        for (NSLayoutConstraint *cons in self.refreshLabel.superview.constraints) {
            if (cons.firstItem==self.refreshLabel||cons.firstItem==self.lastRefreshTimeLabel) {
                [self.refreshLabel.superview removeConstraint:cons];
            }
            if (cons.firstItem==self.refreshImageView&&cons.firstAttribute==NSLayoutAttributeTrailing) {
                [self.refreshLabel.superview removeConstraint:cons];
            }
        }
        [self.refreshLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.lastRefreshTimeLabel attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.refreshImageView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:15]];
        [self.refreshLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.lastRefreshTimeLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.refreshLabel.superview attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
        [self.refreshLabel.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.lastRefreshTimeLabel attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.refreshLabel.superview attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0]];
    }
}
- (UIColor *)colorWithHexString: (NSString *)color
{
    NSString *cString = [[color stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];
    
    // String should be 6 or 8 characters
    if ([cString length] < 6) {
        return [UIColor clearColor];
    }
    
    // strip 0X if it appears
    if ([cString hasPrefix:@"0X"])
        cString = [cString substringFromIndex:2];
    if ([cString hasPrefix:@"#"])
        cString = [cString substringFromIndex:1];
    if ([cString length] != 6)
        return [UIColor clearColor];
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    
    //r
    NSString *rString = [cString substringWithRange:range];
    
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    
    return [UIColor colorWithRed:((float) r / 255.0f) green:((float) g / 255.0f) blue:((float) b / 255.0f) alpha:1.0f];
}
- (void)dealloc{
    [self.view.superview removeObserver:self forKeyPath:@"contentOffset"];
}
@end
