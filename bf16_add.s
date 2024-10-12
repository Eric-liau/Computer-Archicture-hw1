.data
array0: .word 0x411d, 0xc2c8, 0x426b, 0xc117, 0x3f1a
array1: .word 0x4126, 0x4285, 0x429e, 0xc178, 0x3d76  
length: .word 5
print_input: .string "input = "
print_comma: .string ", "
print_newline: .string "\n"
print_output: .string "output = "

.text
main:
    la s0, array0
    la s1, array1
    lw s2, length
loop:
    beqz s2, end    # if s1 = 0, goto end

    lw t0, 0(s0)
    lw t1, 0(s1)
    addi s2, s2, -1
    addi s0, s0 4
    addi s1, s1 4
    
    # print "input = "
    la a0, print_input
    li a7, 4
    ecall
    # print input value
    mv a0, t0
    li a7, 34
    ecall
    # print ", "
    la a0, print_comma
    li a7, 4
    ecall
    # print input value
    mv a0, t1
    li a7, 34
    ecall
    # call function
    call bf16_add
    
    # print ", "
    la a0, print_comma
    li a7, 4
    ecall
    # print "output = "
    la a0, print_output
    ecall
    # print output value
    mv a0, t1
    li a7 34
    ecall
    # print "\n"
    la a0, print_newline
    li a7, 4
    ecall

    j loop
clz:
    # before clz
    addi sp, sp, -4
    sh t0, 0(sp)
    sh t2, 2(sp)
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
    # after clz
    lh t0, 0(sp)
    lh t2, 2(sp)
    addi sp, sp 4
    ret
bf16_add:
    addi sp, sp, -4
    sw ra, 0(sp)
    # t2 = t0_exp
    slli t2, t0, 17
    srli t2, t2, 24
    # t3 = t1_exp
    slli t3, t1, 17
    srli t3, t3, 24
    blt t2, t3, swap
    # t2 = exp, t4 = sft
    sub t4, t2, t3
    j cal_start
swap: 
    # swap(t0, t1)
    mv t4, t0
    mv t0, t1
    mv t1, t4
    # t2 = exp, t4 = sft
    sub t4, t3, t2
    mv t2, t3
cal_start:
    # t3 = sign
    srli t3, t0, 15
    # t5 = 0 ? add : sub
    xor t5, t0, t1
    srli t5, t5, 15
    # t0 = t0_fra
    andi t0, t0, 127
    ori, t0, t0, 128
    # t1 = t1_fra
    andi t1, t1, 127
    ori t1, t1, 128
    srl t1, t1, t4
    # t0 = fra
    beqz t5, add_operation
    sub t0, t0, t1
    j normalize
add_operation:
    add t0, t0, t1
normalize:
    # t1 = lz
    call clz
    li t4, 8
    addi t1, t1, -8
    # normalize exp
    sub t2, t2, t1
    # t1 = |t1|
    srai t4, t1, 4
    xor t1, t1, t4    
    srli t4, t4, 31
    add t1, t1, t4
    # branch if lz >= 8
    beqz t4, shift_left
    srl t0, t0, t1
    j finish
shift_left:
    sll t0, t0, t1
finish:
    addi t0, t0, -128
    slli t3, t3, 15
    slli t2, t2, 7
    or t1, t0, t2
    or t1, t1, t3
    lw ra, 0(sp)
    addi sp, sp, 4
    ret
end:
    li a7, 10
    ecall
