.start main
.constant 0
.constant 0
.constant 0
.constant 0
.constant 0
.constant 0
.constant 0
.constant 0
.constant 0
.constant 0
main:
ldc 1
istore 2
iload 2
ldc 5
isub  
ifgt L0
ldc 0
ldc 1
ifgt L1
L0:
ldc 1
L1:
ifeq L2
ldc 100
istore 1
ldc 1
ifgt L3
L2:
ldc 200
istore 1
L3:
iload 1
print  
halt  
.end  
