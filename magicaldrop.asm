################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Magical Drop.
#
# Student 1: Name, Student Number
# Student 2: Name, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       TODO
# - Unit height in pixels:      TODO
# - Display width in pixels:    TODO
# - Display height in pixels:   TODO
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000
    
COLORS:
    # load red, green, blue, yellow in an array
    .word 0xff0000, 0x00ff00, 0x0000ff, 0xffff00
    
##############################################################################
# Mutable Data
##############################################################################
BOARD:
    .word 0:98  # An array of 98 bytes/integers to store the 7x14 board (initialized to 0/empty)
    
CHARA:
    .word 6 # The character/player's x position index
    
HELD:
    .word 0 0x000000 # The bubbles that the player holds: their number and color=

##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    	# Draw the box rows
	li $t0, 0x808080  # set $t0 as the color grey for the map
	li $t1, 2 # set index for row
	li $t2, 5 # set column for the row
	lw $t3, ADDR_DSPL # load display address
	jal row   # Fill up top row
	li $t1, 2  # set index for row
	li $t2, 20 # set column for row
	jal row   # fill up bottom row
	
	# Draw the box columns
	li $t1, 2 # set row for col
	li $t2, 5 # set index for the col
	jal column  # draw left column
	li $t1, 10 # set row for col
	li $t2, 5 # set index for the col
	jal column  # draw right column
	
	la $t0, BOARD  # Load the board array
	li $v0, 42  # Load random generation function
	li $a1, 3   # Load arg for random generation (4 colors)
	li $t2, 6   # set column index
	# Draw 6 random rows
	jal random_rows
	jal draw_chara
	
	# After finishing setup, go to gameloop
	j game_loop
	

func_return:
	jr $ra           # Returns a function
	

# Fill 6 rows with random bubbles	
random_rows:
	bgt $t2, 9, func_return # Return if all rows are done
	# otherwise store $ra in a temp var & call random_row
	move $t8, $ra
	li $t1, 3   # set row index for random_row
	jal random_row
	move $ra, $t8 # move $ra back if at last loop
	add $t2, $t2, 1  # increment column index
	j random_rows
	
# Fill a row with random bubbles
random_row:
	bgt $t1, 9, func_return   # Return if row is done (at index > 10)
	# Compute the pixel to color in $t4
	mul $t4, $t2, 128   # column coord in $t4
	mul $t5, $t1, 4     # row coord in $t5
	add $t4, $t4, $t5   # add current row coord
	add $t4, $t4, $t3   # add display address
	
	la $t6, COLORS # load colors to $t6
	li $a0, 0     # Set seed again (mem changed by result)
	syscall # call random
	mul $t7, $a0, 4 # get index to take the color from array
	add $t7, $t7, $t6 # get color address in $t7
	lw $t7, 0($t7)    # Load color from memory
	sw $t7, 0($t4)   # Color in the pixel
	add $t1, $t1, 1   # Increment the row index
	j random_row
	
row:
	bgt $t1, 10, func_return   # Return if row is done (at index > 10)
	# Compute the pixel to color in $t4
	mul $t4, $t2, 128   # column coord in $t4
	mul $t5, $t1, 4     # row coord in $t5
	add $t4, $t4, $t5   # add current row coord
	add $t4, $t4, $t3   # add display address
	
	sw $t0, 0($t4)   # Color in the pixel
	add $t1, $t1, 1   # Increment the row index
	j row


column:
	bgt $t2, 20, func_return   # Return if column is done (at index > 20)	
	# Compute the pixel to color in t3
	mul $t4, $t2, 128  # column coord in $t4
	mul $t5, $t1, 4    # row coord in $t5
	add $t4, $t4, $t5   # add current row coord
	add $t4, $t4, $t3   # add display address
	
	sw $t0, 0($t4)   # Color in the pixel
	add $t2, $t2, 1   # Increment the row index
	j column
	


move_right:
	lw $t5, CHARA # Load character position
	bgt $t5, 8, game_loop # if character all the way right, don't go right
	jal undraw_chara # Remove character from old position
	lw $t5, CHARA # Load character position again ($t5 used by undraw)
	add $t5, $t5, 1 # Move character 1 unit to the right
	sw $t5, CHARA # Store new character position
	jal draw_chara # Draw character in new position
	j game_loop # Restart game loop

