//
//  ViewController.m
//  RunLoop
//
//  Created by niuchao on 2018/3/14.
//  Copyright © 2018年 niuchao. All rights reserved.
//

#import "ViewController.h"
#import "NCThread.h"


/*拓展思考* demo4

 ①   通过GCD代码我们引入了Source这个概念,是不是很眼熟,没错在每个Runloop都包含三个部分: Timer, Source ,Observe;(可以去CFRunloop源码里查看为什么包含这三部分)
 Source---事件源(输入源) 对应的是---CFRunloopSourceRef,凡是看到" Ref" 这个字的时候就代表他是一个结构体指针;
     按照函数调动栈解释:Source分为两个部分;
     Source0:不是Source1就是Source0
     Source1:内核与其他线程的通讯事件
 */


@interface ViewController ()

@property (nonatomic,strong) NCThread *ncThread;//demo2为了测试线程是否被释放----设置strong只是保存了_ncThread这个OC对象的生命,线程是由CPU直接调度的,所以它在例子中block任务执行完毕后就会被释放;

@property (nonatomic, strong) dispatch_source_t timer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    GCD与Runloop有紧密的联系
//    **** 用GCD创建的timer,运行后发现与UI操作完美运行,没有冲突,说明GCD把我们封装好了Runloop, 底层就CFRunloop*****

    //创建timer 并把它放在全局队列里面
    _timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(0, 0));
    //设置timer
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC,0);
    //创建句柄 回调
    dispatch_source_set_event_handler(_timer, ^{
        NSLog(@"------线程:%@",[NSThread  currentThread]);
    });
    //启动timer
    dispatch_resume(_timer);


    // GCD timer创建代码块
    //    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, <#dispatchQueue#>);
    //    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, <#intervalInSeconds#> * NSEC_PER_SEC, <#leewayInSeconds#> * NSEC_PER_SEC);
    //    dispatch_source_set_event_handler(timer, ^{
    //        <#code to be executed when timer fires#>
    //    });
    //    dispatch_resume(timer);


}

//打开方法断点,点击屏幕可以查看函数调用栈(如何查看调用栈呢----在lldb模式下输入:thread backtrace ),可以看到CFRunLoopDoSource0,根据拓展我们知道Source0不是内核事件,对啊,因为他是咱们点击出来的,用户事件嘛!!! 拓展①
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{


}


/*demo3 线程间的通信需要Runloop

 - (void)viewDidLoad {
     [super viewDidLoad];

     //子线程
     NSThread *thread = [[NSThread alloc] initWithBlock:^{
         NSLog(@"子线程进来 :%@",[NSThread currentThread]);
         while (true) {
         //            ***Runloop启动线程间的通信***
         [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.0001]];
         }

     }];

     [thread start];

     //线程间的通信----在主线程上为子线程添加了一个任务;
     //但是子线程为启动Runloop,所以otherMethod不会执行,不管它是不是在start之前还是之后;
     //这个方法实际上是将放在Runloop事件队列里面,所以单纯加一个while死循环也不能执行,需要通过Runloop去启动线程之间的通信
     [self performSelector:@selector(otherMethod) onThread:thread withObject:nil waitUntilDone:NO];

 }

 -(void)otherMethod{
     NSLog(@"otherMethod%@",[NSThread currentThread]);
 }

*/


/*拓展思考* (二)RunLoop与线程
 ①线程的生命,只能通过线程的任务去保住,无任务就会被释放!!!  ----让线程有执行不完的任务(Runloop 死循环任务),线程就不会释放了!!!!  ----所以它在例子中block任务执行完毕后就会被释放;

 ②主线程的Runloop是在UIApplicationMain中默认开启
 新创建的线程默认是不会开启的.

 ③主线程对于系统来说也是一个子线程,这么多APP,对于系统来说的就有这么多子线程;-----APP启动的第一条线程
 主线程进行UI操作,UIKit框架也是线程不安全的,保证线程安全就需要'锁',但是凡是'锁'都需要消耗性能,就好像属性里面的nonatomic也是避免消耗性能的,所以苹果规定 "凡是UI操作统一放在----主线程",当然可以尝试一下放在子线程,如果出现资源抢夺,会出现未知的问题.

 */
