N: .reserve 1
        .start begin
begin:  read
        istore N
        iload N
        ldc 1
        isub
        iflt exit
loop:   read
        iload sum
        iadd
        istore sum
        iload N
        ldc 1
        isub
        istore N
        iload N
        ifgt loop
        iload sum
        print
exit:   halt
sum:    .constant 10
        .end
