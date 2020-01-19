
;MMC�h���C�o
;�E�o�T http://w01.tp1.jp/~a571632211/pc8001/index.html

HI		EQU	1

PA_IN		EQU	00010000B
PB_IN		EQU	00000010B
PCL_IN		EQU	00000001B
PCH_IN		EQU	00001000B

A8255		EQU 	0FCH		;8255 �|�[�g�A�h���X
PPI_A		EQU	A8255		;
PPI_B		EQU	A8255+1		;
PPI_C		EQU	A8255+2		;
PPI_CTL		EQU	A8255+3		;

PPI_MMC		EQU	10000000B + PCH_IN	;MMC�h���C�o�Ŏg�p����8255�̃|�[�g�ݒ�

VLED_POS:	EQU	VRAM+78			;���zLED�̈ʒu

;MMCADR0:	DS	1	;MMC �����A�h���X L   MMC�̃A�h���X��32�r�b�g��
;MMCADR1:	DS	1	;MMC �����A�h���X H
;MMCADR2:	DS	1	;MMC �����A�h���X HH
;MMCADR3:	DS	1	;MMC �����A�h���X HHH

;=================================================
;[MMC]8255���[�h�Z�b�g
;=================================================
INIT_8255:
	PUSH	HL

	LD	A,PPI_MMC		;MODE=0,A=IN,B=OUT,CH=IN,CL=OUT
	OUT	(PPI_CTL),A
	LD	A,0F7H
	OUT	(PPI_B),A
	IN	A,(PPI_B)
	CP	0F7H
	JR	Z,.L1

	LD	HL,MSG_NOT_FOUND
	CALL	PRINT
	CALL	KEYWAIT

.L1:	LD	A,0FFH
	OUT	(PPI_B),A

	POP	HL
	RET

;=================================================
;[MMC]MMC��1�o�C�g����
;IN  C=���M�f�[�^
;OUT -
;=================================================
MMC_1WR:
	PUSH	BC
	LD	B,8
.L1:	IN	A,(PPI_B)
	AND	0FEH
	OUT	(PPI_B),A
	CALL	MMC_WAIT
	IN	A,(PPI_B)
	AND	0FDH
	RL	C
	JR	NC,.L2
	OR	02H
.L2:	OUT	(PPI_B),A
	CALL	MMC_WAIT
	IN	A,(PPI_B)
	OR	01H
	OUT	(PPI_B),A
	CALL	MMC_WAIT
	DJNZ	.L1
	POP	BC
	IN	A,(PPI_B)
	OR	02H
	OUT	(PPI_B),A
	RET

;=================================================
;[MMC]MMC����1�o�C�g�󂯎��
;IN  -
;OUT C=��M�f�[�^
;=================================================
MMC_1RD:
	LD	B,8
.LOOP:	IN	A,(PPI_B)
	AND	0FEH
	OUT	(PPI_B),A
        OR	001H
	OUT	(PPI_B),A
	XOR	A
	RL	C
	IN	A,(PPI_C)
	AND	010H
	JR	Z,.L1
	INC	C
.L1:	DJNZ	.LOOP
	RET

;=================================================
;[MMC]MMC����1�o�C�g���X�|���X���󂯎��
;IN  -
;OUT C=���X�|���X
;=================================================
MMC_RES:
	XOR	A				;�^�C���A�E�g�p�J�E���^���Z�b�g
	LD	(TIMEOUT),A

.LOOP:	PUSH	HL
	LD	HL,TIMEOUT
	INC	(HL)
	LD	A,(HL)
	POP	HL
	OR	A
	JR	Z,MMC_TIMEOUT

	LD	B,1
	CALL	MMC_CLK

	IN	A,(PPI_C)
	AND	010H
	JR	NZ,.LOOP

	LD	BC,0700H			;B<-7
	JR	MMC_1RD.LOOP

;=================================================
;[MMC]�^�C���A�E�g����
;=================================================
MMC_TIMEOUT:
	CALL	IPRINT
	DB	"Set SDC then ",DQUOTE,"MOUNT",DQUOTE,CR,LF,EOL
	LD	E,UNPRINTABLE
	JP	ERROR

;=================================================
;[MMC]MMC�N���b�N
;IN  B=��
;OUT 
;=================================================
MMC_CLK:
	IN	A,(PPI_B)
	AND	11111110B
	OUT	(PPI_B),A
	CALL	MMC_WAIT
	IN	A,(PPI_B)
	OR	00000001B
	OUT	(PPI_B),A
	CALL	MMC_WAIT
	DJNZ	MMC_CLK
	RET

;=================================================
;[MMC]CS=H�ɂ���MMC�N���b�NX8
;=================================================
MMC_CLK8:
	IN	A,(PPI_B)
	OR	00000100B
	OUT	(PPI_B),A  			;CS=H
	LD	B,8
	CALL	MMC_CLK   			;MMC�N���b�N���s
	IN	A,(PPI_B)
	AND	11111011B
	OUT	(PPI_B),A  			;CS=L
	RET

;=================================================
;[MMC]MMC��SPI���[�h�ɏ���������
;=================================================
MMC_INIT:
	IN	A,(PPI_B)
	OR	00000100B
	OUT	(PPI_B),A
	LD	B,200
	CALL	MMC_CLK
	IN	A,(PPI_B)
	AND	11111011B
	OUT	(PPI_B),A
	LD	C,01000000B
	CALL	MMC_1WR
	LD	C,0
	CALL	MMC_1WR
	CALL	MMC_1WR
	CALL	MMC_1WR
	CALL	MMC_1WR
	LD	C,10010101B
	CALL	MMC_1WR
	CALL	MMC_RES
	LD	A,01H
	CP	C
	JR	NZ,MMC_INIT

.L1:	CALL	MMC_CLK8
	LD	C,01000001B
	CALL	MMC_1WR
	LD	C,0
	CALL	MMC_1WR
	CALL	MMC_1WR
	CALL	MMC_1WR
	CALL	MMC_1WR
	LD	C,11111001B
	CALL	MMC_1WR
	CALL	MMC_RES
	LD	A,0
	CP	C
	JR	NZ,.L1
	RET

;=================================================
;[MMC]�u���b�NREAD�R�}���h
;=================================================
MMC_BRD_CMD:
	CALL	MMC_CLK8
	LD	C,01010001B
	CALL	MMC_1WR
	LD	A,(MMCADR3)
	LD	C,A
	CALL	MMC_1WR
	LD	A,(MMCADR2)
	LD	C,A
	CALL	MMC_1WR
	LD	A,(MMCADR1)
	LD	C,A
	CALL	MMC_1WR
	LD	A,(MMCADR0)
	LD	C,A
	CALL	MMC_1WR
	LD	C,00000001B
	CALL	MMC_1WR
	CALL	MMC_RES
	LD	A,0
	CP	C
	JR	NZ,MMC_BRD_CMD

.L1:	CALL	MMC_1RD
	LD	A,C
	AND	11100000B
	JR	Z,MMC_BRD_CMD
	LD	A,C
	CP	0FEH
	JR	NZ,.L1
	RET

;=================================================
;[MMC]�u���b�NREAD�I������
;=================================================
MMC_BRD_END:
	CALL	MMC_1RD
	CALL	MMC_1RD
	RET

;=================================================
;[MMC]�u���b�NWRITE�R�}���h
;=================================================
MMC_BWR_CMD:
	CALL	MMC_CLK8
	LD	C,01011000B
	CALL	MMC_1WR
	LD	A,(MMCADR3)
	LD	C,A
	CALL	MMC_1WR
	LD	A,(MMCADR2)
	LD	C,A
	CALL	MMC_1WR
	LD	A,(MMCADR1)
	LD	C,A
	CALL	MMC_1WR
	LD	A,(MMCADR0)
	LD	C,A
	CALL	MMC_1WR
	LD	C,00000001B
	CALL	MMC_1WR
	CALL	MMC_RES
	LD	A,0
	CP	C
	JR	NZ,MMC_BWR_CMD

	LD	C,0FFH
	CALL	MMC_1WR
	LD	C,0FEH
	CALL	MMC_1WR
	RET

;=================================================
;[MMC]�u���b�NWRITE�I������
;=================================================
MMC_BWR_END:
	LD	C,0
	CALL	MMC_1WR
	LD	C,0
	CALL	MMC_1WR
	CALL	MMC_RES

.L1:	IN	A,(PPI_B)
	AND	11111110B
	OUT	(PPI_B),A
	CALL	MMC_WAIT
	IN	A,(PPI_B)
	OR	00000001B
	OUT	(PPI_B),A
	CALL	MMC_WAIT
	IN	A,(PPI_C)
	AND	00010000B
	JR	Z,.L1
	RET

;=================================================
;[MMC]�����A�h���X�N���A
;=================================================
MMC_CLR_ADR:
	XOR	A
	LD	(MMCADR0),A
	LD	(MMCADR1),A
	LD	(MMCADR2),A
	LD	(MMCADR3),A
	RET

;=================================================
;[MMC]�����A�h���X��1�u���b�N���i�߂�
;=================================================
MMC_INC_ADR:
	LD	A,(MMCADR1)
	ADD	A,2
	LD	(MMCADR1),A
	LD	A,(MMCADR2)
	ADC	A,0
	LD	(MMCADR2),A
	LD	A,(MMCADR3)
	ADC	A,0
	LD	(MMCADR3),A
	RET

;=================================================
;[MMC]MMC�ǂݍ���
;IN  MMCADR0,1,2,3=MMC�A�h���X HL=�������A�h���X B=�u���b�N��
;OUT 
;=================================================
MMC_READ:
	PUSH	BC

	CALL	MMC_LED_ON

	CALL	MMC_BRD_CMD
	LD	B,2
.L1:	PUSH	BC
	LD	B,0				;256�񃋁[�v
.L2:	PUSH	BC
	CALL	MMC_1RD
	LD	(HL),C
	INC	HL
	POP 	BC
	DJNZ	.L2
	POP	BC
	DJNZ	.L1
	CALL	MMC_BRD_END
	CALL	MMC_INC_ADR
	POP	BC

	CALL	MMC_LED_OFF

	DJNZ	MMC_READ
	RET

;=================================================
;[MMC]MMC��������
;IN  MMCADR0,1,2,3=MMC�A�h���X HL=�������A�h���X B=�u���b�N��
;OUT 
;=================================================
MMC_WRITE:
	PUSH	BC

	CALL	MMC_LED_ON

	CALL	MMC_BWR_CMD
	LD	B,2
.L1:	PUSH	BC
	LD	B,0
.L2:	PUSH	BC
	LD	C,(HL)
	INC	HL
	CALL	MMC_1WR
	POP	BC
	DJNZ	.L2
	POP	BC
	DJNZ	.L1
	CALL	MMC_BWR_END
	CALL	MMC_INC_ADR
	POP	BC

	CALL	MMC_LED_OFF

	DJNZ	MMC_WRITE
	RET

;=================================================
;[MMC]MMC���ߐs����
;IN  MMCADR0,1,2,3=MMC�A�h���X L=���߂�l B=�u���b�N��
;OUT -
;=================================================
MMC_FILLB:
	PUSH	BC

	CALL	MMC_LED_ON

	CALL	MMC_BWR_CMD
	LD	B,2
.L1:	PUSH	BC
	LD	B,0
.L2:	PUSH	BC
	LD	C,L
	CALL	MMC_1WR
	POP	BC
	DJNZ	.L2
	POP	BC
	DJNZ	.L1
	CALL	MMC_BWR_END
	CALL	MMC_INC_ADR
	POP	BC

	CALL	MMC_LED_OFF

	DJNZ	MMC_FILLB
	RET

;=================================================
;[MMC]12�N���b�N�̃E�F�C�g�}��
;=================================================
MMC_WAIT:
	NOP
	NOP
	NOP
	RET

;=================================================
;�A�N�Z�X�����v�_��
;=================================================
MMC_LED_ON:
	IN	A,(PPI_B)
	AND	11110111B			;LED�M���𗧂Ă�(���_��)
	OUT	(PPI_B),A

IF USE_VIRTUAL_SOUND
	CALL	MMC_SOUND
ENDIF

	LD	A,(INFO_SW)			;�C���t�H���[�V�����t���O���~��Ă�����߂�
	AND	A
	RET	Z

IF USE_VIRTUAL_LED
	LD	A,02AH				;="*"
	LD	(VLED_POS),A
ENDIF

	RET

;=================================================
;�A�N�Z�X�����v����
;=================================================
MMC_LED_OFF:
	IN	A,(PPI_B)
	AND	11111110B			;PB0=CLK<-L microSD���W���[����LED������
	OR	00001000B			;LED�M�����~�낷(���_��)
	OUT	(PPI_B),A

	LD	A,(INFO_SW)
	AND	A
	RET	Z

IF USE_VIRTUAL_LED
	XOR	A				;=NULL����
	LD	(VLED_POS),A
ENDIF
	RET

;=================================================
;�^���A�N�Z�X��
;=================================================
IF USE_VIRTUAL_SOUND
MMC_SOUND:
	PUSH	BC

	LD	B,20H
.L1:	LD	A,(0EA67H)
	OR	00100000B
	OUT	(40H),A
	AND	11011111B
	OUT	(40H),A
	DJNZ	.L1

	POP	BC
	RET
ENDIF

