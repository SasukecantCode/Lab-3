x:      .reserve 1
y:      .constant 5
        .start main
main:   ldc 3
        istore x
        iload x
        iload y
        iadd
        print
        halt
        .end
