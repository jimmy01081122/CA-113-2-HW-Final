.text
.globl matrix_chain_multiplication

# -----------------------------------------------------------------------------
# int* matrix_chain_multiplication(int** matrices, int* rows, int* cols, int count)
#   a0 = matrices (int**)
#   a1 = rows     (int*)
#   a2 = cols     (int*)
#   a3 = count    (int)
# Returns: a0 = pointer to final product matrix (heap) — caller must free.
# -----------------------------------------------------------------------------
# Callee‑saved registers used
#   s0  : M_idx       (current input matrix pointer)
#   s1  : matrices**
#   s2  : rows*
#   s3  : cols*
#   s4  : res_ptr     (current result matrix)
#   s5  : res_rows    (constant after first copy)
#   s6  : res_cols    (updated every iteration)
#   s7  : idx         (0‑based matrix index)
#   s8  : count       (total matrices)
#   s9  : old_ptr     (pointer to matrix to be freed)
# -----------------------------------------------------------------------------
# Caller‑saved temporaries
#   a4  : new_ptr  (malloc return; may be clobbered by free)
#   t0‑t6 : loop / math temps (RV32 has t0‑t6)
# -----------------------------------------------------------------------------

matrix_chain_multiplication:
    # ---------------- Prologue ---------------------------------------------
    addi    sp, sp, -(11*4)         # ra + s0‑s9  (11 words = 44 bytes)
    sw      ra,  40(sp)
    sw      s0,  36(sp)
    sw      s1,  32(sp)
    sw      s2,  28(sp)
    sw      s3,  24(sp)
    sw      s4,  20(sp)
    sw      s5,  16(sp)
    sw      s6,  12(sp)
    sw      s7,   8(sp)
    sw      s8,   4(sp)
    sw      s9,   0(sp)

    mv      s1, a0                  # matrices**
    mv      s2, a1                  # rows*
    mv      s3, a2                  # cols*
    mv      s8, a3                  # count
    li      s7, 0                   # idx = 0

    # ------------- Copy matrices[0] ----------------------------------------
    lw      s5, 0(s2)               # res_rows = rows[0]
    lw      s6, 0(s3)               # res_cols = cols[0]

    mul     t0, s5, s6              # rows*cols
    slli    t0, t0, 2               # *4 bytes
    mv      a0, t0
    call    malloc
    mv      s4, a0                  # res_ptr

    lw      t1, 0(s1)               # src = matrices[0]
    srai    t2, t0, 2               # word count
    li      t3, 0
copy_loop:
    beq     t3, t2, copy_done
    slli    t4, t3, 2
    add     t5, t1, t4
    lw      t6, 0(t5)
    add     t5, s4, t4
    sw      t6, 0(t5)
    addi    t3, t3, 1
    j       copy_loop
copy_done:

    addi    s7, s7, 1               # idx = 1

# ------------- Main loop ---------------------------------------------------
main_loop:
    blt     s7, s8, process_next
    j       finish

process_next:
    slli    t0, s7, 2               # offset bytes = idx*4

    # new_cols = cols[idx]
    add     t1, s3, t0
    lw      t1, 0(t1)
    mv      t6, t1                  # cache new_cols

    # allocate new result matrix
    mul     t2, s5, t6
    slli    t2, t2, 2
    mv      a0, t2
    call    malloc
    mv      a4, a0                  # new_ptr

    # M_idx = matrices[idx]
    add     t3, s1, t0
    lw      s0, 0(t3)

    # ---------- triple‑nested loops ----------------------------------------
    li      t0, 0                   # i = 0
loop_i:
    bge     t0, s5, loop_i_done

    li      t1, 0                   # j = 0
loop_j:
    bge     t1, t6, loop_j_done

    li      t2, 0                   # k = 0
    li      t3, 0                   # sum = 0
loop_k:
    bge     t2, s6, loop_k_done

    # valA = R[i,k]
    mul     t4, t0, s6
    add     t4, t4, t2
    slli    t4, t4, 2
    add     t5, s4, t4
    lw      t5, 0(t5)

    # valB = M[k,j]
    mul     t4, t2, t6
    add     t4, t4, t1
    slli    t4, t4, 2
    add     t4, s0, t4
    lw      t4, 0(t4)

    mul     t4, t5, t4
    add     t3, t3, t4

    addi    t2, t2, 1
    j       loop_k
loop_k_done:
    mul     t4, t0, t6
    add     t4, t4, t1
    slli    t4, t4, 2
    add     t4, a4, t4
    sw      t3, 0(t4)

    addi    t1, t1, 1
    j       loop_j
loop_j_done:
    addi    t0, t0, 1
    j       loop_i
loop_i_done:

    # safe free old result matrix
    mv      s9, s4                  # old_ptr → s9 (callee‑saved)
    mv      s4, a4                  # res_ptr = new_ptr
    mv      s6, t6                  # res_cols = new_cols
    mv      a0, s9                  # arg0 = old_ptr
    call    free

    addi    s7, s7, 1               # idx++
    j       main_loop

# ------------- Finish -------------------------------------------------------
finish:
    mv      a0, s4                  # return res_ptr

    # Epilogue: restore
    lw      s9,   0(sp)
    lw      s8,   4(sp)
    lw      s7,   8(sp)
    lw      s6,  12(sp)
    lw      s5,  16(sp)
    lw      s4,  20(sp)
    lw      s3,  24(sp)
    lw      s2,  28(sp)
    lw      s1,  32(sp)
    lw      s0,  36(sp)
    lw      ra,  40(sp)
    addi    sp, sp, (11*4)
    jr      ra
