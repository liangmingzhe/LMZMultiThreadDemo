//
//  ViewController.m
//  LMZMultiThreadDemo
//
//  Created by 梁明哲 on 2021/1/24.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    /**
     *  需求一：往非主队列中添加三个任务 任务1;任务2;任务3
     *  依赖关系：任务3->任务2; 任务2->任务1
     */
    //方式一:使用NSOperation
    [self methodForOperation];
    
    //方式二:使用GCD的栅栏函数
    [self methodWithGCDBarrier];
    
    //方式三:使用GCD的信号量
    [self methodSemaphore];
     
    
    /**
     *  需求二: 往非主队列中添加三个任务 任务1;任务2;任务3
     *  任务3 需要依赖 任务2 和 任务1 的返回结果，任务1 和 任务2 之间没有依赖关系
     *  依赖关系：任务3->任务1; 任务3->任务1
     *  分析:
     *      1.修改 methodForOperation 中的依赖关系就可以实现
     *      2.使用GCD中的任务组和notify实现
     */
    //方式一:使用任务组
    [self methodForGroup];
    
}




/**
 需求：
 往非主队列中添加三个任务 任务1;任务2;任务3
 自动执行顺序：三个任务同时执行
 改后的执行顺序:任务三等待任务一和任务二执行完毕，才执行
 依赖关系：任务3->任务2; 任务2->任务1
 */
- (void)methodForOperation {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSOperationQueue *queue = [[NSOperationQueue alloc] init];
        queue.maxConcurrentOperationCount = 5;
        NSBlockOperation *op = [NSBlockOperation blockOperationWithBlock:^{
            NSLog(@"进度:下载图片1 - 开始下载");
            [NSThread sleepForTimeInterval:3];
            NSLog(@"进度:下载图片1 - 成功");
        }];
        
        NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
            NSLog(@"进度:下载图片2 - 开始下载");
            [NSThread sleepForTimeInterval:3];
            NSLog(@"进度:下载图片2 - 成功");
        }];
        
        NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
            NSLog(@"进度:下载图片3 - 开始下载");
            [NSThread sleepForTimeInterval:5];
            NSLog(@"进度:下载图片3 - 成功");
        }];
        
        [op3 addDependency:op2];
        [op2 addDependency:op];
        
        [queue addOperation:op];
        [queue addOperation:op2];
        [queue addOperation:op3];
    });
}

- (void)methodWithGCDBarrier {
    /**
     * 使用栅栏函数(dispatch_barrier_async)实现顺序下载，该函数需要同dispatch_queue_create函数生成的并行队列一起使用，否则无效
     */
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_queue_t queue1 = dispatch_queue_create("12312312", DISPATCH_QUEUE_CONCURRENT);
        dispatch_async(queue1, ^{
            NSLog(@"进度:下载图片1 - 开始下载");
            [NSThread sleepForTimeInterval:3];
            NSLog(@"进度:下载图片1 - 成功");
        });
        
        dispatch_barrier_async(queue1, ^{
            NSLog(@"进度:下载图片1 - 结束");
        });
        
        dispatch_async(queue1, ^{
            NSLog(@"进度:下载图片2 - 开始下载");
            [NSThread sleepForTimeInterval:5];
            NSLog(@"进度:下载图片2 - 成功");
        });
        
        dispatch_barrier_async(queue1, ^{
            NSLog(@"进度:下载图片2 - 结束");
        });
        
        dispatch_async(queue1, ^{
            NSLog(@"进度:下载图片3 - 开始下载");
            [NSThread sleepForTimeInterval:5];
            NSLog(@"进度:下载图片3 - 成功");
        });
    });
}


- (void)methodForGroup {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        dispatch_group_t group_t = dispatch_group_create(); //创建组
        
        dispatch_queue_global_t q_group_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);  //队列
        
        dispatch_group_enter(group_t);
        dispatch_group_async(group_t, q_group_t, ^{
            NSLog(@"下载图片1");
            [NSThread sleepForTimeInterval:3];
            NSLog(@"下载图片1 - 成功");
            dispatch_group_leave(group_t);
        });
        
        dispatch_group_enter(group_t);
        dispatch_group_async(group_t, q_group_t, ^{
            NSLog(@"下载图片2");
            [NSThread sleepForTimeInterval:10];
            NSLog(@"下载图片2 - 成功");
            dispatch_group_leave(group_t);
        });
        
        dispatch_group_notify(group_t, q_group_t, ^{
            NSLog(@"下载图片3");
            [NSThread sleepForTimeInterval:3];
            NSLog(@"下载图片3 - 成功");
        });
    });
}

/**
 *  @abstract:通过信号量实现异步队列的任务的顺序执行
 */
- (void)methodSemaphore {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_semaphore_t semzphore_t = dispatch_semaphore_create(0);
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"下载图片1");
            [NSThread sleepForTimeInterval:3];
            NSLog(@"下载图片1 - 成功");
            dispatch_semaphore_signal(semzphore_t);
        });
        
        dispatch_semaphore_wait(semzphore_t, DISPATCH_TIME_FOREVER);
        
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"下载图片2");
            [NSThread sleepForTimeInterval:10];
            NSLog(@"下载图片2 - 成功");
            dispatch_semaphore_signal(semzphore_t);
        });
        dispatch_semaphore_wait(semzphore_t, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            NSLog(@"下载图片3   ");
            [NSThread sleepForTimeInterval:3];
            NSLog(@"下载图片3 - 成功");
        });
    });
}


@end
