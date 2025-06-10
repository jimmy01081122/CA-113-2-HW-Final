.text
.global LIS

LIS:
   # TODO #
   # copy your code (only LIS section) from hw1_2.s #
    # TODO #
    # a0: n (sequence length)
    # a1: address of nums array
    # a2: address of dp array

    # Register Allocation:
    # s0: n (sequence length)
    # s1: address of nums array
    # s2: address of dp array
    # s3: loop counter i
    # s4: loop counter j
    # s5: max_len (stores the maximum value in dp array)
    # t0, t1, t2, t3, t4, t5: temporary registers

    # Save registers
    addi sp, sp, -40
    sw ra, 36(sp)
    sw s0, 32(sp)
    sw s1, 28(sp)
    sw s2, 24(sp)
    sw s3, 20(sp)
    sw s4, 16(sp)
    sw s5, 12(sp)


    # Store input arguments in saved registers
    mv s0, a0  # s0 = n
    mv s1, a1  # s1 = &nums[0]
    mv s2, a2  # s2 = &dp[0]

    # Initialize dp array: dp[i] = 1 for all i from 0 to n-1
    li t0, 1      # t0 = 1 (value to store in dp)
    li s3, 0      # s3 = i = 0
init_loop:
    beq s3, s0, init_loop_end  # if i == n, end initialization
    nop
    nop
    slli t1, s3, 2             # t1 = i * 4 (byte offset)
    nop
    nop
    add t2, s2, t1             # t2 = &dp[i]
    nop
    nop
    sw t0, 0(t2)               # dp[i] = 1
    nop
    nop
    addi s3, s3, 1             # i++
    
    nop
    nop
    j init_loop
init_loop_end:
        
    nop
    nop
    # Outer loop: for i from 1 to n-1
    li s3, 1      # s3 = i = 1
        
    nop
    nop
outer_loop:
    beq s3, s0, outer_loop_end # if i == n, end outer loop
        
    nop
    nop
    # Inner loop: for j from 0 to i-1
    li s4, 0      # s4 = j = 0
        
    nop
    nop
inner_loop:
    beq s4, s3, inner_loop_end # if j == i, end inner loop
        
    nop
    nop
    # Load A[j] and A[i]
    slli t0, s4, 2             # t0 = j * 4
    add t1, s1, t0             # t1 = &nums[j]
        
    nop
    nop
    lw t2, 0(t1)               # t2 = nums[j]
        
    nop
    nop
    slli t3, s3, 2             # t3 = i * 4
        
    nop
    nop
    add t4, s1, t3             # t4 = &nums[i]
        
    nop
    nop
    lw t5, 0(t4)               # t5 = nums[i]

        
    nop
    nop
    # if A[j] < A[i] (nums[j] < nums[i])
    bge t2, t5, skip_update    # if nums[j] >= nums[i], skip update

        
    nop
    nop
    # Load dp[j] and dp[i]
    add t0, s2, t0             # t0 = &dp[j] (reuse t0 for address)
        
    nop
    nop
    lw t1, 0(t0)               # t1 = dp[j]

        
    nop
    nop
    add t3, s2, t3             # t3 = &dp[i] (reuse t3 for address)
        
    nop
    nop
    lw t4, 0(t3)               # t4 = dp[i]

    # Calculate dp[j] + 1
    addi t1, t1, 1             # t1 = dp[j] + 1

    # Update dp[i] = max(dp[i], dp[j] + 1)
        
    nop
    nop
    bge t4, t1, skip_update    # if dp[i] >= dp[j] + 1, skip update
        
    nop
    nop
    sw t1, 0(t3)               # dp[i] = dp[j] + 1

skip_update:
        
    nop
    nop
    addi s4, s4, 1             # j++
        
    nop
    nop
    j inner_loop
inner_loop_end:
        
    nop
    nop
    addi s3, s3, 1             # i++
    
        
    nop
    nop
    j outer_loop
outer_loop_end:

    # Find the maximum value in dp array
        
    nop
    nop
    li s5, 0      # s5 = max_len = 0
        
    nop
    nop
    li s3, 0      # s3 = i = 0
        
    nop
    nop
find_max_loop:
        
    nop
    nop
    beq s3, s0, find_max_loop_end # if i == n, end find max loop
        
    nop
    nop
    slli t0, s3, 2             # t0 = i * 4
        
    nop
    nop
    add t1, s2, t0             # t1 = &dp[i]
        
    nop
    nop
    lw t2, 0(t1)               # t2 = dp[i]
        
    nop
    nop
    ble t2, s5, skip_max_update # if dp[i] <= max_len, skip update
        
    nop
    nop
    mv s5, t2                  # max_len = dp[i]
skip_max_update:
        
    nop
    nop
    addi s3, s3, 1             # i++
        
    nop
    nop
    j find_max_loop
find_max_loop_end:

    # Store the result (max_len) in a0
        
    nop
    nop
    mv a0, s5

    # Restore registers and return
        
    nop
    nop
    lw ra, 36(sp)
        
    nop
    nop
    lw s0, 32(sp)
        
    nop
    nop
    lw s1, 28(sp)
        
    nop
    nop
    lw s2, 24(sp)
        
    nop
    nop
    lw s3, 20(sp)
        
    nop
    nop
    lw s4, 16(sp)
        
    nop
    nop
    lw s5, 12(sp)
        
    nop
    nop
    addi sp, sp, 40
        
    nop
    nop
    ret # Return to main (equivalent to jalr x0, ra, 0)