###############################################################################
# Matrix-Chain Multiplication (DP) — RISC-V RV32IM
#   no-free 版本：呼叫端在使用完畢後自行 free 結果矩陣
###############################################################################
    .text
    .globl  matrix_chain_multiplication

###############################################################################
# matrix_chain_multiplication(int** matrices, int* rows, int* cols, int N)
#   a0=matrices  a1=rows  a2=cols  a3=N
#   ret a0 → 最終乘積矩陣 (caller 之後自行 free)
###############################################################################
matrix_chain_multiplication:
    # ─── prologue ───────────────────────────────────────────────────────────
    addi    sp, sp, -48
    sw      ra,  44(sp)
    sw      s0,  40(sp)
    sw      s1,  36(sp)
    sw      s2,  32(sp)
    sw      s3,  28(sp)
    sw      s4,  24(sp)
    sw      s5,  20(sp)
    sw      s6,  16(sp)
    sw      s7,  12(sp)
    sw      s8,   8(sp)
    sw      s9,   4(sp)
    sw      s10,  0(sp)

    mv      s0, a0          # matrices**
    mv      s1, a1          # rows*
    mv      s2, a2          # cols*
    mv      s3, a3          # N

    # ─── malloc DP-buffer：cost(N×N)+split(N×N)+dims(N+1) ──────────────────
    mul     s7, s3, s3      # s7 = N*N
    slli    s7, s7, 2       # bytes of 1 N×N int matrix
    add     t2, s7, s7      # cost + split
    addi    t3, s3, 1
    slli    t3, t3, 2       # bytes of dims
    add     t3, t2, t3      # total bytes
    mv      a0, t3
    call    malloc
    mv      s4, a0          # cost base
    add     s5, s4, s7      # split base
    add     s6, s5, s7      # dims  base

    # ─── build dims[0]=rows[0]; dims[i+1]=cols[i] ──────────────────────────
    lw      t0, 0(s1)
    sw      t0, 0(s6)
    li      t1, 0
dims_loop:
    bge     t1, s3, dims_done
    slli    t2, t1, 2
    add     t3, s2, t2
    lw      t4, 0(t3)
    addi    t2, t2, 4
    add     t5, s6, t2
    sw      t4, 0(t5)
    addi    t1, t1, 1
    j       dims_loop
dims_done:

    # ─── cost[i][i] = 0 ─────────────────────────────────────────────────────
    li      t0, 0
diag_loop:
    bge     t0, s3, diag_done
    mul     t1, t0, s3
    add     t1, t1, t0
    slli    t1, t1, 2
    add     t1, s4, t1
    sw      zero, 0(t1)
    addi    t0, t0, 1
    j       diag_loop
diag_done:

    # ─── bottom-up DP ───────────────────────────────────────────────────────
    li      t0, 2
len_loop:
    bgt     t0, s3, dp_done
    li      t1, 0
i_loop:
    sub     t2, s3, t0
    blt     t2, t1, next_len
    add     t3, t1, t0
    addi    t3, t3, -1      # j

    # cost[i][j] = ∞
    mul     t4, t1, s3
    add     t4, t4, t3
    slli    t4, t4, 2
    add     t4, s4, t4
    li      t5, 0x7fffffff
    sw      t5, 0(t4)

    mv      t6, t1          # k = i
k_loop:
    beq     t6, t3, k_done
    # q = cost[i][k] + cost[k+1][j] +
    #     dims[i] * dims[k+1] * dims[j+1]
    mul     a4, t1, s3
    add     a4, a4, t6
    slli    a4, a4, 2
    add     a4, s4, a4
    lw      a4, 0(a4)

    addi    a5, t6, 1
    mul     a5, a5, s3
    add     a5, a5, t3
    slli    a5, a5, 2
    add     a5, s4, a5
    lw      a5, 0(a5)
    add     a4, a4, a5

    slli    a6, t1, 2
    add     a6, s6, a6
    lw      a6, 0(a6)        # dims[i]

    addi    a7, t6, 1
    slli    a7, a7, 2
    add     a7, s6, a7
    lw      a7, 0(a7)        # dims[k+1]

    mul     a6, a6, a7       # dims[i]*dims[k+1]

    addi    a7, t3, 1
    slli    a7, a7, 2
    add     a7, s6, a7
    lw      a7, 0(a7)        # dims[j+1]

    mul     a6, a6, a7
    add     a4, a4, a6       # q

    lw      a5, 0(t4)
    bge     a4, a5, skip_store
    sw      a4, 0(t4)        # cost[i][j] = q
    mul     a5, t1, s3
    add     a5, a5, t3
    slli    a5, a5, 2
    add     a5, s5, a5
    sw      t6, 0(a5)        # split[i][j] = k
skip_store:
    addi    t6, t6, 1
    j       k_loop
k_done:
    addi    t1, t1, 1
    j       i_loop
next_len:
    addi    t0, t0, 1
    j       len_loop
