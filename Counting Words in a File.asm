# Compute the word counts for each word reading thorugh a file
# Written by Taha Ahmed for CS2340.005, assignment 3, starting March 2, 2022.
# NetID: txa190016
.eqv MAX_WORD_SIZE 255
.eqv BLOCK_SIZE 16
.eqv MAX_FILE_NAME 100
.eqv LIST_SIZE 300000 # 1000 ( 255 + 5 )  = 300000
.eqv LIST_ELEMENT_SIZE 4000 # 4 x 1000 = 4000
.data

list_ptr: .word 0 
listPtrs: .space LIST_ELEMENT_SIZE
block: .space BLOCK_SIZE
word_data: .space MAX_WORD_SIZE
file: .space MAX_FILE_NAME
enter_msg: .asciiz "Enter file name: "
list_not_sort: .asciiz "List before sort :\n\n"
list_sort: .asciiz "\nList after sort :\n"
open_error_msg: .asciiz "we can't open file to read may not exist.\n"
read_error_msg: .asciiz "error for reading.\n"
.text
.globl main
main:
	li $v0,4
	la $a0,enter_msg
	syscall
	
	# read file name from user
	li $v0,8
	la $a0,file
	li $a1,MAX_FILE_NAME
	syscall
	
	# remove '\n' from file 
	la $a0,file
	jal remove_new_line
	
	# open file for read
	li $v0,13
	la $a0,file
	li $a1,0
	li $a2,0
	syscall
	blt $v0,$zero,main_open_error
	move $s0,$v0 # save file descriptor in $s0 
	
	# create allocate space for a list of these words
	li $v0,9
	li $a0,LIST_SIZE
	syscall
	sw $v0,list_ptr
	
	li $s2,-1 # if -1 no cross if 2 there are cross 
	lw $s4,list_ptr # cuurent liet etim
	la $s5,word_data # $s5 = word_data
	la $s6,listPtrs
	li $s7,0
main_loop: 
	move $a0,$s0
	la $a1,block
	li $a2,BLOCK_SIZE
	jal readLine
	blt $v0,$zero,main_read_error
	beq $v0,$zero,main_loop_checkS2
	# convert to lowercase
	la $a0,block
	li $a1,BLOCK_SIZE
	jal toLowercase
	move $s1,$v0 # $s1 = numbers of chars readed 
	la $s3,block # $s3 = block
main_loop_word:	
	bne $s2,2,main_loop_wordU2
	# here word cross block :)
	lbu $a0,block
	jal isLetter
	beq $v0,$zero,main_loop_word_checkS2U
main_loop_wordU2:
	move $a0,$s5
	move $a1,$s3 
	move $a2,$s1
	jal fillWord
	beq $v0,$zero,main_loop_word_checkS2 # no next word 
	beq $v0,1,main_loop # no next char
	bne $v0,2,main_loop_update
	# here  word cross a block boundary
	move $s2,$v0 # save $v0 in $s2
	move $a0,$s5
	jal strlen
	addu $s5,$s5,$v0
	j main_loop
main_loop_word_checkS2:
	bne $s2,2,main_loop
main_loop_word_checkS2U:
	li $s2,-3 # this mean now not cross 
	la $s5,word_data 
	j main_loop_append
main_loop_update:
	la $s5,word_data 
	move $s3,$v0
	sub $s1,$s1,$v1 # update $s1
	j main_loop_append
main_loop_checkS2:
	bne $s2,2,main_loop_done
	li $s2,-2 # for exit
main_loop_append:	
	lw $a0,list_ptr
	la $a1,word_data
	jal findWord
	beq $v0,$zero,main_loop_new_word
	# here we just need to increament count
	ulw $t0,($v0)
	addi $t0,$t0,1
	usw $t0,($v0)
	j main_loop_wordS2
main_loop_new_word:
	la $a0,word_data
	jal strlen
	beq $v0,$zero,main_loop
	sb $v0,4($s4) # save length 
	li $t0,1
	usw $t0,($s4)
	addiu $a0,$s4,5
	la $a1,word_data
	move $a2,$v0
	jal strncpy 
	sw $s4,0($s6) 
	addiu $s6,$s6,4
	addi $s7,$s7,1
	# update s4
	move $a0,$s4
	jal nextWord
	move $s4,$v0
