#################################################################################
#	Name:		Aaron Cohen						#
#												#
#	File:		cosine.s						#
#												#
#	README:		Was having trouble closing the program and an infinite		#
#			loop occuring, but fixed this by moving where my stack			#
#			call was and moved the stack pointer properly.					#
#################################################################################
	.data
welcome:
	.asciiz "Please enter a floating point number: "
error:
	.asciiz "Invalid number, re-enter\n"
result:
	.asciiz "\nThe cosine of "
equalto:
	.asciiz " = "
	.text
	.globl main

main:
	addiu $sp, $sp, -4
			#Storing the return address before link to next function
	sw $ra, 0($sp)
			#Jump and link to the input function
	jal input
	lw $ra, 0($sp)
			#$f12 is the parmater floating point register
	mov.s $f12, $f20
			#Jump and link to the cosine function then upon returning I load the return address
	jal cosine
	lw $ra, 0($sp)
	mov.s $f21, $f0
			#Printing the result string 
	li $v0, 4
	la $a0, result
	syscall
			#Printing the float that the user entered in the input function
	li $v0, 2
	mov.s $f12, $f20
	syscall
			#Printing an equal sign
	li $v0, 4
	la $a0, equalto
	syscall
			#Printing the final cosine value
	li $v0, 2
	mov.s $f12, $f21
	syscall
			#return
	jr $ra
	
input:
			#Printing the welcome statement prompting the user for input
	li $v0, 4
	la $a0, welcome
	syscall
			#Reading the user input and placing it in the floating point save register $f20
	li $v0, 6
	syscall
			#Loading immediates to error check the user input 
	li.s $f4, 6.28318531
	li.s $f5, 0.0

_loop1:
			#Loop that checks if the input is between 0 and 6.283; if not it goes to an error statement
	c.lt.s $f0, $f4
	bc1f _error1
	c.lt.s $f0, $f5
	bc1t _error1
	mov.s $f20, $f0
	jr $ra

_error1:
			#Printing an error message
	li $v0, 4
	la $a0, error
	syscall
			#Printing the welcome message again
	li $v0, 4
	la $a0, welcome
	syscall
			#Reading in user input
	li $v0, 6
	syscall
			#A jump back to the error checking loop
	j _loop1

cosine:
			#Moving down the stack for the cosine function
	addiu $sp, $sp, -28
			#$f21 is used for the calculations until the final result; $f23 is used for the exponent and factorial
	li.s $f21, 1.0
	li.s $f23, 2.0
			#Counter registers 
	li.s $f24, 2.0
	li $s0, 1
	li $s1, 2
	li $s4, 2

_calc:
			#Storing each of the registers onto the stack (including the return address
	swc1 $f20, 24($sp)
	swc1 $f21, 20($sp)
	swc1 $f22, 16($sp)
	swc1 $f23, 12($sp)
	sw $s0, 8($sp)
	sw $s4, 4($sp)
	sw $ra, 0($sp)
			#Putting user input and exponent into the designated $f12 and $f13 paramter registers for the power function
	mov.s $f12, $f20
	mov.s $f13, $f23
			#Call to the power function
	jal power
			#Upon returning load the return address and counter variable
	lw $ra, 0($sp)
	lw $s4, 4($sp)
	mov.s $f22, $f0
			#Storing $f22 which has the return value of the power function
	swc1 $f22, 16($sp)
			#Parameter register for the factorial function
	mov.s $f12, $f23
			#Jump and link
	jal factorial
			#Setting $f25 equal to the returned factorial value
	mov.s $f25, $f0
	abs.s $f25, $f25
			#Reloading $f24 to add to the exponent/factorial
	li.s $f24, 2.0
			#Loading all my saved registers from the stack
	lwc1 $f20, 24($sp)
	lwc1 $f21, 20($sp)
	lwc1 $f22, 16($sp)
	lwc1 $f23, 12($sp)
	lw $s0, 8($sp)
	lw $s4, 4($sp) 
	lw $ra, 0($sp)
			#Calculations
	li $s1, 2
			#Dividing the return value of power by the return value of factorial
	div.s $f22, $f22, $f25
			#Divide my counter to check if I should add or subtract 
	divu $s0, $s1
	mfhi $s2
	addi $s0, 1
			#Incrementing exponent/factorial by 2.0
	add.s $f23, $f23, $f24
	addi $s4, 2
			#Checking to jump to addition or subtraction
	beq $s2, $zero, _add1
	beq $s2, 1, _sub1
	
_add1:
			#Adding 
	add.s $f21, $f21, $f22
			#Checking to see if the counter has reached the correct amount of iterations
	beq $s0, 11, _return
			#if not jump to calc
	j _calc
	
_sub1:
			#Subtracting
	sub.s $f21, $f21, $f22
			#Return check
	beq $s0, 11, _return
			#else jump to calc
	j _calc
	
_return:
			#Moving the final value into the $f0 return register and returning to main
	mov.s $f0, $f21
			#Stack return
	addiu $sp, $sp, 28
	jr $ra
	
	
power:
			#Initializing $f6 as my counter
	li.s $f6, 1.0 
	li.s $f7, 1.0
			#setting $f0 as my final return value
	mov.s $f0, $f12
	mov.s $f25, $f12

_loop2:
			#Looping and multiplying until the counter reaches the paramter that was passed
	mul.s $f0, $f0, $f25
	add.s $f6, $f6, $f7
	c.eq.s $f6, $f13
	bc1f _loop2
			#Return to cosine
	jr $ra

factorial:
			#Modified factorial function from notes to work with floats
			#Integer register $a0 would overflow past 14
	li.s $f4, 1.0
	c.lt.s $f12, $f4
	li.s $f0, 1.0
	bc1f _L2
	jr $ra

_L2:
			#Moving in the stack
	addiu $sp, $sp, -8
			#Storing the return address and new factorial value to multiply by
	sw $ra, 4($sp)
	swc1 $f5, 0($sp)
	mov.s $f5, $f12
	sub.s $f12, $f12, $f4
	jal factorial
			#Multiplying and storing in my return value $f0 then loading the return address
	mul.s $f0, $f0, $f5
	lwc1 $f5, 0($sp)
	lw $ra, 4($sp)
	addiu $sp, $sp, 8
			#Return to previous factorial function then to the cosine function
	jr $ra
