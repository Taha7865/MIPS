#Written by John Cole for CS2340.005, assignment 4, Starting March 14, 2022.
#NetID: txa190016 
#Palindrom checker. This operates by inputting a string and it will go through
#byte by byte to remove anything that is not a number or letter
#Must include a file called "functions.asm" and "Syscalls.asm" before running the program
#Functions.asm has all the functions that this file will use, the output will return whether or not the input is a palindrome
.include "Syscalls.asm"
.data

.eqv	StringSize		200


# data section variables

stringRead:		.space		StringSize
promptString:		.asciiz		"Enter a string: "
palindrome:		.asciiz		"Palindrome\n"
notPalindrome:		.asciiz		"Not a palindrome\n"


.text
main:

# print prompt for string
li $v0, SysPrintString
la $a0, promptString
syscall

# read string from the user
li $v0, SysReadString
la $a0, stringRead
li $a1, StringSize
syscall

# end program if string is empty
la $a0, stringRead
lb $t0, ($a0)
beq $t0, 10, endProgram

# call check palindrome function
jal isPalindrome

# if returns zero, string is not palindrome
beqz $v0, isNotPalindrome

# otherwise, print palindrome
li $v0, SysPrintString
la $a0, palindrome
syscall

# request another string
j main

# print not palindrome
isNotPalindrome:
li $v0, SysPrintString
la $a0, notPalindrome
syscall

# requezt another string
j main

endProgram:

# Terminate the program
li $v0, SysExit
syscall



###################################################
# isPalindrome
# Check if the string is palindrome or not
# Input:
# 	a0 = string offset
# Returns:
#	v0 = palindrome status (1 for yes, 0 for no)
###################################################
isPalindrome:

	# set stack frame to store the variables and registers
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $a0, 4($sp)
	sw $s0, 8($sp)
	sw $s1, 12($sp)
	sw $s2, 16($sp)
	
	# call function to remove extra characters
	jal removePunctuation

	move $s0, $a0				# string offset
	add $s1, $s0, $v0			# string end offset
	addi $s1, $s1, -1			# back from end character
	
	li $v0, 1				# set string is palindrome
palindromeLoop:	

	lbu $s2, ($s0)				# get starting character from string
	beq $s2, 10, endPalindrome		# check if it is the last character of string
	
	lbu $s3, ($s1)				# get character from the last of string
	bne $s2, $s3, notMatch			# check if they match
	
	addi $s0, $s0, 1			# go next to the starting byte of the string
	addi $s1, $s1, -1			# come back from the ending byte of string
	
	j palindromeLoop			# repeat
	
notMatch:
	li $v0, 0				# set string is not palindrome
	
endPalindrome:

	# restore the registers and reset the stack frame
	lw $ra, 0($sp)
	lw $a0, 4($sp)
	lw $s0, 8($sp)
	lw $s1, 12($sp)
	lw $s2, 16($sp)
	addi $sp, $sp, 20
	
	# return
	jr $ra
.include "functions.asm"



