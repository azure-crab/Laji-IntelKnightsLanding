#############################################################
#测试j,jal,jr指令，如需要可分开测试，执行正常应该是15个周期 revise date 2015/12/17 tiger
#############################################################
.text
benchmark_start:
  addi $s1,$zero, 1   #测试j,jal,jr指令，如需要可分开测试，执行正常应该是15个周期
 j jmp_next1
 addi $s1,$zero, 1
 addi $s2,$zero, 2
 addi $s3,$zero, 3
jmp_next1:
 j jmp_next2
 addi $s1,$zero, 1
 addi $s2,$zero, 2
 addi $s3,$zero, 3
jmp_next2:
 j jmp_next3
 addi $s1,$zero, 1
 addi $s2,$zero, 2
 addi $s3,$zero, 3
jmp_next3:
 j jmp_next4
 addi $s1,$zero, 1
 addi $s2,$zero, 2
 addi $s3,$zero, 3
jmp_next4:jal jmp_count

######################################


#移位测试  需要支持超addi,sll,add,syscall,srl,sll,sra,beq,j,syscall    revise date:2015/12/16 tiger

.text
addi $s0,$zero,1     #简单移位，循环测试，0号区域显示的是初始值1左移1位重复15次的值，1号区域是累加值
addi $s1,$zero,1  
sll $s1, $s1, 31   #逻辑左移31位 $s1=0x80000000
 

###################################################################
#                逻辑右移测试 
# 显示区域依次显示0x80000000 0x20000000 0x08000000 0x02000000 0x00800000 0x00200000 0x00080000 0x00020000 0x00008000 0x00002000 0x00000800 0x00000200 0x00000080 0x00000020 0x00000008 0x00000002 0x00000000  
###################################################################
LogicalRightShift:            #逻辑右移测试，将最高位1逐位向右右移直至结果为零

add    $a0,$0,$s1       #display $s1    #逻辑右移测试，将最高位1逐位向右右移直至结果为零
addi   $v0,$0,34        # display hex
syscall                 # we are out of here.  
     
srl $s1, $s1, 2   
beq $s1, $zero, shift_next1
j LogicalRightShift

shift_next1:

add    $a0,$0,$s1       #display $s1
addi   $v0,$0,34         # display hex
syscall                 # we are out of here.  


###################################################################
#                逻辑左移测试 
# 显示区域依次显示0x00000004 0x00000010 0x00000040 0x00000100 0x00000400 0x00001000 0x00004000 0x00010000 0x00040000 0x00100000 0x00400000 0x01000000 0x04000000 0x10000000 0x40000000 0x00000000 
###################################################################

addi $s1,$zero, 1        #                逻辑左移测试 
LogicalLeftShift:         #逻辑左移测试，将最低位1逐位向左移直至结果为零
sll $s1, $s1, 2  

add    $a0,$0,$s1       #display $s1
addi   $v0,$0,34         # display hex
syscall                 # we are out of here.  
      
beq $s1, $zero, ArithRightShift
j LogicalLeftShift


###################################################################
#                算术右移测试 
# 显示区域依次显示0x80000000 0xf0000000 0xff000000 0xfff00000 0xffff0000 0xfffff000 0xffffff00 0xfffffff0 0xffffffff 
###################################################################
ArithRightShift:          #算术右移测试，#算术移位测试，80000000算术右移，依次显示为F0000000,FF000000,FFF00000,FFFF0000直至FFFFFFFF

addi $s1,$zero,1     #                算术右移测试 
sll $s1, $s1, 31   #逻辑左移31位 $s1=0x80000000

add    $a0,$0,$s1       #display $s1
addi   $v0,$0,34         # display hex
syscall                 # we are out of here.  

sra $s1, $s1, 3    #$s1=0X80000000-->0XF0000000

add    $a0,$0,$s1       #display $s1
addi   $v0,$0,34         # display hex
syscall                 # we are out of here.  


sra $s1, $s1, 4    #0XF0000000-->0XFF000000

add    $a0,$0,$s1       #display $s1
addi   $v0,$0,34         # display hex
syscall                 # we are out of here.  


sra $s1, $s1, 4    #0XFF000000-->0XFFF00000

add    $a0,$0,$s1       #display $s1
addi   $v0,$0,34         # display hex
syscall                 # we are out of here.  

