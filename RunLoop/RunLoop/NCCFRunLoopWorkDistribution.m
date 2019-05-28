//
//  NCCFRunLoopWorkDistribution.m
//  RunLoop
//
//  Created by niuchao on 2018/3/15.
//  Copyright © 2018年 niuchao. All rights reserved.
//

#import "NCCFRunLoopWorkDistribution.h"
#import <objc/runtime.h>

#define NCCFRunLoopWorkDistribution_DEBUG 1

@interface NCCFRunLoopWorkDistribution ()

//(4.....) 定义任务数组
@property (nonatomic, strong) NSMutableArray *tasks;

@property (nonatomic, strong) NSMutableArray *tasksKeys;
@property (nonatomic, strong) NSTimer *timer;

@end

@implementation NCCFRunLoopWorkDistribution

- (void)removeAllTasks {
    [self.tasks removeAllObjects];
    [self.tasksKeys removeAllObjects];
}

//(5....)保存block任务到数组
- (void)addTask:(NCCFRunLoopWorkDistributionUnit)unit withKey:(id)key{
    [self.tasks addObject:unit];
    [self.tasksKeys addObject:key];

    //如果要执行的Task任务超出屏幕范围个数就把第一个删了...
    if (self.tasks.count > self.maximumQueueLength) {
        [self.tasks removeObjectAtIndex:0];
        [self.tasksKeys removeObjectAtIndex:0];
    }
}

- (void)_timerFiredMethod:(NSTimer *)timer {
    //We do nothing here
}

- (instancetype)init
{
    if ((self = [super init])) {
        _maximumQueueLength = 30;
        _tasks = [NSMutableArray array];
        _tasksKeys = [NSMutableArray array];
        _timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_timerFiredMethod:) userInfo:nil repeats:YES];
    }
    return self;
}

+ (instancetype)sharedRunLoopWorkDistribution {
    static NCCFRunLoopWorkDistribution *singleton;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        singleton = [[NCCFRunLoopWorkDistribution alloc] init];
        //注意这里传的是一个self的OC对象
        [self _registerRunLoopWorkDistributionAsMainRunloopObserver:singleton];
    });
    return singleton;
}


+ (void)_registerRunLoopWorkDistributionAsMainRunloopObserver:(NCCFRunLoopWorkDistribution *)runLoopWorkDistribution {
    static CFRunLoopObserverRef defaultModeObserver;
    
//    (2.....) 创建观察者CFRunLoopObserver,封装了一个函数方法
    _registerObserver(kCFRunLoopBeforeWaiting, defaultModeObserver, NSIntegerMax - 999, kCFRunLoopCommonModes, (__bridge void *)runLoopWorkDistribution, &_defaultModeRunLoopWorkDistributionCallback);
}

//创建观察者CFRunLoopObserver函数方法
static void _registerObserver(CFOptionFlags activities, CFRunLoopObserverRef observer, CFIndex order, CFStringRef mode, void *info, CFRunLoopObserverCallBack callback) {

//    (1....)拿到当前的Runloop
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();

    //定义第六个参数,上下文结构体,里面的info同callback函数中的void *info参数有联系,会传一个self
    CFRunLoopObserverContext context = {
        0,
        info,       //这个info实际上就是self , info == (__bridge void *)self;  (需要__bridge桥接,因为这里是将OC转为C语言)
        &CFRetain,
        &CFRelease,
        NULL
    };
    //创建观察者 CFRunLoopObserver 关键系统方法
    //二参数看扩展②,我们选择的是kCFRunLoopBeforeWaiting
    //三参数是否循环观察
    //五参数创建函数的回调,直接写callback函数指针,所以我们定义了一个函数:_defaultModeRunLoopWorkDistributionCallback
    //六参数创建上下文,取定义好的一个结构体指针
    observer = CFRunLoopObserverCreate(NULL, activities, YES, order, callback, &context);


//    (3.....)添加观察者,这里用的mode是kCFRunLoopDefaultMode---只能拖拽完毕后加载, kCFRunLoopCommonModes----可以边拖动边加载
    CFRunLoopAddObserver(runLoop, observer, mode);

    //释放:因为这里是C语言环境,不属于ARC,所有带有几个单词的函数需要注意'释放' -- new,cope,create 会在堆区域开辟内存空间!!!
    CFRelease(observer);
}

// (4....)
//定义一个函数方法,用于创建创建观察者 CFRunLoopObserver 的回调方法
static void _defaultModeRunLoopWorkDistributionCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
    _runLoopWorkDistributionCallback(observer, activity, info);
}

//在源码中我们看到CallBack是这个样式的,理由有三个参数,第一个和第二个我们都有解释,那三个是什么??
//------void *info 是一个万能指针,直接打印啥都没有,需要同CFRunLoopObserverCreate中的上下文结构体指针(&context)有联系,在里面传self
static void _runLoopWorkDistributionCallback(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{

    //(5....)提取self的tesks任务列表
    //*********这里为什么取不到self********
    //因为只有OC的方法本质是消息机制,就是发送消息megSend(),里面才有两个隐藏的函数: 1、id self(方法调用者)  2、SEL _cmd,C语言函数里面是没有的.


    //通过上下文指针&context传值self,然后桥接__bridge成OC的self
    NCCFRunLoopWorkDistribution *runLoopWorkDistribution = (__bridge NCCFRunLoopWorkDistribution *)info;

    //取到self就能拿到它的任务列表tasks,tasks里面是NCCFRunLoopWorkDistributionUnitBlock.

    //如果tasks里面没有block任务,那就直接返回
    if (runLoopWorkDistribution.tasks.count == 0) {
        return;
    }
    BOOL result = NO;
    while (result == NO && runLoopWorkDistribution.tasks.count) {
        //取到NCCFRunLoopWorkDistributionUnitBlock任务
        NCCFRunLoopWorkDistributionUnit unit  = runLoopWorkDistribution.tasks.firstObject;
        //执行block
        result = unit();
        //执行完需要删除任务
        [runLoopWorkDistribution.tasks removeObjectAtIndex:0];
        [runLoopWorkDistribution.tasksKeys removeObjectAtIndex:0];
    }
}

@end



@implementation UITableViewCell (NCCFRunLoopWorkDistribution)

@dynamic currentIndexPath;

- (NSIndexPath *)currentIndexPath {
    NSIndexPath *indexPath = objc_getAssociatedObject(self, @selector(currentIndexPath));
    return indexPath;
}

- (void)setCurrentIndexPath:(NSIndexPath *)currentIndexPath {
    objc_setAssociatedObject(self, @selector(currentIndexPath), currentIndexPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

