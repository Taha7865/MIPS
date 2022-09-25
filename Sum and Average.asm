.include "Syscalls.asm"
.data
askN:	.asciiz	"Enter a number: "
error:	.asciiz "Error: Number entered is not valid, try ReadInput! \n"
summ:	.asciiz "The sum is "
avg:	.asciiz "\nThe average is "
buffer:	.space 	255
sum:	.word 	0


.text
main:
li $t3, 0			# store number of inputs

ReadInput:
li $v0, SysPrintString
la $a0, askN
syscall				# ask the user to enter a number

li $v0, SysReadString
la $a0, buffer			# call the buffer
li $a1, 255			# must load the size of buffer
syscall				# read string from the user


lbu $t0, ($a0)			# first character of the buffer
li $t1, 0			# store the sign into register
li $t2, 0			# accumalator
beq $t0, '\n', printValues	# if first character is new line character, then print the results


bne $t0, '-', conversion	# if first character is minus sign, means the value entered is negative
li $t1, 1			# if negative sign is present, let $t1 be 1 so we can store the negative
addi $a0, $a0, 1		# to to next byte
lbu $t0, ($a0)			# get next byte
j conversion

conversion:
	beq $t0, '\n' , EndConversion	# end conversion if new line character found
	blt $t0, '0', errorFound		# check for invalid input
	bgt $t0, '9', errorFound		# check for invalid input
	j proceed				# jump to proceed branch if no errors are found
errorFound:					# if error is found, print error statement and jump to ReadInput to ask for input ReadInput
	li $v0, SysPrintString
	la $a0, error
	syscall			# print the error
	j ReadInput		# ask for input ReadInput
proceed:			# proceed to convert each number in the string
	sub $t0, $t0, '0'		# covert ascii to number
	mul $t2, $t2, 10		# multiply previous number with 10
	add $t2, $t2, $t0		# add the new number
	addi $a0, $a0, 1		# go to next byte
	lbu $t0, ($a0)			# get next byte
	j conversion			# repeat until newline character does not found
EndConversion:				# Go here when the full number is done converting
	addi $t3, $t3, 1			# increment in number of input numbers
	beqz $t1, notNeg			# Check if $t1 is 0, if it is, we skip negative converstion and go to add the number to sum
	neg $t2, $t2				# if true, then turn the number into negative
notNeg:						
	lw $t4, sum				# get sum from data segment
	add $t4, $t4, $t2			# add new number
	sw $t4, sum				# store sum ReadInput
	j ReadInput					# repeat for next input

printValues:
	li $v0, SysPrintString
	la $a0, summ				# print the message for sum
	syscall
	li $v0, SysPrintInt
	lw $a0, sum
	syscall					# print the sum value

	li $v0, SysPrintString
	la $a0, avg
	syscall					# print the message for average
	lw $a0, sum
	div $a0, $t3
	mflo $a0				# get the average
	li $v0, SysPrintInt
	syscall					# print the average value

li $v0, SysExit
syscall					# Terminate the program



 
