.data
# No writable global variables are needed for this assignment.

.section .rodata
# ============================================================
# asgn8.s
# CS330 - Assignment 8
#
# This program implements four assembly language functions:
#   1) prime_factors  - prints the prime factors of an integer
#   2) fib            - recursively computes the n-th Fibonacci number
#   3) linear_search  - searches a hardcoded array from left to right
#   4) binary_search  - searches a sorted hardcoded array using binary search
#
# Calling convention used throughout the file:
#   - First integer argument is passed in RDI
#   - Return values are placed in RAX
#   - printf / scanf are used for user interaction and verification
#
# Bonus feature:
#   - The program takes user input for all four demonstrations.
# ============================================================

# Input / output strings
prompt_pf:          .string "Enter a positive integer for prime factorization: "
prompt_fib:         .string "Enter n for Fibonacci: "
prompt_linear:      .string "Enter key for linear search: "
prompt_binary:      .string "Enter key for binary search: "
scan_fmt:           .string "%ld"

pf_intro:           .string "Prime factors of %ld: "
factor_fmt:         .string "%ld "
newline_fmt:        .string "\n"
invalid_pf_fmt:     .string "Input must be greater than 1 to have prime factors.\n"
negative_fib_fmt:   .string "Negative Fibonacci input entered, so the program will use 0.\n"
fib_result_fmt:     .string "fib(%ld) = %ld\n"
found_fmt:          .string "%s: key %ld found at index %ld\n"
not_found_fmt:      .string "%s: key %ld not found\n"
linear_label:       .string "Linear search"
binary_label:       .string "Binary search"

# Hardcoded sorted array used by both search functions.
search_array:       .quad 2, 4, 6, 8, 10

.text
.global main
.extern printf
.extern scanf

# ============================================================
# prime_factors
# ------------------------------------------------------------
# Purpose:
#   Prints all prime factors of the positive integer passed in RDI.
#
# Argument:
#   RDI = number n
#
# Return value:
#   None required for grading. The function prints the factors directly.
#
# Local storage:
#   -8(%rbp)  = current n being factored
#   -16(%rbp) = current odd divisor i
#   -24(%rbp) = quotient after successful division
#
# Important idea:
#   First remove all factors of 2. After that, only odd divisors
#   need to be tested. If a value greater than 2 remains at the end,
#   that remaining value is also prime.
# ============================================================
prime_factors:
    pushq %rbp
    movq %rsp, %rbp
    subq $32, %rsp

    movq %rdi, -8(%rbp)

    # Guard against inputs like 0, 1, or negative values.
    cmpq $1, -8(%rbp)
    jg pf_print_intro

    leaq invalid_pf_fmt(%rip), %rdi
    xorl %eax, %eax
    call printf
    leave
    ret

pf_print_intro:
    # Print heading: "Prime factors of n: "
    leaq pf_intro(%rip), %rdi
    movq -8(%rbp), %rsi
    xorl %eax, %eax
    call printf

# Repeatedly divide by 2 while n is even.
pf_even_loop:
    movq -8(%rbp), %rax
    cmpq $2, %rax
    jl pf_odd_setup
    testq $1, %rax
    jne pf_odd_setup

    leaq factor_fmt(%rip), %rdi
    movq $2, %rsi
    xorl %eax, %eax
    call printf

    movq -8(%rbp), %rax
    shrq $1, %rax
    movq %rax, -8(%rbp)
    jmp pf_even_loop

# Start checking odd divisors from 3 upward.
pf_odd_setup:
    movq $3, -16(%rbp)

# Continue while i*i <= n.
pf_odd_loop:
    movq -16(%rbp), %rcx
    movq %rcx, %rax
    imulq %rcx, %rax
    movq -8(%rbp), %rdx
    cmpq %rdx, %rax
    jg pf_after_loop

    # Divide n by i and inspect the remainder.
    movq -8(%rbp), %rax
    cqto
    idivq %rcx
    cmpq $0, %rdx
    jne pf_next_odd

    # Save the quotient before calling printf because caller-saved
    # registers may be overwritten by function calls.
    movq %rax, -24(%rbp)

    leaq factor_fmt(%rip), %rdi
    movq -16(%rbp), %rsi
    xorl %eax, %eax
    call printf

    movq -24(%rbp), %rax
    movq %rax, -8(%rbp)
    jmp pf_odd_loop