main_loop_wordS2:
	bne $s2,-2,main_loop_word
main_loop_done:	
	# before sort
	li $v0,4
	la $a0,list_not_sort
	syscall
	# print list 
	lw $a0,list_ptr # cuurent liet etim
	jal printList
	# sort list 
	la $a0,listPtrs
	move $a1,$s7 # n
	jal sort
	# after sort 
	li $v0,4
	la $a0,list_sort
	syscall
	# print list 
	la $a0,listPtrs
	jal printListP
main_exit:
	# exit
	li $v0,10
	syscall
main_open_error:
	li $v0,4
	la $a0,open_error_msg
	syscall
	j main_exit
main_read_error:
	li $v0,4
	la $a0,read_error_msg
	syscall
	# close file
	li $v0,16
	move $a0,$s0 # $s0 = file descriptor 
	j main_exit

	###############################
	# we sort array pointer of list elements here :)
	# $a0 = address of block
	# $a1 = size of block
	# return
	# none
	
	# we implement bubble sort algorithm 
	# for(i=0;i<n-1;i++)
	#   for(j=0;j<n-i-1;j++)
	#     if(arr[j]<arr[j+1])
	#	swap(arr[j],arr[j+1])
sort:
	# we use $t2 as i
	li $t2,0 # i = 0
sort_outer_loop:
	addi $t0,$a1,-1 # $t0 = n-1
	bge $t2,$t0,sort_outer_loop_done
	# here i<n-1
	# we use $t3 as j
	li $t3,0 # j = 0
sort_inner_loop:
	addi $t0,$a1,-1 # $t0 = n-1
	sub $t0,$t0,$t2
	bge $t3,$t0,sort_outer_loop_update
	# here j<n-i-1
	sll $t1,$t3,2 # $t1 = j*4
	addu $t1,$t1,$a0 # $t1 = &arr[j]
	lw $t4,0($t1) # $t4 = arr[j]
	lw $t5,4($t1) # $t5 = arr[j+1]
	ulw $t6,0($t4) # $t6 = arr[j].count
	ulw $t7,0($t5) # $t7 = arr[j+1].count
	bge $t6,$t7,sort_inner_loop_update
	# here arr[j]<arr[j+1]
	# swap(arr[j],arr[j+1])
	sw $t4,4($t1)
	sw $t5,0($t1)
sort_inner_loop_update:
	addi $t3,$t3,1 # j++
	j sort_inner_loop
sort_outer_loop_update:
	addi $t2,$t2,1 # i++
	j sort_outer_loop
sort_outer_loop_done:
	jr $ra
	###############################
	# convert to lowercase 
	# $a0 = address of block
	# $a1 = size of block
	# return
	# none
toLowercase:
	ble $a1,$zero,toLowercase_done 
	lbu $t0,0($a0)
	blt $t0,'A',toLowercase_update
	bgt $t0,'Z',toLowercase_update
	ori $t0,$t0,0x20 # convet to lower case
	sb $t0,0($a0)
toLowercase_update:
	addiu $a0,$a0,1
	addi $a1,$a1,-1
	j toLowercase
toLowercase_done:
	jr $ra	
	###############################
	# remove the first '\0' 
	# $a0 = char
	# return
	# $v0 = 1 ( 0-9 A-Z a-z ) $v0 = 0 other letter
isLetter:
	blt $a0,'0',isLetterReturn0
	ble $a0,'9',isLetterReturn1
	blt $a0,'A',isLetterReturn0
	ble $a0,'Z',isLetterReturn1
	blt $a0,'a',isLetterReturn0
	bgt $a0,'z',isLetterReturn0
isLetterReturn1:
	li $v0,1
	jr $ra
isLetterReturn0:
	li $v0,0
	jr $ra
	###############################
	# remove the first '\0' 
	# $a0 = string address
	# return
	# none
remove_new_line:
	lbu $t0,0($a0)
	beq $t0,$zero,remove_new_line_done
	beq $t0,'\n',remove_new_lineR
	addiu $a0,$a0,1
	j remove_new_line
