//
//  main.m
//  RunLoop
//
//  Created by niuchao on 2018/3/14.
//  Copyright © 2018年 niuchao. All rights reserved.
//

/*拓展*
 循环与递归 区别????  方法的调用就是函数的调用,函数调用本质: 分配一块栈区域!!递归就是自己调用自己,反复的调用就会反复的分配空间,所有造成堆栈溢出;
 汇编语言中会提到为什么递归即函数的反复调用会反复开辟栈空间,而死循环不会反复开辟空间.


 */

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    @autoreleasepool {
//        NSLog(@"来了");
        /*UIApplicationMain为我们创建了一个:主循环Runloop,默认开启
         1.保证程序不退出;
         2.监听事件,触摸事件,时钟,网络事件;
         3.如果没有时间发生,就会进入休眠状态,性能损耗低;
         */
         int main = UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
        NSLog(@"走了");
        return main;
    }
}
