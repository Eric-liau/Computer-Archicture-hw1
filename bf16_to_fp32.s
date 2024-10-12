.data
array: .word 0x1234, 0x4321, 0xabcd, 0xdcba, 0xffff    
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
    beqz s1, end    # if s1 = 0, goto end

    lw t0, 0(s0)
    addi s1, s1, -1
    addi s0, s0 4

    call bf16_to_fp32

    # print "bf16 = "
    la a0, print_bf16
    li a7, 4
    ecall
    # print bf16 value
    mv a0, t0
    li a7, 34
    ecall
    # print ", "
    la a0, print_comma
    li a7, 4
    ecall
    # print "fp32 = "
    la a0, print_fp32
    ecall
    # print fp32 value
    mv a0, t1
    li a7 34
    ecall
    # print "\n"
    la a0, print_newline
    li a7, 4
    ecall

    j loop

bf16_to_fp32:
    slli t1, t0, 16
    ret

end:
    li a7, 10
    ecall