remove_new_lineR:
	sb $zero,0($a0)
remove_new_line_done:
	jr $ra
	
	###############################
	# fill word 
	# $a0 = word address
	# $a1 = block address
	# $a2 = size
	# return 
	# $v0 = address of separator (if exist)  0 if no word 1 if no next char  $v0 = 2  word cross a block boundary
	# $v1 = number of chars that we skip
	
fillWord:
	addiu $sp,$sp,-24
	sw $ra,0($sp)
	sw $s0,4($sp)
	sw $s1,8($sp)
	sw $s2,12($sp)
	sw $s3,16($sp)
	sw $s4,20($sp)
	
	move $s0,$a0 # $s0 = word address
	move $s1,$a1 # $s1 = string address
	move $s2,$a2 # $s2 = size
	# we use $s3 for count number of char that we skip
	
	sb $zero,0($s0) # word[0] = '\0';
	
	# first we need to go to the word 
	move $a0,$s1
	move $a1,$s2
	jal goNextWord
	beq $v0,$zero,fillWord_done
	beq $v0,1,fillWord_done
	move $s1,$v0 # update $s1 
	sub $s2,$s2,$v1 # update $s2
	move $s3,$v1
	
	# second we go to next sperator 
	move $a0,$s1
	move $a1,$s2
	jal goNextSeparator
	beq $v0,1,fillWord_done
	bne $v0,$zero,fillWord_notCross
	# $v0 = 0 this mean word cross a block boundary
	move $a0,$s0
	move $a1,$s1
	move $a2,$v1
	jal strncpy 
	li $v0,2
	j fillWord_updateV1 
fillWord_notCross:
	move $s4,$v0 # save $v0 in $s4
	move $a0,$s0
	move $a1,$s1
	move $a2,$v1
	jal strncpy 
	move $v0,$s4
fillWord_updateV1:
	add $v1,$v1,$s3
fillWord_done:
	lw $ra,0($sp)
	lw $s0,4($sp)
	lw $s1,8($sp)
	lw $s2,12($sp)
	lw $s3,16($sp)
	lw $s4,20($sp)
	addiu $sp,$sp,24
	jr $ra

	###############################
	# skip word that letters or digits 
	# $a0 = string address
	# $a1 = size
	# return 
	# $v0 = address of separator (if exist)  0 if no separator 1 if no next char 
	# $v1 = number of chars that we skip
goNextSeparator:
	addiu $sp,$sp,-8
	sw $ra,0($sp)
	sw $s0,4($sp)
	move $s0,$a0 # save $a0 in $s0
	li $v1,0
	ble $a1,$zero,goNextSeparator_return1
goNextSeparator_loop:
	beq $a1,$zero,goNextSeparator_return0
	lbu $a0,0($s0)
	jal isLetter
	beq $v0,$zero,goNextSeparator_loop_done
	addiu $s0,$s0,1
	addi $v1,$v1,1
	addi $a1,$a1,-1
	j goNextSeparator_loop
goNextSeparator_loop_done:
	move $v0,$s0
goNextSeparator_done:
	lw $ra,0($sp)
	lw $s0,4($sp)
	addiu $sp,$sp,8
	jr $ra
goNextSeparator_return0:
	li $v0,0
	j goNextSeparator_done
goNextSeparator_return1:
	li $v0,1
	j goNextSeparator_done	
	
	###############################
	# skip chars that no letter or digits 
	# $a0 = string address
	# $a1 = size
	# return 
	# $v0 = address of word (if exist)  0 if no word 1 if no next char 
	# $v1 = number of chars that we skip
goNextWord:
	addiu $sp,$sp,-8
	sw $ra,0($sp)
	sw $s0,4($sp)
	move $s0,$a0 # save $a0 in $s0
	li $v1,0
	ble $a1,$zero,goNextWord_return1
goNextWord_loop:
	beq $a1,$zero,goNextWord_return0
	lbu $a0,0($s0)
	jal isLetter
	bne $v0,$zero,goNextWord_loop_done
	addiu $s0,$s0,1
	addi $v1,$v1,1
	addi $a1,$a1,-1
	j goNextWord_loop
