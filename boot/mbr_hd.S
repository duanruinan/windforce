/*****************************************************************************
 * File:		mbr_hd.S
 * Description:		MBR bootstrap code for hard disk.
 * 			The bootstrap program will choose a partition for the
 * 			next stage's bootup from 4 primary partitions in MBR
 * 			partition table (the type of which is 0xC8).
 * 			U should use wrtmbr tool to write mbr into disk image.
 * 			wrtmbr will preserve MBR partition table on the disk.
 * 			e.g. wrtmbr mbr_image c.img
 * Author:		Ruinan Duan <duanruinan@zoho.com>
 * Modify:		09/02/2019 10:42:33 		Created
 *****************************************************************************/

.code16

.org 0x0000
.globl START

START:
	cli
	xorw	%ax,		%ax
	movw	%ax,		%ds
	movw	%ax,		%es
	movw	%ax,		%ss
	movw	%ax,		%sp

	movw	$0x0100,	%cx
	movw	$0x7C00,	%si
	movw	$0x0600,	%di
	rep	movsw
	ljmp	$0x0000,	$start_base_0600

start_base_0600:
	sti
	movb	%dl,		drv_num
	callw	clrscr
	movw	$pt1,		%bx
	movw	$4,		%cx
1:	movb	4(%bx),	%al
	cmpb	$0xC8,		%al
	jz	2f
	addw	$0x10,		%bx
	decw	%cx
	jnz	1b
	jmp	3f
2:	movw	%bx,		pt_offs
	callw	test_lba
	movw	pt_offs,	%bx
	addw	$8,		%bx
	movl	(%bx),		%ebx
	movl	%ebx,		lba_addr_l
	movw	$0x7C00,	%bx
	movw	%bx,		buf
	movw	$1,		blkcnt

	callw	read_sector

	cmpw	$0xAA55,	0x7DFE
	jne	4f
	movw	pt_offs,	%si
	movb	drv_num,	%dl
	pushw	$ok_msg_len
	pushw	$ok_msg
	callw	print_msg
	addw	$4,		%sp
	ljmp	$0x0000,	$0x7C00

3:	pushw	$err_msg_len
	pushw	$err_msg
	jmp	5f
4:	pushw	$illegal_mbr_len
	pushw	$illegal_mbr
5:	callw	print_msg
	addw	$4,		%sp
	jmp	.

test_lba:
	movb	$0x41,		%ah
	movw	$0x55AA,	%bx
	movb	drv_num,	%dl
	int	$0x13
	jc	6f
	ret
6:	pushw	$no_lba_len
	pushw	$no_lba
	callw	print_msg
	jmp	.

/*
 * Read a sector using LBA
 * INT13H Read LBA Sector
 * Input:
 *     AH: 42H
 *     DS:SI: Disk Address Packet
 *     DL: DrvNUM
 * Output:
 *     CF: 0 ok, 1 fail
 *     AH: 0
 */
read_sector:
	movw	$dapack,	%si
	movb	$0x42,		%ah
	movb	drv_num,	%dl
	int	$0x13
	jc	7f
	ret
7:	pushw	$io_err_len
	pushw	$io_err
	callw	print_msg
	jmp	.

/*
 * Clear Screen
 * INT10H Scroll up
 * Input:
 *     AH: 06H
 *     AL: Line number of scrolling up (0 - all)
 *     BH: attribute byte
 *     CH, CL: top, left
 *     DH, DL: bottom, right
 * Output:
 *     None
 *
 * INT10H Set cursor
 * Input:
 *     AH: 02H
 *     DH, DL: row, collumn
 *     BH: Page
 * Output:
 *     None
 */
clrscr:
	movb	$6,		%ah
	xorb	%al,		%al
	xorw	%cx,		%cx
	movw	$(24*256+79),	%dx
	movb	$0x07,		%bh
	int	$0x10
	xorb	%bh,		%bh
	xorw	%dx,		%dx
	movb	$0x02,		%ah
	int	$0x10
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

dapack:		.byte		0x10
		.byte		0
blkcnt:		.short		1	/* count of sectors,INT13H reset to 0 */
buf:		.short		0x7C00
		.short		0
lba_addr_l:	.int		0
		.int		0
err_msg:	.ascii		"No OS"
.equ	err_msg_len,		. - err_msg
illegal_mbr:	.ascii		"Illegal MBR"
.equ	illegal_mbr_len,	. - illegal_mbr
ok_msg:		.ascii		"Bootstrap...\r\n"
.equ	ok_msg_len,		. - ok_msg
no_lba:		.ascii		"NoLBA"
.equ	no_lba_len,		. - no_lba
io_err:		.ascii		"IOERR"
.equ	io_err_len,		. - io_err
drv_num:	.byte		0
pt_offs:	.short		0
.org 0x01B8
disk_id:	.int		0xFEFEFEFE
.org 0x01BE
pt1:		.octa		0
pt2:		.octa		0
pt3:		.octa		0
pt4:		.octa		0
.org 0x01FE
.short 0xAA55
.end