sra $s1, $s1, 4    

add    $a0,$0,$s1       #display $s1
addi   $v0,$0,34         # display hex
syscall                 # we are out of here.  

sra $s1, $s1, 4    

add    $a0,$0,$s1       #display $s1
addi   $v0,$0,34         # display hex
syscall                 # we are out of here.  


sra $s1, $s1, 4    

add    $a0,$0,$s1       #display $s1
addi   $v0,$0,34         # display hex
syscall                 # we are out of here.  


sra $s1, $s1, 4    

add    $a0,$0,$s1       #display $s1
addi   $v0,$0,34         # display hex
syscall                 # we are out of here.  


sra $s1, $s1, 4    


add    $a0,$0,$s1       #display $s1
addi   $v0,$0,34         # display hex
syscall                 # we are out of here.  

#############################################################
#走马灯测试,测试addi,andi,sll,srl,sra,or,ori,nor,syscall  LED按走马灯方式来回显示数据
#############################################################

.text
addi $s0,$zero,1 
sll $s3, $s0, 31      # $s3=0x80000000
sra $s3, $s3, 31      # $s3=0xFFFFFFFF   
addu $s0,$zero,$zero   # $s0=0         
addi $s2,$zero,12 

addiu $s6,$0,3  #走马灯计数
zmd_loop:

addiu $s0, $s0, 1    #计算下一个走马灯的数据
andi $s0, $s0, 15  

#######################################
addi $t0,$0,8    
addi $t1,$0,1
left:

sll $s3, $s3, 4   #走马灯左移
or $s3, $s3, $s0

add    $a0,$0,$s3       # display $s3
addi   $v0,$0,34         # system call for LED display 
syscall                 # display 

sub $t0,$t0,$t1
bne $t0,$0,left
#######################################

addi $s0, $s0, 1   #计算下一个走马灯的数据
addi $t8,$0,15
and $s0, $s0, $t8
sll $s0, $s0, 28     

addi $t0,$0,8
addi $t1,$0,1

zmd_right:

srl $s3, $s3, 4  #走马灯右移
or $s3, $s3, $s0

addu    $a0,$0,$s3       # display $s3
addi   $v0,$0,34         # system call for LED display 
syscall                 # display 

sub $t0,$t0,$t1
bne $t0,$0,zmd_right
srl $s0, $s0, 28  
#######################################

sub $s6,$s6,$t1
beq $s6,$0, exit
j zmd_loop

exit:

add $t0,$0,$0
nor $t0,$t0,$t0      #test nor  ori
sll $t0,$t0,16
ori $t0,$t0,0xffff

addu   $a0,$0,$t0       # display $t0
addi   $v0,$0,34         # system call for LED display 
syscall                 # display 
#################################################################################
#本程序实现0-15号字单元的降序排序,此程序可在mars mips仿真器中运行
#运行时请将Mars Setting中的Memory Configuration设置为Compact，data at address 0
#
#################################################################################
 .text
sort_init:
 addi $s0,$0,-1
 addi $s1,$0,0
 
 sw $s0,0($s1)
 addi $s0,$s0,1
 addi $s1,$s1,4
 sw $s0,0($s1)
 addi $s0,$s0,1
 addi $s1,$s1,4
 sw $s0,0($s1)
 addi $s0,$s0,1
 addi $s1,$s1,4
 sw $s0,0($s1)
 addi $s0,$s0,1
 addi $s1,$s1,4
 sw $s0,0($s1)
 addi $s0,$s0,1
 addi $s1,$s1,4
 sw $s0,0($s1)
 addi $s0,$s0,1
 addi $s1,$s1,4
 sw $s0,0($s1)
 addi $s0,$s0,1
 addi $s1,$s1,4
 sw $s0,0($s1)
 addi $s0,$s0,1
 addi $s1,$s1,4
  sw $s0,0($s1)
 addi $s0,$s0,1
 addi $s1,$s1,4
  sw $s0,0($s1)
 addi $s0,$s0,1
 addi $s1,$s1,4
 sw $s0,0($s1)
 addi $s0,$s0,1
 addi $s1,$s1,4
  sw $s0,0($s1)
 addi $s0,$s0,1
 addi $s1,$s1,4
  sw $s0,0($s1)
 addi $s0,$s0,1
 addi $s1,$s1,4
  sw $s0,0($s1)
 addi $s0,$s0,1
 addi $s1,$s1,4
  sw $s0,0($s1)
 addi $s0,$s0,1
 addi $s1,$s1,4
    sw $s0,0($s1)
 addi $s0,$s0,1
 addi $s1,$s1,4
   
 addi $s0,$s0,1
 
 add $s0,$zero,$zero   
 addi $s1,$zero,60   #排序区间
