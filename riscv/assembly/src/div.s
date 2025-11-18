.macro DEBUG_PRINT reg
csrw 0x800, \reg          # Write the register value to control/status register 0x800
.endm
	
.text
.global div                 # Export the symbol 'div' so we can call it from other files
.type div, @function        # Declare 'div' as a function

div:
    # Prologue: Set up stack frame
    addi sp, sp, -32        # Allocate 32 bytes (8 words) on the stack
    
    # Save callee-saved registers that we will use
    sw   ra, 28(sp)         # Save return address to stack (offset 28 bytes)
    sw   s0, 24(sp)         # Save s0 register to stack (offset 24 bytes)
    sw   s1, 20(sp)         # Save s1 register to stack (offset 20 bytes)
    sw   s2, 16(sp)         # Save s2 register to stack (offset 16 bytes)
    sw   s3, 12(sp)         # Save s3 register to stack (offset 12 bytes)
    sw   s4, 8(sp)          # Save s4 register to stack (offset 8 bytes)

    # Debug: Print input parameters
    DEBUG_PRINT a0          # Print numerator (first function argument)
    DEBUG_PRINT a1          # Print denominator (second function argument)

    # Check for division by zero
    beq a1, zero, div_by_zero  # If denominator (a1) is zero, jump to error handler
    
    # Save input parameters to callee-saved registers
    mv s0, a0               # s0 = numerator (N) - save original numerator
    mv s1, a1               # s1 = denominator (D) - save original denominator
    
    # Initialize algorithm variables
    li s2, 0                # s2 = quotient (Q) - initialize quotient to 0
    li s3, 0                # s3 = remainder (R) - initialize remainder to 0
    li s4, 31               # s4 = counter (i) - start from bit 31 (MSB) for 32-bit integers
    
div_loop:
    # Check if we've processed all bits (from 31 down to 0)
    blt s4, zero, div_done  # If counter (s4) < 0, we're done, jump to div_done
    
    # R := R << 1 (left-shift remainder by 1 bit)
    slli s3, s3, 1          # Shift remainder left by 1 bit (multiply by 2)
    
    # Extract bit i from numerator (s0)
    srl t0, s0, s4          # Shift numerator right by counter bits to bring bit i to LSB
    andi t0, t0, 1          # Mask with 1 to extract only the least significant bit
    
    # R(0) := N(i) - set LSB of remainder to bit i of numerator
    li t1, 0xFFFFFFFE       # t1 = mask to clear LSB (all 1's except LSB=0)
    and s3, s3, t1          # Clear the least significant bit of remainder
    or s3, s3, t0           # Set the LSB of remainder to the extracted numerator bit
 
    # Check if R >= D (if remainder >= denominator)
    blt s3, s1, no_subtract # If remainder < denominator, skip subtraction
    
    # If R >= D, then subtract denominator from remainder
    sub s3, s3, s1          # R := R - D (subtract denominator from remainder)
    
    # Set Q(i) := 1 (set bit i in quotient)
    li t0, 1                # Load immediate value 1 into temporary register
    sll t0, t0, s4          # Shift left by counter to create mask for bit position i
    or s2, s2, t0           # Set bit i in quotient using OR operation

no_subtract:
    # Decrement loop counter and continue
    addi s4, s4, -1         # i = i - 1 (move to next lower bit position)
    j div_loop              # Jump back to start of loop
    
div_done:
    # Move final results to return registers
    mv a0, s2               # a0 = quotient (return value)
    mv a1, s3               # a1 = remainder (return value)
    j div_exit              # Jump to function exit (skip error handler)
    
div_by_zero:
    # Handle division by zero case
    mv a0, zero             # a0 = 0 (return 0 for quotient)
    mv a1, zero             # a1 = 0 (return 0 for remainder)
    
div_exit:
    # Debug: Print output results
    DEBUG_PRINT a0          # Print quotient result
    DEBUG_PRINT a1          # Print remainder result

    # load every register
    lw   ra, 28(sp)         # Restore return address from stack
    lw   s0, 24(sp)         # Restore s0 register from stack
    lw   s1, 20(sp)         # Restore s1 register from stack
    lw   s2, 16(sp)         # Restore s2 register from stack
    lw   s3, 12(sp)         # Restore s3 register from stack
    lw   s4, 8(sp)          # Restore s4 register from stack
    addi sp, sp, 32         # Deallocate stack space (restore stack pointer)
    ret                     # Return to caller (jump to address in ra)
