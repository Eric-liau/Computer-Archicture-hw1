.data
array: .word 0x12345678, 0x87654321, 0xabcd1234, 0xdcbaabcd, 0x7ff1234    
length: .word 5
print_bf16: .string "bf16 = "
print_comma: .string ", "
print_newline: .string "\n"
print_fp32: .string "fp32 = "

.text
main:
    la s0, array
    lw s1, length
loop:
    beqz s1, end 

    lw t0, 0(s0)
    addi s1, s1, -1
    addi s0, s0 4

    call fp32_to_bf16

    # print "fp32 = "
    la a0, print_fp32
    li a7, 4
    ecall
    # print fp32 value
    mv a0, t0
    li a7, 34
    ecall
    # print ", "
    la a0, print_comma
    li a7, 4
    ecall
    # print "bf16 = "
    la a0, print_bf16
    ecall
    # print bf16 value
    mv a0, t1
    li a7 34
    ecall
    # print "\n"
    la a0, print_newline
    li a7, 4
    ecall

    j loop

fp32_to_bf16:
    # NaN detect
    li t1, 0x7fffffff
    li t2, 0x7f800000
    and t3, t0, t1
    blt t2, t3, NaN
notNaN:
    srli t1, t0, 16
    andi t1, t1, 1
    li t2, 0x7fff
    add t1, t1, t2
    add t1, t0, t1
    srli t1, t1, 16
    ret
NaN:
    srli t1, t0, 16
    ori t1, t1, 64
    ret
end:
    li a7, 10
    ecall