move_left:
	lw $t5, CHARA
	blt $t5, 4, game_loop # if character all the way left, don't go left
	jal undraw_chara # Remove character from old position
	lw $t5, CHARA # Load character position again ($t5 used by undraw)
	sub $t5, $t5, 1 # Move character 1 unit to the left
	sw $t5, CHARA # Store new character position
	jal draw_chara # Draw character in new position
	j game_loop # Restart game loop

# Draw the character
draw_chara:
	lw $t4, CHARA # Character x index position
	mul $t5, $t4, 4  # Get horizontal pixel position
	add $t5, $t5, 2688  # Add columns to the position
	add $t5, $t5, $t3  # Add display address
	li $t6, 0xffffff # character color: white pixel
	
	sw $t6, 0($t5) # draw it
	jr $ra # return func
	

# Undraw the character (use old pos)
undraw_chara:
	lw $t4, CHARA # Character x index position
	mul $t5, $t4, 4  # Get horizontal pixel position
	add $t5, $t5, 2688  # Add columns to the position
	add $t5, $t5, $t3  # Add display address
	li $t6, 0x000000 # character color: white pixel
	
	sw $t6, 0($t5) # draw it
	jr $ra # return func


quit:
	li $v0, 10                      # Quit gracefully
	syscall

#checks the keyboard input
keyboard_input:
	lw $a0, 4($t1)                  # Load second word from keyboard
	beq $a0, 0x71, quit             # Check if the key q was pressed (quit game)
    	beq $a0, 0x61, move_left        # Check if the key a was pressed (move left)
    	beq $a0, 0x64, move_right       # Check if the key d was pressed (move right)
    	beq $a0, 0x79, grab_bubbles      # Check if the key s was pressed (grab)


grab_bubbles:
	la $t0, BOARD  # Load BOARD into $t0 just in case
	lw $t4, CHARA  # $t4 takes the character's position
	sub $t4,$t4, 2 # $t4 is now the column we look at (index in the BOARD)
	li $t5, 13     # $t5 is the row we look at (BOARD index). Starts at the bottom
	j grab_bubbles_loop # A loop to grab all the bottom bubbles (with same color)
	# This loop always goes back to the game loop upon ending


grab_bubbles_loop:
	blt $t5, 0, game_loop # If at the top, stop the loop
	mul $t6, $t5, 7 # Start finding index by multiplying rows
	add $t6, $t6, $t4 # Find index of this "bubble" (or empty spot)
	mul $t6, $t6, 4   # Find the offset by multiplying by 4 (memory of an integer)
	add $t6, $t6, $t0 # The address of the bubble
	lw $t6, 0($t6) # Get the actual value of the bubble
	beq $t6, 0x000000, grab_bubbles_loop_incr # If it's empty, increment & go back to start of loop
	jal grab_bubble # Otherwise try to grab the bubble


grab_bubbles_loop_incr:
	sub $t5, $t5, 1 # decrement the row index
	j grab_bubble_loops # go back to start of loop
		

grab_bubble_diff_col:
	lw $t7 0(HELD) # Load into $t7 the number of held bubbles
	bne $t7, 0, j game_loop # If the colors are different, and a bubble is already held, end the loop
	li $t7, 1 # Else hold this one bubble
	sw $t7, 0(HELD) # And store the number of held bubbles
	sw $t6, 4(HELD) # And store the new color of held bubbles
	move $a0, $t4 # The row of the color as argument
	move $a1, $t5 # The column of the color as argument
	## TODO compute the actual coords of $a0 and $a1 so that undraw_bubble can be used behind the character
	j undraw_bubble # Undraw the bubble

grab_bubble:
	lw $t7 4(HELD) # Load into $t7 the color of held bubbles
	bne $t7, $t6, grab_bubble_diff_col # If the bubble is a different color (can hold if 0 held)
	
undraw_bubble:
	# stuff man idk yet

game_loop:
	la $t0, BOARD
	lw $t1, ADDR_KBRD
    # 1a. Check if key has been pressed
    lw $t8, 0($t1)                  # Load first word from keyboard
    beq $t8, 1, keyboard_input      # If first word 1, key is pressed (# 1b. Check which key has been pressed)
    
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to Step 1
    j game_loop
