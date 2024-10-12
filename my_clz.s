.data
array: .word 0x4, 0x21, 0x0, 0xcba, 0xffff    
length: .word 5
print_input: .string "input = "
print_comma: .string ", "
print_newline: .string "\n"
print_lz: .string "lz = "

.text
main:
    la s0, array
    lw s1, length
loop:
    beqz s1, end    # if s1 = 0, goto end

    lw t0, 0(s0)
    addi s1, s1, -1
    addi s0, s0 4
    
    # print "input = "
    la a0, print_input
    li a7, 4
    ecall
    # print input value
    mv a0, t0
    li a7, 34
    ecall
    # call function
    call clz
    
    # print ", "
    la a0, print_comma
    li a7, 4
    ecall
    # print "lz = "
    la a0, print_lz
    ecall
    # print lz value
    mv a0, t1
    li a7 1
    ecall
    # print "\n"
    la a0, print_newline
    li a7, 4
    ecall

    j loop

clz:
    # x |= (x >> 1)
    srli t1, t0, 1
    or t0, t0, t1
    # x |= (x >> 2)
    srli t1, t0, 2
    or t0, t0, t1
    # x |= (x >> 4)
    srli t1, t0, 4
    or t0, t0, t1
    # x |= (x >> 8)
    srli t1, t0, 8
    or t0, t0, t1

    # x -= ((x >> 1) & 0x5555)
    srli t1, t0, 1
    li t2, 0x5555
    and t1, t1, t2
    sub t0, t0, t1
    # x = ((x >> 2) & 0x3333) + (x & 0x3333)
    srli t1, t0, 2
    li t2, 0x3333
    and t1, t1, t2
    and t0, t0, t2
    add t0, t0, t1
    # x = ((x >> 4) + x) & 0x0f0f
    srli t1, t0, 4
    add t0, t0, t1
    li t2, 0x0f0f
    and t0, t0, t2
    # x += (x >> 8)
    srli t1, t0, 8
    add t0, t0, t1
    # return (16 - (x & 0x7f))
    andi t0, t0, 0x7f
    xori t0, t0, -1
    addi t1, t0, 17
    ret
end:
    li a7, 10
    ecall
