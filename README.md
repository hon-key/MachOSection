# MachOSection
A way using mach-o section to execute function or read value

对于一些大型的 APP 来说，启动过程可能是一个比较重要的点。因为大型 APP 往往带有大量的业务组件和一些基础组件，这些组件往往需要在 APP 启动时做点什么。

刚开始的时候可能大家会把他们全都往 APPDelegate 里塞，每塞一点，APP 的启动就会延后一点，随着 APP 的发展，塞入的越来越多，启动时间的延后将成为一个问题。不仅如此，冗长的 appdelegate 也会让维护变得相当头疼，即使分 category 也是治标不治本。又因为启动阶段其实有分多个细分阶段，比如作为首页显示之前以及之后，甚至还有 main() 执行之前以及之后等。

那么如何去解决这个问题呢，其实办法有多种，一种常见的方法是使用通知来发送各个启动阶段的消息，这样不仅可以减少 appdelegate 的负担，还可以解耦各个组件的启动项与顶层壳之间的关联。但有个缺点是，他并不支持 main 函数执行之前的启动阶段，无法全面覆盖。

这时候我们发现可执行程序文件的结构以及方法允许我们用另一种方式来达到这个目的。那就是通过 mach-o 文件结构来执行方法或者读取数据。

原理是：

- 通过 __attribute__ 的 section 属性来为 mach-o 的 __DATA 段自定义一个 section，并将函数指针或者数据存入这个 section 之中
- 程序启动阶段，不管是 main() 函数启动之前还是之后，mach-o 镜像已经被读入内存，所以该段以及 section 中的函数指针或者数据是可以读取得到的，我们读取他们，然后执行函数或者操作数据

通过以上方法，我们可以发现， 

- __attribute__ 属性可以定义在各个业务组件之内，在编译阶段就写入 mach-o 里，与顶层的壳做到了完全的隔离。
- 无论你是在 load（）阶段还是在 main() 阶段，甚至是 constructor 函数，你都可以有序地调用你存储的函数或者读取数据，所以你可以定义你的结构体来进行更精细的流程控制。
- 你可以限制这些流程的时间来确定你该阶段的启动流程是否过于冗长，从而进行有针对性地改善。
- 他不仅可以用于启动，也可以用于运行结束阶段，类似于析构函数。

具体用法：

以 ClassA.m 为例

```

MACH_O_SECTION_FUNCTION_DEFINITION(START_UP_1) {
    // do your job for start up ClassA
}

@implementation ClassA
...
@end

```

我们假设 START_UP_1 作为 -application:didFinishLaunchWithOptions: 方法开始时需要执行的启动项集合，则：

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [MachOSection.shareInstance executeFunctionsForKey:@"START_UP_1"];
    ...
}
```

不同的文件都可以定义同一个 START_UP_1 绑定的方法，编译阶段将根据编译顺序写入 mach-o 中，更具体的需求，我们可以自定义属于自己的读写结构来来存储更多的信息以进行更精确的流程控制。
