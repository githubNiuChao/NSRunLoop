//
//  NCViewController.m
//  RunLoop
//
//  Created by niuchao on 2018/3/15.
//  Copyright © 2018年 niuchao. All rights reserved.
//

/** 拓展思考

 分析卡顿的原因
--所有cell加载都在主线程的一次Runloop循环里面!!!UI的渲染也属于Runloop的事情!!!
 卡顿就是因为一次Runloop循环,渲染的图片太多了,而且都是高清大图!!!

 解决思路 --->让Runloop循环每次只加载一张图片
 步骤:
--通过观察(oberserver)Runloop的循环;
---Runloop循环一次,只加载一张图片;
     ----> Cell数据源加载图片的代码放在数组列表中去.
     ----> Runloop循环一次,就从数组里面拿到一张图片加载


 查看系统CFRunloop代码,我们可以知道,对应之前的说的Runloop包含三个部分, Timer, Source ,Observe;
 ----里面包含这三个结构体指针
 typedef struct CF_BRIDGED_MUTABLE_TYPE(id) __CFRunLoopSource * CFRunLoopSourceRef;
 typedef struct CF_BRIDGED_MUTABLE_TYPE(id) __CFRunLoopObserver * CFRunLoopObserverRef;
 typedef struct CF_BRIDGED_MUTABLE_TYPE(NSTimer) __CFRunLoopTimer * CFRunLoopTimerRef;

 ----运行循环观察者活动
  Run Loop Observer Activities
typedef CF_OPTIONS(CFOptionFlags, CFRunLoopActivity) {
    kCFRunLoopEntry = (1UL << 0),               //进入Runloop循环通知
    kCFRunLoopBeforeTimers = (1UL << 1),        //Runloop在处理Timer之前通知
    kCFRunLoopBeforeSources = (1UL << 2),       //Runloop在处理Sources之前通知
    kCFRunLoopBeforeWaiting = (1UL << 5),       //Runloop在处理完Sources/Timer之后即将要进入Waiting状态通知
    kCFRunLoopAfterWaiting = (1UL << 6),        //Runloop在结束Waiting状态即将要处理Sources/Timer时通知,与BeforeTimers/BeforeSources异曲同工,但是它可以观察即将要处理Sources/Timer,BeforeTimers/BeforeSources只能观察各种对应的....!!!
    kCFRunLoopExit = (1UL << 7),                //Runloop退出通知
    kCFRunLoopAllActivities = 0x0FFFFFFFU       //Runloop以上所有的活动都会通知!!!
};

-----OC里面回调有Block,代理,KVO!!! 但是在C语言里面只有函数指针
 
 */


#import "NCViewController.h"
#import "NCCFRunLoopWorkDistribution.h"

static NSString *IDENTIFIER = @"IDENTIFIER";

static CGFloat CELL_HEIGHT = 135.f;

@interface NCViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *ncTableView;

@end

@implementation NCViewController



- (void)loadView {
    self.view = [UIView new];
    self.ncTableView = [UITableView new];
    self.ncTableView.delegate = self;
    self.ncTableView.dataSource = self;
    [self.view addSubview:self.ncTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.ncTableView.frame = self.view.bounds;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.ncTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:IDENTIFIER];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 520;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:IDENTIFIER];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.currentIndexPath = indexPath;
    [NCViewController task_5:cell indexPath:indexPath];
    [NCViewController task_1:cell indexPath:indexPath];


    //添加Runloop的任务列表里面
    [[NCCFRunLoopWorkDistribution sharedRunLoopWorkDistribution] addTask:^BOOL(void) {
        if (![cell.currentIndexPath isEqual:indexPath]) {
            return NO;
        }
        [NCViewController task_2:cell indexPath:indexPath];
        return YES;
    } withKey:indexPath];

    [[NCCFRunLoopWorkDistribution sharedRunLoopWorkDistribution] addTask:^BOOL(void) {
        if (![cell.currentIndexPath isEqual:indexPath]) {
            return NO;
        }
        [NCViewController task_3:cell indexPath:indexPath];
        return YES;
    } withKey:indexPath];

    [[NCCFRunLoopWorkDistribution sharedRunLoopWorkDistribution] addTask:^BOOL(void) {
        if (![cell.currentIndexPath isEqual:indexPath]) {
            return NO;
        }
        [NCViewController task_4:cell indexPath:indexPath];
        return YES;
    } withKey:indexPath];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return CELL_HEIGHT;
}


+ (void)task_5:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    for (NSInteger i = 1; i <= 5; i++) {
        [[cell.contentView viewWithTag:i] removeFromSuperview];
    }
}

+ (void)task_1:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 300, 25)];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor redColor];
    label.text = [NSString stringWithFormat:@"%zd - 图纸索引是重中之重", indexPath.row];
    label.font = [UIFont boldSystemFontOfSize:13];
    label.tag = 1;
    [cell.contentView addSubview:label];
}

+ (void)task_2:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath  {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(105, 20, 85, 85)];
    imageView.tag = 2;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Image" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.image = image;
    [UIView transitionWithView:cell.contentView duration:0.3 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [cell.contentView addSubview:imageView];
    } completion:^(BOOL finished) {
    }];
}

+ (void)task_3:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath  {
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(200, 20, 85, 85)];
    imageView.tag = 3;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Image" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.image = image;
    [UIView transitionWithView:cell.contentView duration:0.3 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [cell.contentView addSubview:imageView];
    } completion:^(BOOL finished) {
    }];
}

+ (void)task_4:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath  {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 99, 300, 35)];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor colorWithRed:0 green:100.f/255.f blue:0 alpha:1];
    label.text = [NSString stringWithFormat:@"%zd - 绘制大图像的优先级较低。 应分配到不同的运行循环中.", indexPath.row];
    label.font = [UIFont boldSystemFontOfSize:13];
    label.tag = 4;

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(5, 20, 85, 85)];
    imageView.tag = 5;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Image" ofType:@"jpg"];
    UIImage *image = [UIImage imageWithContentsOfFile:path];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    imageView.image = image;
    [UIView transitionWithView:cell.contentView duration:0.3 options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionCrossDissolve animations:^{
        [cell.contentView addSubview:label];
        [cell.contentView addSubview:imageView];
    } completion:^(BOOL finished) {
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}

@end
