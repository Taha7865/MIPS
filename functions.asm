#Written by John Cole for CS2340.005, assignment 4, Starting March 14, 2022.
#NetID: txa190016 
#Functions used in the palindrome file


######################################################
# removePunctuation
# removes anything that isn’t a letter or a number.
# input:
#	a0 : string offset
# returns:
# 	v0 : new string length
######################################################
#Removes something that is not a number or a letter in the word
removePunctuation:
	
	# set stack frame to store registers 
	addi $sp, $sp, -24
	sw $ra, 0($sp)
	sw $a0, 4($sp)
	sw $s0, 8($sp)
	sw $s1, 12($sp)
	sw $s2, 16($sp)
	
	move $s0, $a0			# previous pointer
	move $s1, $a0			# next pointer
	li $v0, 0			# number of new characters saved
#looping through the word byte by byte to remove non numbers and letters
removeLoop:
	lbu $s2, ($s1)			# get byte and check if its end of string
	beq $s2, 10, removingDone
	
	# if not end of string then check if it is letter or character
	blt $s2, '0', skipChar
	ble $s2, '9', storeChar
	blt $s2, 'A', skipChar
	ble $s2, 'Z', storeChar
	blt $s2, 'a', skipChar
	bgt $s2, 'z', skipChar
	
# if yes, then store the characater into the word
storeChar:
	sb $s2, ($s0)
	addi $s0, $s0, 1
	addi $v0, $v0, 1
	
# else skip that character and move to next byte
skipChar:
	addi $s1, $s1, 1
	j removeLoop

#When we are at the end of the word, successfully removing all non numbers and letters
removingDone:

	# set end of string
	li $s2, 10				# new line character
	sb $s2, ($s0)
	
	# set end line character
	li $s2, 0
	addi $s0, $s0, 1
	sb $s2, ($s0)
	
	sw $v0, 20($sp)			# store length of string on stack
	
	# call function to convert string to uppercase
	jal toUpper


	# restore registers values from stack and reset stack frame
	lw $ra, 0($sp)
	lw $a0, 4($sp)
	lw $s0, 8($sp)
	lw $s1, 12($sp)
	lw $s2, 16($sp)
	lw $v0, 20($sp)
	addi $sp, $sp, 24
	
	# return
	jr $ra
	
	
###################################################
# toUpper
# convert string to all uppercase letters
# input:
#	a0 : string offset
# returns: nothing
###################################################
toUpper:
	
	# set stack frame to store registers to be used
	addi $sp, $sp, -20
	sw $ra, 0($sp)
	sw $a0, 4($sp)
	sw $s0, 8($sp)
	sw $s1, 12($sp)
	sw $s2, 16($sp)
	
	move $s0, $a0		# string offset
	
	# set mask to convert from lowercae to uppercase
	li $s2, 32			
	not $s2 $s2		#using binary to set 1s and 0s to change to uppercase
	
convertCase:
	lbu $s1, ($s0)				# load byte from string
	beq $s1, 10, convertDone		# check if it is the end of string
	
	# if not end of string, convert to uppercase and load back in string
	and $s1, $s1, $s2
	sb	$s1, ($s0)
	
	addi $s0, $s0, 1			# next byte
	j  convertCase				# repeat
	
convertDone:

	# restore registers values from stack and reset stack frame
	lw $ra, 0($sp)
	lw $a0, 4($sp)
	lw $s0, 8($sp)
	lw $s1, 12($sp)
	lw $s2, 16($sp)
	addi $sp, $sp, 20
	
	# return
	jr $ra
