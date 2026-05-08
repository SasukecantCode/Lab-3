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
ldc 4
istore 2
ldc 6
istore 3
iload 2
iload 3
iadd  
ldc 8
isub  
ifgt L0
ldc 0
ldc 1
ifgt L1
L0:
ldc 1
L1:
ifeq L2
iload 2
iload 3
imul  
istore 1
ldc 1
ifgt L3
L2:
iload 2
iload 3
iadd  
istore 1
L3:
iload 1
print  
halt  
.end  