goNextWord_loop_done:
	move $v0,$s0
goNextWord_done:
	lw $ra,0($sp)
	lw $s0,4($sp)
	addiu $sp,$sp,8
	jr $ra
goNextWord_return0:
	li $v0,0
	j goNextWord_done
goNextWord_return1:
	li $v0,1
	j goNextWord_done
	
	###############################
	# find word in word list
	# $a0 = address of first word in list
	# $a1 = address of word that we need to find
	# return 
	# $v0 = address of word in list ( if not found return 0 )
findWord:	
	addiu $sp,$sp,-16
	sw $ra,0($sp)
	sw $s0,4($sp)
	sw $s1,8($sp)
	sw $s2,12($sp)
	
	move $s0,$a0 # $s0 = ddress of first word in list
	move $s1,$a1 # $s1 = address of word that we need to find
	
findWord_loop:
	ulw $t0,0($s0)
	beq $t0,$zero,findWord_return0 # not found :( 
	addiu $a0,$s0,5
	move $a1,$s1
	lbu $a2,4($s0) 
	jal strncmp
	beq $v0,$zero,findWord_found
	# update loop
	move $a0,$s0
	jal nextWord
	move $s0,$v0
	j findWord_loop
findWord_found:
	move $v0,$s0
findWord_done:
	lw $ra,0($sp)
	lw $s0,4($sp)
	lw $s1,8($sp)
	lw $s2,12($sp)
	addiu $sp,$sp,16
	jr $ra
findWord_return0:
	li $v0,0
	j findWord_done
	
	###############################
	# compare str1 with str2 we compare just first num chars 
	# $a0 = str1
	# $a1 = str2
	# $a2 = num
	# return 
	# $v0 = 0 equals other value mean str1 different to str2
strncmp:
	addiu $sp,$sp,-16
	sw $ra,0($sp)
	sw $s0,4($sp)
	sw $s1,8($sp)
	sw $s2,12($sp)
	
	move $s0,$a0 # $s0 = str1
	move $s1,$a1 # $s1 = str2
	move $s2,$a2 # $s2 = num
	
strncmp_loop:
	ble $a2,$zero,strncmp_update
	lbu $t0,0($a0) 
	lbu $t1,0($a1)
	sub $v0,$t1,$t0 
	bne $v0,$zero,strncmp_done
	beq $t0,$zero,strncmp_update
	beq $t1,$zero,strncmp_update
	addiu $a0,$a0,1
	addiu $a1,$a1,1
	addi $a2,$a2,-1
	j strncmp_loop
strncmp_update:
	bne $v0,$zero,strncmp_done
	move $a0,$s1
	jal strlen
	beq $v0,$s2,strncmp_done_return0
	li $v0,1 # return 1
strncmp_done:
	lw $ra,0($sp)
	lw $s0,4($sp)
	lw $s1,8($sp)
	lw $s2,12($sp)
	addiu $sp,$sp,16
	jr $ra
strncmp_done_return0:
	li $v0,0
	j strncmp_done
	###############################
	# read line from file ( we read char until we find '\n' or '\0'
	# $a0 = file descriptor
	# $a1 = block address 
	# $a2 = block size
	# return 
	# $v0 = numbers of chars readed (0 if end of file negative if error )
readLine:
	addiu $sp,$sp,-20
	sw $ra,0($sp)
	sw $s0,4($sp)
	sw $s1,8($sp)
	sw $s2,12($sp)
	sw $s3,16($sp)
	
	move $s0,$a0 # $s0 = file descriptor
	move $s1,$a1 # $s1 = block address 
	move $s2,$a2 # $s2 = block size
	
	# we use $s3 for calculate numbers of chars readed
	li $s3,0 
