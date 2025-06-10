
.data
input: .word 7

.text
.global main

# This is 1132 CA Homework 1
# Implement fact(x) = 4*F(floor(n-1)/2) + 8n + 3 , where F(0)=4
# Input: n in a0(x10)
# Output: fact(n) in a0(x10)
# DO NOT MOTIFY "main" function

main:        
	# Load input into a0
	lw a0, input
	
	# Jump to fact   
	jal fact       

    # You should use ret or jalr x1 to jump back here after function complete
	# Exit program
    # System id for exit is 10 in Ripes, 93 in GEM5 !
    li a7, 10
    ecall

fact:
    # TODO #