pf_next_odd:
    addq $2, -16(%rbp)
    jmp pf_odd_loop

# If n is still greater than 2 here, it is the last prime factor.
pf_after_loop:
    movq -8(%rbp), %rax
    cmpq $2, %rax
    jle pf_finish

    leaq factor_fmt(%rip), %rdi
    movq %rax, %rsi
    xorl %eax, %eax
    call printf

pf_finish:
    leaq newline_fmt(%rip), %rdi
    xorl %eax, %eax
    call printf

    leave
    ret

# ============================================================
# fib
# ------------------------------------------------------------
# Purpose:
#   Recursively computes the n-th Fibonacci number.
#
# Argument:
#   RDI = n
#
# Return value:
#   RAX = fib(n)
#
# Local storage:
#   -8(%rbp)  = original n
#   -16(%rbp) = temporary storage for fib(n-1)
#
# Base cases:
#   fib(0) = 0
#   fib(1) = 1
#
# Note:
#   A negative n is treated as 0 to keep the function safe.
# ============================================================
fib:
    pushq %rbp
    movq %rsp, %rbp
    subq $16, %rsp

    cmpq $0, %rdi
    jl fib_negative

    cmpq $1, %rdi
    jle fib_base_case

    # Save original n because recursive calls change RDI.
    movq %rdi, -8(%rbp)

    # First recursive call: fib(n - 1)
    movq -8(%rbp), %rdi
    subq $1, %rdi
    call fib
    movq %rax, -16(%rbp)

    # Second recursive call: fib(n - 2)
    movq -8(%rbp), %rdi
    subq $2, %rdi
    call fib

    # Combine the two recursive results.
    addq -16(%rbp), %rax
    leave
    ret

fib_base_case:
    movq %rdi, %rax
    leave
    ret

fib_negative:
    movq $0, %rax
    leave
    ret

# ============================================================
# linear_search
# ------------------------------------------------------------
# Purpose:
#   Searches the hardcoded array from left to right.
#
# Argument:
#   RDI = key to search for
#
# Return value:
#   RAX = index if found, otherwise -1
#
# Register usage:
#   RSI = base address of array
#   RCX = current index
#   RDX = current array element
# ============================================================
linear_search:
    pushq %rbp
    movq %rsp, %rbp

    leaq search_array(%rip), %rsi
    movq $0, %rcx

ls_loop:
    cmpq $5, %rcx
    jge ls_not_found

    movq (%rsi,%rcx,8), %rdx
    cmpq %rdi, %rdx
    je ls_found

    incq %rcx
    jmp ls_loop

ls_found:
    movq %rcx, %rax
    popq %rbp
    ret

ls_not_found:
    movq $-1, %rax
    popq %rbp
    ret

# ============================================================
# binary_search
# ------------------------------------------------------------
# Purpose:
#   Performs binary search on the same sorted hardcoded array.
#
# Argument:
#   RDI = key to search for
#
# Return value:
#   RAX = index if found, otherwise -1
#
# Register usage:
#   RSI = base address of array
#   R8  = low index
#   R9  = high index
#   R10 = mid index
#   R11 = array[mid]
#
# Important idea:
#   Because the array is sorted, each comparison eliminates half
#   of the remaining search range.
# ============================================================
binary_search:
    pushq %rbp
    movq %rsp, %rbp

    leaq search_array(%rip), %rsi
    movq $0, %r8
    movq $4, %r9

bs_loop:
    cmpq %r9, %r8
    jg bs_not_found

    movq %r8, %r10
    addq %r9, %r10
    shrq $1, %r10

    movq (%rsi,%r10,8), %r11
    cmpq %r11, %rdi
    je bs_found
    jl bs_go_left

    # key > array[mid], so continue in the right half.
    leaq 1(%r10), %r8
    jmp bs_loop

