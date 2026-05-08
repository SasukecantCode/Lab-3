        .start main
main:   ldc 7
        istore a
        iload a
        ldc 2
        imul
        print
        halt
a:      .reserve 1
b:      .constant 3
        .end