dp_done:

    # ─── build 結果矩陣 ──────────────────────────────────────────────────────
    li      a0, 0
    addi    a1, s3, -1
    call    _mcm_rec         # a0 = final matrix ptr

    # ─── epilogue ───────────────────────────────────────────────────────────
    lw      s10, 0(sp)
    lw      s9 , 4(sp)
    lw      s8 , 8(sp)
    lw      s7 ,12(sp)
    lw      s6 ,16(sp)
    lw      s5 ,20(sp)
    lw      s4 ,24(sp)
    lw      s3 ,28(sp)
    lw      s2 ,32(sp)
    lw      s1 ,36(sp)
    lw      s0 ,40(sp)
    lw      ra ,44(sp)
    addi    sp, sp, 48
    jr      ra

###############################################################################
# _mcm_rec(i,j) — no-free 版本
###############################################################################
_mcm_rec:
    addi    sp, sp, -48
    sw      ra, 44(sp)
    sw      a0, 40(sp)      # i
    sw      a1, 36(sp)      # j
    beq     a0, a1, _mcm_leaf

    mul     t0, a0, s3
    add     t0, t0, a1
    slli    t0, t0, 2
    add     t0, s5, t0
    lw      t0, 0(t0)       # k
    sw      t0, 32(sp)

    mv      a1, t0
    call    _mcm_rec
    sw      a0, 28(sp)

    lw      t0, 32(sp)
    addi    a0, t0, 1
    lw      a1, 36(sp)
    call    _mcm_rec
    sw      a0, 24(sp)

    lw      a0, 28(sp)
    lw      a1, 24(sp)
    lw      t1, 40(sp)       # i
    slli    t2, t1, 2
    add     t2, s6, t2
    lw      a2, 0(t2)        # rowsA
    lw      t0, 32(sp)       # k
    addi    t0, t0, 1
    slli    t2, t0, 2
    add     t2, s6, t2
    lw      a3, 0(t2)        # colsA / rowsB
    lw      t3, 36(sp)       # j
    addi    t3, t3, 1
    slli    t2, t3, 2
    add     t2, s6, t2
    lw      a4, 0(t2)        # colsB
    call    _matmul_core
    lw      ra, 44(sp)
    addi    sp, sp, 48
    jr      ra

###############################################################################
# _mcm_leaf(i,i) — 直接回傳 matrices[i]
###############################################################################
_mcm_leaf:
    slli    t0, a0, 2
    add     t0, s0, t0
    lw      a0, 0(t0)
    lw      ra, 44(sp)
    addi    sp, sp, 48
    jr      ra

###############################################################################
# _matmul_core(A,B,rowsA,colsA,colsB) → C
#   **移除 t7 / t8，改用 a6 / a7**
###############################################################################
_matmul_core:
    addi    sp, sp, -16
    sw      ra, 12(sp)
    sw      a2,  8(sp)      # rowsA
    sw      a3,  4(sp)      # colsA
    sw      a4,  0(sp)      # colsB

    mv      t5, a0          # A
    mv      t6, a1          # B

    mul     t0, a2, a4
    slli    t0, t0, 2
    mv      a0, t0
    call    malloc
    mv      t4, a0          # C

    # 取回 rowsA, colsA, colsB
    lw      a2,  8(sp)
    lw      a3,  4(sp)
    lw      a4,  0(sp)

    mv      a0, t5          # A
    mv      a1, t6          # B

    lw      ra, 12(sp)
    addi    sp, sp, 16

    # ---------- 清零結果矩陣 ----------
    mul     t1, a2, a4      # 元素數
    li      t0, 0
zero_loop:
    beq     t0, t1, zero_done
    slli    a6, t0, 2
    add     a6, t4, a6
    sw      zero, 0(a6)
    addi    t0, t0, 1
    j       zero_loop
zero_done:

    # ---------- 矩陣乘法 ----------
    li      t0, 0           # i
mm_i:
    bge     t0, a2, mm_done
    li      t1, 0           # j
mm_j:
    bge     t1, a4, mm_j_end
    li      t2, 0           # k
    li      t3, 0           # acc
mm_k:
    bge     t2, a3, mm_k_end
    # A[i][k] → a6
    mul     a6, t0, a3
    add     a6, a6, t2
    slli    a6, a6, 2
    add     a6, a0, a6
    lw      a6, 0(a6)

    # B[k][j] → a7
    mul     a7, t2, a4
    add     a7, a7, t1
    slli    a7, a7, 2
    add     a7, a1, a7
    lw      a7, 0(a7)

    mul     a6, a6, a7
    add     t3, t3, a6

    addi    t2, t2, 1
    j       mm_k
mm_k_end:
    mul     a6, t0, a4
    add     a6, a6, t1
    slli    a6, a6, 2
    add     a6, t4, a6
    sw      t3, 0(a6)

    addi    t1, t1, 1
    j       mm_j
mm_j_end:
    addi    t0, t0, 1
    j       mm_i
mm_done:
    mv      a0, t4
    jr      ra