/*
demo2
(二)RunLoop与线程

 - (void)viewDidLoad {
     [super viewDidLoad];

     //子线程
     NSThread *thread = [[NSThread alloc] initWithBlock:^{

         NSTimer *time = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(timerMethod) userInfo:nil repeats:YES];

         //注意这里是子线程的Runloop
         [[NSRunLoop currentRunLoop] addTimer:time forMode:NSRunLoopCommonModes];//UI操作(触摸)时和timer事件正常执行


         //        while (true) {
         //什么事情都不做,这里只是让线程有执行不完的任务,进而保住线程不被释放;
         //----虽然线程保住了,但是timerMethod事件却未处理是为什么呢?????  想一想这里是不是子线程!!!;
         //        }


         //Runloop ----子线程的Runloop默认是不会开启的,这就解释了为什么线程保住了却未执行timerMethod方法!!!! 看拓展②
         //currentRunLoop会调用底层的CFRunloop,在这里只有此currentRunLoop()调用时才回去创建一个Runloop,是个懒加载过程!!!
         [[NSRunLoop currentRunLoop] run];//run起来死循环任务,不会执行下面的代码

         //现在考虑一下Runloop如何被停止呢???? 好,尝试在timerMethod方法中将线程退出,线程一但退出那是不是Runloop也就被退出了!!!

         NSLog(@"线程来了");//当run起来后timerMethod虽然执行了,但是这里不会打印执行,因为上面的Runloop是死循环,类似于UIApplicationMain的下面不会执行一样;
     }];


     //这个方法是在主线程上执行的,不会等待block,所以对于Thread的释放是没有关系的.
     [thread start];
 }


 //1.当子线程thread为局部变量时此方法不会执行,因为被释放了;
 //2.但是当子线程为_ncThread全局变量时也不会执行, 为什么呢?????  ----strong只是保存了_ncThread这个OC对象的生命,线程是由CPU直接调度的,所以它在例子中block任务执行完毕后就会被释放;

 - (void)timerMethod{
     NSLog(@"timerMethod执行 当前线程%@:",[NSThread currentThread]);//不会执行 看拓展①

     //暴力干掉子线程!!!!对应上面的Runloop退出.
     [NSThread exit];

     [NSThread sleepForTimeInterval:1.0];//模拟耗时操作,从而引进子线程概念
 }

 -(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{

     [NSThread exit];//暴力干掉主线程会出现什么情况呢???

     //答案是主线程被杀死了,例子中的拖动等主线程UI操作不会执行了, 这是为什么呢???主线程都能被干掉?太不可思议了!!! 看拓展③
 }

*/



/*拓展思考* (一):Runloop 初探

 **Runloop始终与线程将关联**
 Runloop有5中模式  每一种模式中都包含  timer ---- source  ---- observer

 NSDefaultRunLoopMode 默认模式
 UITrackingRunLoopMode  UI模式--1.用户体验优先级最高 2.只会在有UI操作(触摸)时进行
 NSRunLoopCommonModes   占位模式 原则上讲它不属于Runloop模式
 内核模式
 初始化模式

 当将timer事件设定为,可以理解为添加到 默认模式 的事件列表下,并添加到主线程的Runloop中,但是我们知道凡是UI操作的事件都是添加到主线程上的,所以在默认模式下的timer事件会与UI操作事件发生冲突,主线程上的Runloop会在timer事件与UI操作事件上来回跳动Run执行;
 但是如果将timer事件添加到UI模式下,就会发现它只会在有触摸或者说有UI操作时才会执行.

 */

/*demo1  Runloop 初探

 - (void)viewDidLoad {
     [super viewDidLoad];

     //此方法默认封装到Runloop里面了;
     //***此方法默认加入的是默认模式,所以依然会出现UI操作冲突的问题***
     [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerMethod) userInfo:nil repeats:YES];

     //此方法默认不加入Runloop,需要手动加入到Runloop循环当中去
     NSTimer *time = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(timerMethod) userInfo:nil repeats:YES];
     //[NSRunLoop mainRunLoop];当前就是主Runloop

     //NSDefaultRunLoopMode 默认模式
     //UITrackingRunLoopMode UI模式
     //NSRunLoopCommonModes  占位模式 原则上讲它不属于Runloop模式
     //    [[NSRunLoop currentRunLoop] addTimer:time forMode:NSDefaultRunLoopMode];//UI操作(触摸)时和timer事件 相互跳动执行
     //    [[NSRunLoop currentRunLoop] addTimer:time forMode:UITrackingRunLoopMode];//只会在有UI操作(触摸)时执行timer事件
     [[NSRunLoop currentRunLoop] addTimer:time forMode:NSRunLoopCommonModes];//UI操作(触摸)时和timer事件正常执行
}

- (void)timerMethod{
    NSLog(@"timerMethod执行 当前线程%@:",[NSThread currentThread]);
}
*/

@end
