/*****************************************************************************
 * File:		boot_hd.S
 * Description:		OS bootstrap code for hard disk.
 * Author:		Ruinan Duan <duanruinan@zoho.com>
 * Modify:		09/02/2019 10:42:33 		Created
 *****************************************************************************/

.code16

.org 0x0000
.globl START

START:
	xorw	%ax,		%ax
	movw	%ax,		%ds
	movw	%ax,		%es
	movw	%ax,		%ss
	movw	%ax,		%sp

	/* check memory layout */
	pushw	$mem_chk_msg_len
	pushw	$mem_chk_msg
	callw	print_msg
	addw	$4,		%sp
	callw	check_mem
	jmp	.

	pushw	$booting_msg_len
	pushw	$booting_msg
	callw	print_msg
	addw	$4,		%sp
	jmp	.

/*
 * INT15H
 * Func: Detecting memory
 * Input:
 *     EAX: 0xE820
 *     EBX: 0
 *     EDX: 0x534D4150
 *     CX: 24 (entry length. U should set as 24 for ACPI3.0,
 *             otherwise set as 20)
 * Output:
 *     ES:DI: Point to memory descriptor (DI is not increamented automaticly)
 * Usage:
 *     For the first call to INT15H, point ES:DI at the destination buffer for
 *     the list. Clear EBX. Set EDX to the magic number 0x534D4150. Set EAX to
 *     0xE820(note that upper 16-bits of EAX should be set to 0). Set ECX to 24.
 *     Do INT 0x15.
 *     If the first call to INT15H is successful, EAX will be set to 0x534D4150,
 *     and the carry flag will be clear. EBX will be set to some non-zero value,
 *     which must be preserved for the next call to the function. CL will will
 *     contain the number of bytes actually stored at ES:DI (propably 20).
 *     For the subsequent call to the function: increment DI by your list entry
 *     size, reset EAX to 0xE820, and ECX to 24. When you reach the end of the
 *     list, EBX may reset to 0. If you call the function again with EBX = 0,
 *     the list will start over. If EBX does not reset to 0, the function will
 *     return with carry set when you try to access the entry after the last
 *     valid entry.
 *     After getting the list, it may be desirable to: sort the list, combine
 *     adjacent ranges of the same type, change any overlapping areas to the
 *     most restrictive type, and change any unrecognised "type" values to type
 *     2.
 *     Type 3 "ACPI reclaimable" memory regions may be used like (and combined
 *     with) normal "available RAM" areas as long as you're finished using the
 *     ACPI tables that are stored there (e.g. it can be "reclaimed").
 *     Type 2,4,5 (reserved, ACPI non-volatile, bad) mark areas that should be
 *     avoided when you are allocating physical memroy.
 *     Treat unlisted regions as Type 2 -- reserved.
 *     Your code must be able to handle areas that don't start or end on any
 *     sort of "page boundary".
 * Base Address       | Length             | Type
 * 0x0000000000000000 | 0x000000000009FC00 | Free Memory (1)
 * 0x000000000009FC00 | 0x0000000000000400 | Reserved Memory (2)
 * 0x00000000000E8000 | 0x0000000000018000 | Reserved Memory (2)
 * 0x0000000000100000 | 0x0000000001F00000 | Free Memory (1)
 * 0x00000000FFFC0000 | 0x0000000000040000 | Reserved Memory (2)
 *
 */
check_mem:
	movw	$mmap_ent+4,	%di		/* set di point to entry */
	xorl	%ebx,		%ebx		/* clear ebx */
	xorw	%bp,		%bp		/* keep an entry count in bp */
	movl	$0x534D4150,	%edx		/* place "SMAP" into edx */
	movl	$0xE820,	%eax
	movw	$1,		%es:20(%di)	/* force a valid ACPI 3 entry */
	movl	$24,		%ecx		/* ask for 24 bytes */
	int	$0x15
	jc	6f				/* carry set on first call mean
						 * unsupported function */
	movl	$0x534D4150,	%edx		/* some BIOSes apparently trash
						 * this register */
	cmpl	%edx,		%eax		/* on success, eax must have
						 * been reset to "SMAP" */
	jne	6f
	testl	%ebx,		%ebx		/* ebx = 0 implies list is only
						 * 1 entry long (worthless) */
	jz	6f
	jmp	2f
1:	movl	$0xE820,	%eax		/* eax, ecx get trashed */
	movw	$1,		%es:20(%di)	/* force a valid ACPI 3 entry */
	movl	$24,		%ecx		/* ask for 24 bytes again */
	int	$0x15
	jc	5f				/* carry set means "end of list
						 * reached */
	movl	$0x534D4150,	%edx		/* repair potentially trashed
						 * register */
2:
	jcxz	4f				/* skip any 0 length entries */
	cmpb	$20,		%cl		/* got a 24 byte ACPI 3.x
						 * response*/
	jbe	3f
	testb	$1,		%es:20(%di)	/* if so: is the "ignore this
						 * data" bit clear ? */
	jz	4f
3:	movl	%es:8(%di),	%ecx		/* lower uint32_t of memory
						 * region length */
	orl	%es:12(%di),	%ecx		/* "or" it with upper uint32_t
						 * to test for zero */
	jz	4f
	incw	%bp
	addw	$24,		%di
4:	testl	%ebx,		%ebx		/* if ebx resets to 0,complete*/
	jne	1b
5:	movw	%bp,		mmap_ent	/* store the entry count */
	clc
	ret
6:	std
	ret

/*
 * Print String
 * INT10H Get Cursor position
 * Input:
 *     AH: 03H
 *     BH: Page
 * Output:
 *     CH: Start line
 *     CL: End line
 *     DH: line
 *     DL: collumn
 *
 * INT10H Print string
 * Input:
 *     AH: 13H
 *     AL: Mode
 *     ES:BP: Address of string
 *     CX: length
 *     BH: Page
 *     BL: attribute
 *     DH: line
 *     DL: collumn
 *     Mode: AL
 *         0x00: Do not update cursor's position. attribute in BL
 *         0x01: Update cursor's position. attribute in BL
 *         0x02: Do not update cursor's position. attribute in "string data"
 *         0x03: Update cursor's position. attribute in "string data"
 * Output:
 *     None
 */
print_msg:
	pushw	%bp
	movb	$0x03,		%ah
	xorb	%bh,		%bh
	int	$0x10
	movw	4(%esp),	%ax
	movw	%ax,		%bp /* address of string */
	movw	%cs,		%ax
	movw	%ax,		%es
	movw	6(%esp),	%cx /* string's length */
	movw	$0x1301,	%ax
	movw	$0x0007,	%bx
	int	$0x10
	popw	%bp
	ret

itoa:
	pushw	%bp
	movw	4(%esp),	%ax
	movw	%ax,		%si /* address of string */
	movw	6(%esp),	%ax /* string's length */
	movw	8(%esp),	%ax /* integer */
	movw	$8,		%cx
	popw	%bp
	ret

int_str:	.ascii		"AAAA"
.equ	int_str_len,		4
crcf_str:	.ascii		"\r\n"
.equ	crcf_str_len,		2
mem_chk_msg:	.ascii		"Checking memory...\r\n"
.equ	mem_chk_msg_len,	. - mem_chk_msg
booting_msg:	.ascii		"Loading bootloader...\r\n"
.equ	booting_msg_len,	. - booting_msg
.equ	mmap_ent,		0x0800

.org 0x01FE
.short 0xAA55
.end

