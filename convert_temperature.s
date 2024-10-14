.data
array: .word 0x41266666, 0xc3463ee6, 0x429d8f5c, 0xc1780000, 0x3d75c28f, 0xc25b7cee
length: .word 6


print_celsius: .string "celsius = "
print_comma: .string ", "
print_newline: .string "\n"
print_kelvin: .string "kelvin = "
print_fahrenheit: .string "fahrenheit = "

.text
main:
    la s0, array
    lw s1, length
loop:
    beqz s1, end    # if s1 = 0, goto end

    lw t0, 0(s0)
    
    # print "celsius = "
    la a0, print_celsius
    li a7, 4
    ecall
    # print celsius value
    mv a0, t0
    li a7, 34
    ecall
    # call convert_kel
    call convert_temperature_kel
    
    # print ", "
    la a0, print_comma
    li a7, 4
    ecall
    # print "kelvin = "
    la a0, print_kelvin
    ecall
    # print kelvin value
    mv a0, t1
    li a7 34
    ecall
    # call convert_fah
    lw t0, 0(s0)
    call convert_temperature_fah

     # print ", "
    la a0, print_comma
    li a7, 4
    ecall
    # print "fahrenheit = "
    la a0, print_fahrenheit
    ecall
    # print fahrenheit value
    mv a0, t1
    li a7 34
    ecall
    # print "\n"
    la a0, print_newline
    li a7, 4
    ecall
    
    addi s1, s1, -1
    addi s0, s0 4
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
bf16_mul:
    addi sp, sp -4
    sw ra, 0(sp)
    # t2 = sign
    xor t2, t0, t1
    srli, t2, t2, 15
    # t3 = exp
    slli t3, t0, 17
    srli t3, t3, 24
    slli t4, t1, 17
    srli t4, t4, 24
    add t3, t3, t4
    addi t3, t3, -127
    # t0 = fra
    andi t0, t0, 127
    ori t0, t0, 128
    andi t1, t1, 127
    ori t1, t1, 128
    mul t0, t0, t1
    srli t0, t0, 7
    call clz
    li t4, 8
    sub t1, t4, t1
    srl t0, t0, t1
    add t3, t3, t1
    addi t0, t0, -128
    slli t2, t2, 15
    slli t3, t3, 7
    or t1, t0, t2
    or t1, t1, t3
    lw ra, 0(sp)
    addi sp, sp, 4
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
convert_temperature_kel:
    addi sp, sp, -4
    sw ra, 0(sp)
    call fp32_to_bf16
    li t0 0x4389        # (bf16)273.15
    call bf16_add
    lw ra, 0(sp)
    addi sp, sp, 4
    ret
convert_temperature_fah:
    addi sp, sp, -4
    sw ra, 0(sp)
    call fp32_to_bf16
    li t0 0x3fe6        # (bf16)1.8
    call bf16_mul
    li t0 0x4200        # (bf16)32
    call bf16_add
    lw ra, 0(sp)
    addi sp, sp, 4
    ret
end:
    li a7, 10
    ecall
