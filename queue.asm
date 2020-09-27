    .data
    #struct node{
    #   int data_a 
    #   int data_b
    #   struct Node *next // struct Node == NULL(0) for last element, since it cannot point to anything.
    #}

    .globl rear #ptr to rear of queue
    .globl front#ptr to front of queue
    .globl prev_el#ptr to previous el
    .globl elemnts_in_q

elemnts_in_q: .word 0
rear:  .word -1
front: .word -1
prev_el: .word -1 #prev_el will be used to allow access to previous el. when PC is on the active  el.
                    #this will allow us to store the active el.'s addr in the previous el. effectively making 
                    #the previous el point to the next element.

select_func:   .asciiz "\nChoose between:\n(1) - Enqueue: inserts an element at the rear of the queue.\n(2) - Dequeue: removes the front element of the queue and prints it.\n(3) - Size: prints out the number of elements inside the queue.\n(4) - Peek: shows the values of the front element without removing it.\n(5) - Print: prints all the elements inside the queue or prints out if the queue is empty.\n(6) - Exit: ends the program.\n"
invalid_in:    .asciiz "Invalid input. Try again!"
a_str:  .asciiz "Enter value a:"
b_str:  .asciiz "Enter value b:"
size_str: .asciiz "Queue size:"


bracketL: .asciiz "["
bracketR: .asciiz "]"
comma: .asciiz ","
txt_empty: .asciiz "The queue is empty.\n"
txt_not_empty: .asciiz "The queue is not empty.\n"
nL:	.asciiz "\n"

    .text
    .globl main
main:
 
    la $a0, select_func
    li $v0, 4
    syscall

    li $v0, 5
    syscall

    #usr selection
    beq $v0, 1, sel_Enqueue_1
    beq $v0, 2, sel_Dequeue_2
    beq $v0, 3, sel_Size_3
    beq $v0, 4, sel_Peek_4
    beq $v0, 5, sel_Print_5
    beq $v0, 6, Exit
    
    #invalid input
    la $a0, invalid_in
    li $v0, 4
    syscall
    j main

    #v0 == 1
    sel_Enqueue_1:
    li $v0, 4
    la $a0, a_str
    syscall

    li $v0, 5
    syscall
    move $s0, $v0 # s0 = a

    li $v0, 4
    la $a0, b_str
    syscall

    li $v0, 5
    syscall
    
    move $a0, $s0 # a0 = a
    move $a1, $v0 # a1 = b
    
    jal enqueue
    j main


    #v0 == 2
    sel_Dequeue_2:
    jal dequeue
    j main

    #v0 == 3
    sel_Size_3:
    la $a0, size_str 
    li $v0, 4
    syscall

    jal size
    move $a0, $v0
    li $v0, 1
    syscall
    j main

    #v0 == 4
    sel_Peek_4:
    #cant peek if queue is empty
   

    jal peek
    beq $v0, -1, cant_peek #can't peek if q is empty
    lw $s1 0($v0)
    lw $s2 4($v0)

    la $a0, bracketL
    li $v0, 4
    syscall

    move $a0, $s1
    li $v0, 1
    syscall
    
    la $a0, comma
    li $v0, 4
    syscall

    move $a0, $s2
    li $v0, 1
    syscall

    la $a0, bracketR
    li $v0, 4
    syscall

    cant_peek:
    j main

    #v0 == 5
    sel_Print_5:
    jal queue_Print
    j main


    #v0 == 6 exit()
    Exit:


    li $v0, 10
    syscall


##########################################################################################
#enqueue adds an element to the end of the queue.
#Input:
#a0 = int_a
#a1 = int_b
#Output: ~
    # .text
    # .globl enqueue
enqueue:
    move $t0, $a0
    move $t1, $a1

    la $t9, elemnts_in_q # actual # of elements in the queue
    lw $t3 0($t9) # t3 = # of el.
    
    
    #malloc 3 * 4 bytes
    li $a0, 12
    li $v0, 9 #v0 will contain the addr of newly allocated memory
    syscall

    #modifying previous element
    la $t6, prev_el
    lw $t5 0($t6)#
    #if previous element is == -1 --> 
    #there is no previous el that needs to point to this one 
    #this means we do not need to add our new addr to a previous elment
    #(if !(-1) then we have the address addr of the previous element)
    beq $t5, -1, not_first_el
    sw $v0 8($t5)#our previous element now points to the element next to it, which is the newly added element.
    not_first_el:
    
    #updates to number of elements, rear, front(if first element) and prev_el
    #and it stores user integer in the new structure.

    #enque updates rear to new address (v0)
    la $t8, rear
    sw $v0 0($t8) #rear
    #if 1st element then rear == front ==v0
    bne $t3, 0, two_and_above
    #update front
    la $t7, front
    sw $v0 0($t7) #front (v0)
    two_and_above:
    
    addi $t3, $t3, 1# number of elements++
    sw $t3 0($t9)
    #update previous_elem
    sw $v0 0($t6)
    #store integer 1 in struct
    sw $t0 0($v0)
    #store integer 2 in struct
    sw $t1 4($v0)
    jr $ra