sort_loop:
 lw $s3,0($s0)     
 lw $s4,0($s1)
 slt $t0,$s3,$s4
 beq $t0,$0,sort_next   #降序排序
 sw $s3, 0($s1)
 sw $s4, 0($s0)   
sort_next:
 addi $s1, $s1, -4   
 bne $s0, $s1, sort_loop  
 
 add    $a0,$0,$s0       #display $s0
 addi   $v0,$0,34         # display hex
 syscall                 # we are out of here.  DISP: disp $r0, 0
 
 addi $s0,$s0,4
 addi $s1,$zero,60
 bne $s0, $s1, sort_loop

 addi   $v0,$zero,50         # system call for pause
 syscall                  # we are out of here.   
 
 #SUBU测试  循环减1   revise date:2018/3/12 tiger
#依次输出  0x00000010 0x0000000f 0x0000000e 0x0000000d 0x0000000c 0x0000000b 0x0000000a 0x00000009 0x00000008 0x00000007 0x00000006 0x00000005 0x00000004 0x00000003 0x00000002 0x00000001 0x00000000 0xffffffff 0xfffffffe 0xfffffffd 0xfffffffc 0xfffffffb 0xfffffffa 0xfffffff9 0xfffffff8 0xfffffff7 0xfffffff6 0xfffffff5 0xfffffff4 0xfffffff3 0xfffffff2 0xfffffff1 0xfffffff0
.text

addi $t0,$zero,1     #
addi $s1,$zero, 0x10     #

add $a0,$0,$s1           
addi $v0,$zero,34         # system call for print
syscall                  # print

addi $t3,$zero, 0x20

subu_branch:
subu $s1,$s1,$t0     #先移1位
add $a0,$0,$s1          
addi $v0,$zero,34         # system call for print
syscall                  # print
addi $t3,$t3, -1    
bne $t3,$zero,subu_branch   #循环8次

addi   $v0,$zero,10         # system call for exit
syscall                  # we are out of here.   

#sltiu 测试    revise date:2018/3/12 tiger
#依次输出  0x00001997 0x00001996 0x00001995 0x00001994 0x00001993 0x00001992 0x00001991 0x00001990 0x0000198f 0x0000198e 0x0000198d 0x0000198c 0x0000198b 0x0000198a 0x00001989 0x00001988 0x00001987 0x00001986 0x00001985 0x00001984 0x00001983 0x00001982 0x00001981 0x00001980 0x0000197f 0x0000197e 0x0000197d 0x0000197c 0x0000197b 0x0000197a 0x00001979 0x00001978 0x00001977 0x00001976 0x00001975 0x00001974 0x00001973 0x00001972 0x00001971 0x00001970 0x0000196f 0x0000196e 0x0000196d 0x0000196c 0x0000196b 0x0000196a 0x00001969 0x00001968 0x00001967 0x00001966 0x00001965 0x00001964 0x00001963 0x00001962 0x00001961 0x00001960 0x0000195f 0x0000195e 0x0000195d 0x0000195c 0x0000195b 0x0000195a 0x00001959 0x00001958 0x00001957 0x00001956 0x00001955 0x00001954 0x00001953 0x00001952 0x00001951 0x00001950 0x0000194f 0x0000194e 0x0000194d 0x0000194c 0x0000194b 0x0000194a 0x00001949

.text
addi $t0,$zero,-1    
addi $t1,$zero,0     
addi $s1,$zero, 0x1997  
sltiu_branch:
add $a0,$0,$s1          
addi $v0,$zero,34        # system call for print
syscall                  # print
add $s1,$s1,$t0     
sltiu $t1,$s1, 0x1949
beq $t1,$zero,sltiu_branch

addi   $v0,$zero,10         # system call for exit
syscall                  # we are out of here.   

