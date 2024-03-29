Laji-IntelKnightsLanding  
--------------------------
## introduction
a MIPS32 CPU with five-stage instruction pipeline, operand forwarding, nested interrupts and dynamic bimodal branch predictor

## 文档  
[指令对照表共享文档链接(sheet4)](https://1drv.ms/x/s!ApZLhnoi90jEgcJxx4Y1am3vJVUXcA)  
[zz syscall各模块简要说明onenote链接](https://1drv.ms/u/s!ApZLhnoi90jEgcIdLEGKjjEoEAE8oQ)  
[第二轮课程设计资源文档汇总](https://yiqixie.com/d/home/fcAAwE-6cJ2Qq1ARLiE7Zjf6b)  
  
## 工程说明  
按照各自类型把Repo根目录所有文件都加进去即可。  
  
## 上板说明  
* 16个开关从右到左编号为`0 ~ 15`，命名为`swt[15:0]`  
* `swt[0]`用来控制CPU运行频率：  
  * `0`：`2 Hz`  
  * `1`：`20 Hz`  
  * `2`：`200 Hz`  
  * `3`：`2 MHz`  
* `swt[5:2]`用来控制数码管的输出内容（均是16进制）：  
  * `0000`：`CPU自身来自syscall的输出`  
  * `0001`：`已执行的指令数`  
  * `0010`：`已执行的无条件跳转指令数`  
  * `0011`：`已执行的条件分支指令数`  
  * `0100`：`已执行跳转的条件分支指令数`  
  * `0101`：`当前PC的值`  
  * `0110`：`寄存器$(swt[15:11])的值`  
  * `0111`：`内存地址(swt[15:6] * 4)的值`  
  * `1000`：`已插入气泡的数量`
  * `1001`：`load-use的数量`
* `CPU RESET`按键用于异步复位（电平触发），主要作用是将PC清零  
* `BTNC`按键用于停机后继续执行（电平触发）  