readLine_loop:
	ble $s2,$zero,readLine_loop_done
	li $v0,14
	move $a0,$s0
	move $a1,$s1
	li $a2,1 # we need to read just one char
	syscall
	blt $v0,$zero,readLine_done # error when we read
	beq $v0,$zero,readLine_loop_done # end of file 
	# we check for '\n' and '\0'
	lbu $t0,0($s1)
	beq $t0,'\n',readLine_loop_done1
	beq $t0,$zero,readLine_loop_done 
	addiu $s1,$s1,1
	addi $s3,$s3,1
	addi $s2,$s2,-1
	j readLine_loop
readLine_loop_done1:
	sb $zero,0($s1)
	addi $s3,$s3,1
readLine_loop_done:
	move $v0,$s3 
readLine_done:
	lw $ra,0($sp)
	lw $s0,4($sp)
	lw $s1,8($sp)
	lw $s2,12($sp)
	lw $s3,16($sp)
	addiu $sp,$sp,20
	jr $ra
	
	
	###############################
	# get length of string 
	# $a0 = address of string 
	# return 
	# $v0 = length of string 
strlen:
	li $v0,0
strlen_loop:
	lbu $t0,0($a0)
	beq $t0,$zero,strlen_done
	addiu $a0,$a0,1
	addi $v0,$v0,1
	j strlen_loop
strlen_done:
	jr $ra
	
	###############################
	# get next word  
	# $a0 = address word ( first word byte count 5th byte word length next string )
	# return 
	# $v0 = next word
nextWord:
	lbu $v0,4($a0) 
	addi $v0,$v0,5
	addu $v0,$v0,$a0
	jr $ra

	

	###############################
	# print list of words to output 
	# $a0 = address array pointers of list elements
	# return 
	# none
printListP:
	addiu $sp,$sp,-8
	sw $ra,0($sp)
	sw $s0,4($sp)
	move $s0,$a0 # save $a0 in $s0
	
printListP_loop:
	lw $a0,0($s0)
	beq $a0,$zero,printListP_done
	jal printWord
	addiu $s0,$s0,4
	j printListP_loop
printListP_done:
	lw $ra,0($sp)
	lw $s0,4($sp)
	addiu $sp,$sp,8
	jr $ra
	
	
		
	###############################
	# print list of words to output 
	# $a0 = address first element in string 
	# return 
	# none
printList:
	addiu $sp,$sp,-8
	sw $ra,0($sp)
	sw $s0,4($sp)
	move $s0,$a0 # save $a0 in $s0
	
printList_loop:
	ulw $t0,0($s0)
	beq $t0,$zero,printList_done
	move $a0,$s0
	jal printWord
	move $a0,$s0
	jal nextWord
	move $s0,$v0
	j printList_loop
printList_done:
	lw $ra,0($sp)
	lw $s0,4($sp)
	addiu $sp,$sp,8
	jr $ra
	
	###############################
	# print word to output 
	# $a0 = address word ( first word byte count 5th byte word length next string )
	# return 
	# none
.data
printWord_msg1: .asciiz " : "

.text
printWord:
	addiu $sp,$sp,-8
	sw $ra,0($sp)
	sw $s0,4($sp)
	
	move $s0,$a0 # save $a0 in $s0
	
	# print word here
	la $a0,word_data
	addiu $a1,$s0,5
	lbu $a2,4($s0) 
	jal strncpy
	
	# print word 
	li $v0,4
	la $a0,word_data
	syscall
	
	# print " : "
	li $v0,4
	la $a0,printWord_msg1
	syscall
	
	# print count 
	li $v0,1
	ulw $a0,0($s0)
	syscall
	
	# print new line 
	li $v0,11
	li $a0,'\n'
	syscall
	
	lw $ra,0($sp)
	lw $s0,4($sp)
	addiu $sp,$sp,8
	jr $ra

	
	###############################
	# copy Copies the first num characters of source to destination
	# $a0 = address of destination
	# $a1 = address of source
	# $a2 = num
	# return 
	# none 	
strncpy:
	ble $a2,$zero,strncpy_loop_done
	lbu $t0,0($a1)
	sb $t0,0($a0)
	beq $t0,$zero,strncpy_done
	addiu $a0,$a0,1
	addiu $a1,$a1,1
	addi $a2,$a2,-1
	j strncpy
strncpy_loop_done:
	sb $zero,($a0)
strncpy_done:
	jr $ra
