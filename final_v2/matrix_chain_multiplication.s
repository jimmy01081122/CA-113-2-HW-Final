###############################################################################
# Matrix-Chain Multiplication (DP) — RISC-V RV32IM

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
# _mcm_rec(i,j) 
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
# _mcm_leaf(i,i) 
###############################################################################
_mcm_leaf:
    slli    t0, a0, 2
    add     t0, s0, t0
    lw      a0, 0(t0)
    lw      ra, 44(sp)
    addi    sp, sp, 48
    jr      ra
###############################################################################
# _matmul_core_tile8(A,B,rowsA,colsA,colsB) → C
#   - 8×8 blocking
###############################################################################
_matmul_core:
    # ─── prologue ───────────────────────────────────────────────────────────
    addi    sp, sp, -56
    sw      ra, 52(sp)
    sw      s0, 48(sp)
    sw      s1, 44(sp)
    sw      s2, 40(sp)
    sw      s3, 36(sp)
    sw      s4, 32(sp)
    sw      s5, 28(sp)
    sw      s6, 24(sp)
    sw      s7, 20(sp)
    sw      s8, 16(sp)
    sw      s9, 12(sp)
    sw      s10, 8(sp)

    # -------- 參數搬到 s-register --------
    mv  s0, a0          # baseA
    mv  s1, a1          # baseB
    mv  s2, a2          # rowsA (M)
    mv  s3, a3          # colsA (K)
    mv  s4, a4          # colsB (N)

    slli s5, s3, 2      # strideA (bytes)
    slli s6, s4, 2      # strideB / strideC (bytes)

    # malloc M*N*4
    mul  t0, s2, s4
    slli t0, t0, 2
    mv   a0, t0
    call malloc
    mv   s7, a0         # baseC

    # ---------- 整個 C 先清 0 ----------
    mul  t1, s2, s4     # element count
    li   t0, 0
zero_loop:
    beq  t0, t1, zero_done
    slli a2, t0, 2
    add  a2, s7, a2
    sw   zero, 0(a2)
    addi t0, t0, 1
    j    zero_loop
zero_done:

    # -------- 常數 --------
    li   s8, 8          # TILE = 8
    slli s9, s8, 2      # 32

    ########################################################################
    # 3-level  (iT, jT, kT)
    ########################################################################
    li   t0, 0              # iT
outer_i:
    bge  t0, s2, mm_end

    li   t1, 0              # jT
outer_j:
    bge  t1, s4, next_i

    # -------- rowCptr = &C[iT][jT] --------
    mul  t2, t0, s6         # iT * strideC
    add  t6, s7, t2
    slli a2, t1, 2          # a2 = jT * 4
    add  t6, t6, a2         # t6 = &C[iT][jT]

    # -------- kT sweep --------
    li   t2, 0              # kT
kT_loop:
    bge  t2, s3, next_j

    #    A_tile = &A[iT][kT]
    mul  t3, t0, s5
    add  t3, s0, t3
    slli a2, t2, 2
    add  t3, t3, a2         # t3 = A base for this tile row

    #    B_tile = &B[kT][jT]
    mul  t4, t2, s6
    add  t4, s1, t4
    slli a2, t1, 2
    add  t4, t4, a2         # t4 = B base for this tile col

    # -------- 8×8×8 乘加 --------
    li   a4, 0              # ii
tile_row:
    bge  a4, s8, next_kT

        # 若 iT+ii ≥ rowsA，直接跳過
        add  a2, t0, a4
        bge  a2, s2, row_skip

        li   a5, 0          # kk
row_k:
        bge  a5, s8, row_done

            # 若 kT+kk ≥ colsA，跳過
            add  a3, t2, a5
            bge  a3, s3, k_skip

            # valA = A[iT+ii][kT+kk]
            mul  a6, a4, s3
            add  a6, a6, a5
            slli a6, a6, 2
            add  a6, t3, a6
            lw   a6, 0(a6)

            # -------- col loop (jj) --------
            li   a7, 0                  # jj
col_loop:
            bge  a7, s8, col_done

                # 超出 colsB 時直接跳過
                add  a2, t1, a7
                bge  a2, s4, col_skip

                # valB = B[kT+kk][jT+jj]
                mul  a3, a5, s4
                add  a3, a3, a7
                slli a3, a3, 2
                add  a3, t4, a3
                lw   a3, 0(a3)

                mul  a3, a3, a6          # valA * valB

                # ---------- 計算 &C[iT+ii][jT+jj] ----------
                mul  a2, a4, s6          # rowOffset = ii * strideC
                slli t5, a7, 2           # t5 = jj * 4 
                add  a2, a2, t5
                add  a2, a2, t6          # ptrC

                lw   t5, 0(a2)           
                add  t5, t5, a3          
                sw   t5, 0(a2)           

col_skip:
                addi a7, a7, 1
                j    col_loop
col_done:




k_skip:
            addi a5, a5, 1
            j    row_k
row_done:
row_skip:
        addi a4, a4, 1
        j    tile_row
next_kT:
    addi t2, t2, 8
    j    kT_loop

next_j:
    addi t1, t1, 8
    j    outer_j
next_i:
    addi t0, t0, 8
    j    outer_i

mm_end:
    mv   a0, s7          # return C*

    # ─── epilogue ───────────────────────────────────────────────────────────
    lw  s10, 8(sp)
    lw  s9 ,12(sp)
    lw  s8 ,16(sp)
    lw  s7 ,20(sp)
    lw  s6 ,24(sp)
    lw  s5 ,28(sp)
    lw  s4 ,32(sp)
    lw  s3 ,36(sp)
    lw  s2 ,40(sp)
    lw  s1 ,44(sp)
    lw  s0 ,48(sp)
    lw  ra ,52(sp)
    addi sp, sp, 56
    jr   ra