##########################################################################################
#dequeue removes an element from the queue and returns it
#Input:
#
#Output:
#v0 = addr of front el. ; if queue is empty then v0 = 0
    # .text
    # .globl dequeue
dequeue:
    la $t8, elemnts_in_q
    lw $t7 0($t8)
    #if el in queue == 0 then queue is empty
    move $v0, $t7
    beq $t7, 0, exit_dequeue

    la $t9, front
    lw $t0 0($t9) # t0 = addr of front el / first element of the queue

    move $v0, $t0
    #lw $v1 0($t0)#integer value of front (which will be the old front)
    

    #if queue is not empty
    #update front: front = addr next el
    beq $t0, -1, no_el #t0 == -1 --> queue is empty
    lw $t1, 8($t0) #t1 = addr of next element, which will be our new front
    #if *next == null --> front == rear
    bne $t1, 0, front_not_rear
    la $t6, rear
    lw $t1, 0($t6) # t1 = addr rear
    front_not_rear:
    sw $t1 0($t9) #update new front --> front = addr of next el
    no_el:

    #elements_in_queue --
    addi $t7, $t7, -1
    sw $t7 0($t8)

    exit_dequeue:
    #move $v0, $t0
    jr $ra

##########################################################################################
#size returns the size of the queue
#Input:
#
#Output:
# #v0 = size of queue
#   .text
#   .globl size
size:
    addi $sp, $sp, -4 # saving registers
    sw $ra 0($sp)

    la $t0, elemnts_in_q
    lw $v0 0($t0)

    jr $ra

    lw $ra 0($sp) #restoring registers
    addi $sp, $sp, 4
    

##########################################################################################
#is_Empty returns -1 if the queue is empty, otherwise -2
#Input:
#
#Output:
#v1 = -2 (queue is not empty) else  v1 = -1 
is_Empty:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    li $v1, -2 # is !empty
    la $t0, elemnts_in_q
    lw $t1 0($t0)
    
    bne $t1, 0, not_e
    li $v1, -1 # is empty
    not_e:

    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

##########################################################################################
#peek returns the the front element of the queue without removing it.
#Input:
#
#Output:
#v0 = addr. of front element ; if queue is empty return -1
peek:
    addi $sp, $sp -4 #saving register $ra
    sw $ra 0($sp)
    
    jal is_Empty
    move $v0, $v1
    beq $v1, -1, nothing_2_peek
    la $t0, front
    lw $v0 0($t0)
    nothing_2_peek:
   
    lw $ra 0($sp)
    addi $sp, $sp, 4 #restoring $ra
    
    jr $ra

################################################################################
#queue_Print prints all the elements inside the queue
#Input:
#
#Output:
#   
#   
queue_Print:
    addi $sp, $sp, -4
    sw $ra, 0($sp)


    jal is_Empty # v1 = -1 (Empty Queue) else v1 = -2 
    beq $v1, -1, empty_queue

    #print from front  to rear [a,b].
    jal peek
    move $t2, $v0
    
    
    print_loop:
    li $v0, 4
    la $a0, bracketL # [
    syscall

    li $v0, 1
    lw $a0, 0($t2) # Score
    syscall

    li $v0, 4
    la $a0, comma # ,
    syscall
    
    li $v0, 1
    lw $a0, 4($t2) # student serial n.
    syscall

    li $v0, 4
    la $a0,bracketR
    syscall
    
    lw $t3 8($t2) # *next
    move $t2, $t3
    bne $t3, 0, print_loop#  keeps on printing until struct Node == null

    #li $v0, 4
    la $a0, nL
    syscall
    j end_print



    #no elements inside the queue
    empty_queue:
    la $a0, txt_empty
    li $v0, 4
    syscall

    end_print:

    lw $ra, 0($sp)
    addi $sp, $sp, 4

    jr $ra
    