#LHU 测试    revise date:2018/3/12 tiger
#依次输出  0x00008281 0x00008483 0x00008685 0x00008887 0x00008a89 0x00008c8b 0x00008e8d 0x0000908f 0x00009291 0x00009493 0x00009695 0x00009897 0x00009a99 0x00009c9b 0x00009e9d 0x0000a09f 0x0000a2a1 0x0000a4a3 0x0000a6a5 0x0000a8a7 0x0000aaa9 0x0000acab 0x0000aead 0x0000b0af 0x0000b2b1 0x0000b4b3 0x0000b6b5 0x0000b8b7 0x0000bab9 0x0000bcbb 0x0000bebd 0x0000c0bf
.text

addi $t1,$zero,0     #init_addr 
addi $t3,$zero,16     #counter

#预先写入数据，实际是按字节顺序存入 0x81,82,84,86,87,88,89.......等差数列
ori $s1,$zero, 0x8483  #
addi $s2,$zero, 0x0404  #
sll $s1,$s1,16
sll $s2,$s2,16
ori $s1,$s1, 0x8281  #    注意一般情况下MIPS采用大端方式
addi $s2,$s2, 0x0404  #   init_data= 0x84838281 next_data=init_data+ 0x04040404

lhu_store:
sw $s1,($t1)
add $s1,$s1,$s2   #data +1
addi $t1,$t1,4    # addr +4  
addi $t3,$t3,-1   #counter
bne $t3,$zero,lhu_store

addi $t3,$zero,32   #循环次数
addi $t1,$zero,0    # addr
lhu_branch:
lhu $s1,($t1)     #测试指令
add $a0,$0,$s1          
addi $v0,$zero,34         
syscall                  # print
addi $t1,$t1, 2    
addi $t3,$t3, -1    
bne $t3,$zero,lhu_branch

addi   $v0,$zero,10         # system call for exit
syscall                  # we are out of here.   

#bltz 测试    小于0跳转   revise date:2018/3/12 tiger  
#依次输出0xfffffff1 0xfffffff2 0xfffffff3 0xfffffff4 0xfffffff5 0xfffffff6 0xfffffff7 0xfffffff8 0xfffffff9 0xfffffffa 0xfffffffb 0xfffffffc 0xfffffffd 0xfffffffe 0xffffffff
.text
addi $s1,$zero,-15       #初始值
bltz_branch:
add $a0,$0,$s1          
addi $v0,$zero,34         
syscall                  #输出当前值
addi $s1,$s1,1 
bltz $s1,bltz_branch     #当前指令


addi   $v0,$zero,10    
syscall                  #暂停或退出

j benchmark_start    #删除这条指令，用CCAB差异化指令代替


 ###########################################################
 # 请在这里加入CCAB差异化指令的演示程序
 ###########################################################

                
 addi   $v0,$zero,10         # system call for exit
 syscall                  # we are out of here.   
 
 #MIPS处理器实现中请用停机指令实现syscall

jmp_count: addi $s0,$zero, 0
       addi $s0,$s0, 1
       add    $a0,$0,$s0      
       addi   $v0,$0,34         # display hex
       syscall                 # we are out of here.  
       
       addi $s0,$s0, 2
       add    $a0,$0,$s0      
       addi   $v0,$0,34         # display hex
       syscall                 # we are out of here.  
       
       addi $s0,$s0, 3
       add    $a0,$0,$s0      
       addi   $v0,$0,34         # display hex
       syscall                 # we are out of here.  
       
       addi $s0,$s0, 4       
       add    $a0,$0,$s0      
       addi   $v0,$0,34         # display hex
       syscall                 # we are out of here.  
       
       addi $s0,$s0, 5              
       add    $a0,$0,$s0      
       addi   $v0,$0,34         # display hex
       syscall                 # we are out of here.  
       
       addi $s0,$s0, 6              
       add    $a0,$0,$s0      
       addi   $v0,$0,34         # display hex
       syscall                 # we are out of here.  

       addi $s0,$s0, 7              
       add    $a0,$0,$s0      
       addi   $v0,$0,34         # display hex
       syscall                 # we are out of here.  

       addi $s0,$s0, 8              
       add    $a0,$0,$s0      
       addi   $v0,$0,34         # display hex
       addi   $v0,$0,34         # display hex       
       syscall                 # we are out of here.  

       jr $31

