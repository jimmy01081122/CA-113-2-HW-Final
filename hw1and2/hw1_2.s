.data
nums:   .word 4, 5, 1, 8, 3, 6, 9 ,2    # input sequence
n:      .word 8                        # sequence length
dp:     .word 0, 0, 0, 0, 0, 0, 0, 0, 0   # dp array
.text
.globl main

# This is 1132 CA Homework 1 Problem 2
# Implement Longest Increasing Subsequence Algorithm (Optimized)
# Input:
# sequence length (n) store in a0
# address of sequence store in a1
# address of dp array with length n store in a2 (we can decide to use or not)
# Output: Length of Longest Increasing Subsequenc in a0(x10)
# DO NOT MODIFY "main" FUNCTION !!!
main:
    lw a0, n          # a0 = n
    la a1, nums       # a1 = &nums[0]
    la a2, dp         # a2 = &dp[0]

    jal LIS         # Jump to LIS algorithm

    # Exit program
    # System id for exit is 10 in Ripes, 93 in GEM5
    li a7, 93 # 保持 GEM5 的 exit code
    ecall

LIS:
    # 優化說明:
    # - 使用指標遞增優化位址計算 (addi ptr, ptr, 4)
    # - 減少內層迴圈記憶體存取:
    #   - 在內層迴圈前載入 nums[i] (存於 t5) 和初始 dp[i] (存於 t6)
    #   - 在內層迴圈計算期間，更新保存在暫存器 t6 中的 dp[i] 值
    #   - 在內層迴圈結束後才將最終的 dp[i] (來自 t6) 存回記憶體

    # Register Allocation (優化後):
    # s0: n (sequence length)
    # s1: base address of nums array
    # s2: base address of dp array
    # s3: outer loop counter i
    # s4: inner loop counter j
    # s5: max_len (stores the maximum value in dp array)
    # t0: temporary, often holds dp[j] or dp[j]+1
    # t1: pointer for inner loop nums[j] access (&nums[j]) OR pointer for dp init/max find
    # t2: temporary, holds nums[j] value OR dp[i] value during max find
    # t3: pointer for inner loop dp[j] access (&dp[j])
    # t4: pointer for outer loop dp[i] access (&dp[i])
    # t5: holds nums[i] value during inner loop
    # t6: holds current dp[i] value during inner loop calculation

    # Save registers
    addi sp, sp, -48  # 分配 48 bytes 確保 8 位元組對齊 (保存 7 個 word)
    sw ra, 44(sp)
    sw s0, 40(sp)
    sw s1, 36(sp)
    sw s2, 32(sp)
    sw s3, 28(sp)
    sw s4, 24(sp)
    sw s5, 20(sp)
    # 16(sp), 12(sp), 8(sp), 4(sp), 0(sp) 可用

    # Store input arguments in saved registers
    mv s0, a0  # s0 = n
    mv s1, a1  # s1 = &nums[0]
    mv s2, a2  # s2 = &dp[0]

    # Initialize dp array: dp[i] = 1 for all i from 0 to n-1 (使用指標優化)
    li t0, 1      # t0 = 1 (value to store in dp)
    li s3, 0      # s3 = i = 0
    mv t1, s2     # t1 = current &dp[i], starting at &dp[0]
init_loop:
    beq s3, s0, init_loop_end  # if i == n, end initialization
    sw t0, 0(t1)               # dp[i] = 1
    addi t1, t1, 4             # Increment dp pointer (&dp[i+1])
    addi s3, s3, 1             # i++
    j init_loop
init_loop_end:

    # Outer loop: for i from 1 to n-1
    li s3, 1      # s3 = i = 1
outer_loop:
    beq s3, s0, outer_loop_end # if i == n (or i >= n), end outer loop

    # --- 優化點: 內層迴圈前準備 ---
    # 計算 &nums[i] = &nums[0] + i * 4
    slli t0, s3, 2
    add t4, s1, t0             # t4 = &nums[i]
    lw t5, 0(t4)               # t5 = nums[i] (載入一次)

    # 計算 &dp[i] = &dp[0] + i * 4
    # t0 仍然是 i*4
    add t4, s2, t0             # t4 = &dp[i]
    lw t6, 0(t4)               # t6 = current dp[i] (載入一次，存入 t6 供內層迴圈更新)
    # --- 準備結束 ---

    # Inner loop: for j from 0 to i-1 (使用指標優化)
    li s4, 0      # s4 = j = 0
    mv t1, s1     # t1 = &nums[j], starting at &nums[0]
    mv t3, s2     # t3 = &dp[j], starting at &dp[0]
inner_loop:
    beq s4, s3, inner_loop_end # if j == i, end inner loop

    # Load A[j] (nums[j]) using pointer t1
    lw t2, 0(t1)               # t2 = nums[j]

    # if A[j] < A[i] (nums[j] < nums[i])? (t2 < t5)
    bge t2, t5, skip_update    # if nums[j] >= nums[i], skip update

    # Load dp[j] using pointer t3
    lw t0, 0(t3)               # t0 = dp[j]
    addi t0, t0, 1             # t0 = dp[j] + 1

    # Update dp[i] = max(dp[i], dp[j] + 1)
    # Compare current dp[i] (in t6) with potential new value (dp[j] + 1 in t0)
    # --- 優化點: 更新暫存器中的 dp[i] ---
    bge t6, t0, skip_update    # if current dp[i] (t6) >= dp[j] + 1 (t0), skip update
    mv t6, t0                  # Update dp[i] in register: t6 = dp[j] + 1
    # --- 更新結束 (不寫回記憶體) ---

skip_update:
    addi t1, t1, 4             # Increment nums pointer (&nums[j+1])
    addi t3, t3, 4             # Increment dp pointer (&dp[j+1])
    addi s4, s4, 1             # j++
    j inner_loop
inner_loop_end:
    # --- 優化點: 內層迴圈結束後才寫回 dp[i] ---
    # t4 仍然是 &dp[i]
    sw t6, 0(t4)               # Store final dp[i] from register t6 back to memory
    # --- 寫回結束 ---

    addi s3, s3, 1             # i++
    j outer_loop
outer_loop_end:

    # Find the maximum value in dp array (使用指標優化)
    # li s5, 0 --> LIS 至少為 1，可以從 dp[0] 開始
    lw s5, 0(s2) # s5 = max_len = dp[0]
    li s3, 1      # s3 = i = 1 (從 1 開始比較)
    addi t1, s2, 4 # t1 = &dp[1]
find_max_loop:
    beq s3, s0, find_max_loop_end # if i == n, end find max loop
    lw t2, 0(t1)               # t2 = dp[i]
    ble t2, s5, skip_max_update # if dp[i] <= max_len, skip update
    mv s5, t2                  # max_len = dp[i]
skip_max_update:
    addi t1, t1, 4             # Increment dp pointer (&dp[i+1])
    addi s3, s3, 1             # i++
    j find_max_loop
find_max_loop_end:

    # Store the result (max_len) in a0
    mv a0, s5

    # Restore registers and return
    lw ra, 44(sp)
    lw s0, 40(sp)
    lw s1, 36(sp)
    lw s2, 32(sp)
    lw s3, 28(sp)
    lw s4, 24(sp)
    lw s5, 20(sp)
    addi sp, sp, 48 # 恢復堆疊指標，大小需匹配

    ret # Return to main (equivalent to jalr x0, ra, 0)