bs_go_left:
    # key < array[mid], so continue in the left half.
    leaq -1(%r10), %r9
    jmp bs_loop

bs_found:
    movq %r10, %rax
    popq %rbp
    ret

bs_not_found:
    movq $-1, %rax
    popq %rbp
    ret

# ============================================================
# main
# ------------------------------------------------------------
# Purpose:
#   Demonstrates all four required functions.
#   This version also satisfies the bonus requirement by taking
#   user input with scanf.
#
# Local storage in main:
#   -8(%rbp)  = input for prime factorization
#   -16(%rbp) = input for Fibonacci
#   -24(%rbp) = input key for linear search
#   -32(%rbp) = input key for binary search
#   -40(%rbp) = Fibonacci result
#   -48(%rbp) = search result
# ============================================================
main:
    pushq %rbp
    movq %rsp, %rbp
    subq $64, %rsp

    # -----------------------------
    # Prime factorization demo
    # -----------------------------
    leaq prompt_pf(%rip), %rdi
    xorl %eax, %eax
    call printf

    leaq scan_fmt(%rip), %rdi
    leaq -8(%rbp), %rsi
    xorl %eax, %eax
    call scanf

    movq -8(%rbp), %rdi
    call prime_factors

    # -----------------------------
    # Fibonacci demo
    # -----------------------------
    leaq prompt_fib(%rip), %rdi
    xorl %eax, %eax
    call printf

    leaq scan_fmt(%rip), %rdi
    leaq -16(%rbp), %rsi
    xorl %eax, %eax
    call scanf

    cmpq $0, -16(%rbp)
    jge main_fib_compute

    leaq negative_fib_fmt(%rip), %rdi
    xorl %eax, %eax
    call printf
    movq $0, -16(%rbp)

main_fib_compute:
    movq -16(%rbp), %rdi
    call fib
    movq %rax, -40(%rbp)

    leaq fib_result_fmt(%rip), %rdi
    movq -16(%rbp), %rsi
    movq -40(%rbp), %rdx
    xorl %eax, %eax
    call printf

    # -----------------------------
    # Linear search demo
    # -----------------------------
    leaq prompt_linear(%rip), %rdi
    xorl %eax, %eax
    call printf

    leaq scan_fmt(%rip), %rdi
    leaq -24(%rbp), %rsi
    xorl %eax, %eax
    call scanf

    movq -24(%rbp), %rdi
    call linear_search
    movq %rax, -48(%rbp)

    cmpq $-1, -48(%rbp)
    je main_linear_not_found

    leaq found_fmt(%rip), %rdi
    leaq linear_label(%rip), %rsi
    movq -24(%rbp), %rdx
    movq -48(%rbp), %rcx
    xorl %eax, %eax
    call printf
    jmp main_binary_demo

main_linear_not_found:
    leaq not_found_fmt(%rip), %rdi
    leaq linear_label(%rip), %rsi
    movq -24(%rbp), %rdx
    xorl %eax, %eax
    call printf

main_binary_demo:
    # -----------------------------
    # Binary search demo
    # -----------------------------
    leaq prompt_binary(%rip), %rdi
    xorl %eax, %eax
    call printf

    leaq scan_fmt(%rip), %rdi
    leaq -32(%rbp), %rsi
    xorl %eax, %eax
    call scanf

    movq -32(%rbp), %rdi
    call binary_search
    movq %rax, -48(%rbp)

    cmpq $-1, -48(%rbp)
    je main_binary_not_found

    leaq found_fmt(%rip), %rdi
    leaq binary_label(%rip), %rsi
    movq -32(%rbp), %rdx
    movq -48(%rbp), %rcx
    xorl %eax, %eax
    call printf
    jmp main_done

main_binary_not_found:
    leaq not_found_fmt(%rip), %rdi
    leaq binary_label(%rip), %rsi
    movq -32(%rbp), %rdx
    xorl %eax, %eax
    call printf

main_done:
    movq $0, %rax
    leave
    ret

.section .note.GNU-stack,"",@progbits
