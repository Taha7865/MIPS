# Compute total sum of entered integers and print the sum and number of integers 
# Written by Taha Ahmed for CS2340.005, assignment 1, starting January 31, 2022.
# NetID: txa190016
.include "Syscalls.asm" 	# Include Syscalls file for syscall functions

.data
EnterNum: .asciiz 	"Enter a number: "
PrintSum: .asciiz 	"The sum is: "
PrintCount: .asciiz 	"\nThe number of intergers entered was: "
TotalSum: .word 0 	# Variable for the sum
Counter: .word 0 	# Variable in order to count number of integers
.globl main	

.text
main:

lw $t3, TotalSum 	# store totalSum in directive in order to add sum
lw $t4, Counter 	# counter = 0, will increment everytime an integer that was not 0 was entered


loop: 			# loop for computing sum
li $v0, SysPrintString 	# getting syscall ready to print string
la $a0, EnterNum 	# prints "Enter a number: "
syscall

li, $v0, SysReadInt 	# read integer input 
syscall

move $t0, $v0 		# move integer to $t0 for calculations
beq $t0, 0, done 	# if $t0 is equal to 0, go to done
add $t3, $t0, $t3 	# adding sum + integer and set it equal to the sum
add $t4, $t4, 1 	# adding one to the counter when proper integer was entered
bgtz $t0, loop  	# if integer is greater than 0, then loop back


done:  			# begin done funciton when user entered 0
li $v0, SysPrintString  # getting syscall ready to print string
la $a0, PrintSum 	# print total sum
syscall

li, $v0, SysPrintInt 	# getting syscall ready to print an int
move $a0, $t3 		# moving sum to $a0 in order to print
syscall

li $v0, SysPrintString 	# getting syscall ready to print string
la $a0, PrintCount
syscall

li $v0, SysPrintInt 	# getting syscall ready to print total integers
move $a0, $t4 		# moving counter to $a0 in order to print
syscall



 
 
 
