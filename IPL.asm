
;IPL

INCLUDE "LABELS.ASM"
INCLUDE	"N80.ASM"

A8255:		EQU 	0FCH			;8255 �|�[�g�A�h���X

	ORG	0C000H

START:
	CALL	INIT_DW
	CALL	INIT_8255			;PPI������
	CALL	MMC_INIT			;MMC������
	CALL	READ_MBR			;�p�[�e�B�V�����J�n�Z�N�^�����Z�b�g����

	LD	HL,DOS
	LD	DE,DW0
	CALL	DW_COPY
	CALL	GET_PHYSICAL_ADRS
	LD	HL,06000H-6
	LD	B,0FH
	CALL	MMC_READ
	JP	BASIC				;


DOS:	DB	41H,04H,00H,00H

;=================================================
;[FS]MBR�̓ǂݍ���
;IN  
;OUT (PP_SCTR)
;=================================================
READ_MBR:
	LD	HL,MMCADR0			;MMC�A�h���X��00000000H�ɃZ�b�g
	CALL	DW_CLR				;
	LD	HL,PP_SCTR			;�v���C�}���p�[�e�B�V�����̊J�n�Z�N�^����00000000H�ɃZ�b�g
	CALL	DW_CLR				;
	LD	HL,FILE_BFFR			;MBR���o�b�t�@�ɓǂݍ���
	LD	B,01H				;
	PUSH	HL				;
	CALL	MMC_READ			;
	POP	HL				;�Z�N�^��0�̍ŏ��̃o�C�g��00H�Ȃ�p�[�e�B�V�������؂��Ă���Ƃ���
	LD	A,(HL)				;
	OR	A				;
	RET	NZ				;
	LD	DE,IDX_PP_SCTR			;�u�v���C�}���p�[�e�B�V�����̊J�n�Z�N�^���v�����[�N�ɕۑ�����
	ADD	HL,DE				;
	LD	DE,PP_SCTR			;
	CALL	DW_COPY				;
	RET					;

;=================================================
;[FS]�Z�N�^�����畨���A�h���X�����߂�
;IN  (DW0)=�Z�N�^��
;OUT (MMCADR0)=�����A�h���X
;=================================================
GET_PHYSICAL_ADRS:
	PUSH	DE				;
	PUSH	HL				;
	CALL	DW0_PUSH			;(DW0)��ޔ�
	LD	HL,PP_SCTR			;(DW0)<-�Z�N�^��+�v���C�}���p�[�e�B�V�����̊J�n�Z�N�^��
	LD	DE,DW1				;
	CALL	DW_COPY				;
	CALL	DW0_ADD				;
	CALL	DW_X512				;(MMCADR0)<-�Z�N�^��*�Z�N�^�T�C�Y=�����A�h���X
	LD	HL,DW0				;
	LD	DE,MMCADR0			;
	CALL	DW_COPY				;
	CALL	DW0_POP				;(DW0)�𕜋�
	POP	HL				;
	POP	DE				;
	RET					;

;=================================================
;[FS]�Z�N�^���w��̈�ɓǂݍ���
;IN  (DW0)=�ǂݍ��݂����Z�N�^��,HL=�������̈�̐擪�A�h���X
;OUT (MMCADR0~3)
;=================================================
READ_SCTR:
	CALL	GET_PHYSICAL_ADRS		;(MMCADR0)<-�Z�N�^��(DW0)�̕����A�h���X
	LD	B,01H				;=MMC�u���b�N��
	CALL	MMC_READ			;������<-�Z�N�^�f�[�^200H�o�C�g
	RET					;


;=================================================
;[SUB]�G���[���b�Z�[�W�\��
;IN  HL=���b�Z�[�W�̃A�h���X
;OUT -
;=================================================
ERR:
	CALL	PRINT				;
	CALL	PUT_CR				;
	LD	E,UNPRINTABLE			;
	JP	ERROR				;

;=================================================
;[SUB]�������\������
;IN  (SP)=������̐擪�A�h���X
;OUT -
;=================================================
IPRINT:
	EX	(SP),HL				;
	PUSH	AF				;
.L1:	LD	A,(HL)				;
	INC	HL				;
	OR	A				;
	JR	Z,.L2				;
	RST	18H				;
	JR	.L1				;
.L2:	POP	AF				;
	EX	(SP),HL				;
	RET					;

;=================================================
;�_�u�����[�h�X�^�b�N������
;=================================================
INIT_DW:
	LD	HL,DW_STACK			;
	LD	(DW_SP),HL			;
	RET					;

;=================================================
;�_�u�����[�h���R�s�[����
;(HL)->(DE)
;IN  HL=SOURCE,DE=DEST
;OUT 
;=================================================
DW_COPY:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
	LD	BC,0004H			;
	LDIR					;
	POP	HL				;
	POP	DE				;
	POP	BC				;
	RET					;

;=================================================
;�_�u�����[�h(DW0)���X�^�b�N�ɐς�
;IN  DW0
;OUT -
;=================================================
DW0_PUSH:
	PUSH	DE				;
	PUSH	HL				;
	LD	HL,DW0				;
	JP	DW_PUSH.E1			;

;=================================================
;�_�u�����[�h(HL)���X�^�b�N�ɐς�
;IN  HL
;OUT -
;=================================================
DW_PUSH:
	PUSH	DE				;
	PUSH	HL				;
.E1:	LD	(DW_SP_ORG),SP			;�V�X�e���̃X�^�b�N�|�C���^���ꎞ�G���A�ɑޔ�����
	LD	SP,(DW_SP)			;�X�^�b�N�|�C���^���_�u�����[�h�p�ɕύX����
	LD	E,(HL)				;<-�ŉ��ʃo�C�g
	INC	HL				;
	LD	D,(HL)				;<-��Q�ʃo�C�g
	INC	HL				;
	PUSH	DE				;
	LD	E,(HL)				;<-��R�ʃo�C�g
	INC	HL				;
	LD	D,(HL)				;<-�ŏ�ʃo�C�g
	PUSH	DE				;
	LD	(DW_SP),SP			;�_�u�����[�h�p�X�^�b�N�|�C���^��ۑ�����
	LD	SP,(DW_SP_ORG)			;�V�X�e���̃X�^�b�N�|�C���^�𕜋�����
	POP	HL				;
	POP	DE				;
	RET					;

;=================================================
;�_�u�����[�h(DW0)���X�^�b�N������o��
;IN  -
;OUT (DW0)
;=================================================
DW0_POP:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
	LD	HL,DW0				;
	JP	DW_POP.E1			;

;=================================================
;�_�u�����[�h(HL)���X�^�b�N������o��
;IN  HL
;OUT (HL)
;=================================================
DW_POP:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
.E1:	LD	(DW_SP_ORG),SP			;�V�X�e���̃X�^�b�N�|�C���^���ꎞ�G���A�ɑޔ�����
	LD	SP,(DW_SP)			;�X�^�b�N�|�C���^���_�u�����[�h�p�ɕύX����
	POP	DE				;
	POP	BC				;
	LD	(HL),C				;<-�ŉ��ʃo�C�g
	INC	HL				;
	LD	(HL),B				;<-��Q�ʃo�C�g
	INC	HL				;
	LD	(HL),E				;<-��R�ʃo�C�g
	INC	HL				;
	LD	(HL),D				;<-�ŏ�ʃo�C�g
	LD	(DW_SP),SP			;�_�u�����[�h�p�X�^�b�N�|�C���^��ۑ�����
	LD	SP,(DW_SP_ORG)			;�V�X�e���̃X�^�b�N�|�C���^�𕜋�����
	POP	HL				;
	POP	DE				;
	POP	BC				;
	RET					;

;=================================================
;�_�u�����[�h(DW0)���O�ɂ���
;IN  -
;OUT (DW0)
;=================================================
DW0_CLR:
	PUSH	HL				;
	LD	HL,DW0				;
	JP	DW_CLR.E1			;

;=================================================
;�_�u�����[�h(HHLL)���O�ɂ���
;IN  HL
;OUT (HHLL)
;=================================================
DW_CLR:
	PUSH	HL				;
.E1:	XOR	A				;DW0_CLR�̃G���g���|�C���g
	LD	(HL),A				;
	INC	HL				;
	LD	(HL),A				;
	INC	HL				;
	LD	(HL),A				;
	INC	HL				;
	LD	(HL),A				;
	POP	HL				;
	RET					;

;=================================================
;�_�u�����[�h���Z (DW0)<-(DW0)+(DW1)
;IN  DW0=����Z���̃|�C���^,DW1=���Z���̃|�C���^
;OUT (DW0),CY
;=================================================
DW0_ADD:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
	LD	HL,DW0				;
	LD	DE,DW1				;
	JP	DW_ADD.E1			;

;=================================================
;�_�u�����[�h���Z (HL)<-(HL)+(DE)
;IN  HL=����Z���̃|�C���^,DE=���Z���̃|�C���^
;OUT (HL),CY
;=================================================
DW_ADD:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
.E1:	LD	B,4				;DW0_ADD�̃G���g���|�C���g
	OR	A				;CY<-0
.L1:	LD	A,(DE)				;(HL)<-(HL)+(DE) & CY
	ADC	A,(HL)				;
	LD	(HL),A				;
	INC	DE				;DE++
	INC	HL				;HL++
	DJNZ	.L1				;B--
	POP	HL				;
	POP	DE				;
	POP	BC				;
	RET					;

;=================================================
;�_�u�����[�h(DW0)��2�{����
;IN  -
;OUT (DW0),CY<-BIT31
;=================================================
DW0_X2:
	PUSH	HL				;
	LD	HL,DW0				;
	JP	DW_X2.E1			;

;=================================================
;�_�u�����[�h(HL)��2�{����
;IN  HL
;OUT (HL),CY<-BIT31
;=================================================
DW_X2:
	PUSH	HL				;
.E1:	SLA	(HL)				;BIT0<-0,CY<-BIT7
	INC	HL				;+1 �t���O�͕ω����Ȃ�
	RL	(HL)				;BIT8<-CY,CY<-BIT15
	INC	HL				;+2
	RL	(HL)				;BIT16<-CY,CY<-BIT23
	INC	HL				;+3
	RL	(HL)				;BIT24<-CY,CY<-BIT31
	POP	HL				;
	RET					;

;=================================================
;DW0��256�{����
;IN  (DW0)
;OUT -
;=================================================
DW_X256:
	PUSH	AF				;
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
	LD	HL,DW0+2			;�]���� 00 01 02 03
	LD	DE,DW0+3			;�]���� XX 00 01 02
	LD	BC,0003H			;�]����
	LDDR					;BC--,DE--,HL--
	XOR	A				;
	LD	(DE),A				;(DW0+0)<-0
	POP	HL				;
	POP	DE				;
	POP	BC				;
	POP	AF				;
	RET					;

;=================================================
;DW0��512�{����
;IN  (DW0)
;OUT CY
;=================================================
DW_X512:
	CALL	DW0_X2				;
	CALL	DW_X256				;
	RET					;

;=================================================
;[MMC]8255���[�h�Z�b�g
;=================================================
INIT_8255:
	PUSH	HL

	LD	A,099H
	OUT	(A8255+3),A
	LD	A,0F7H
	OUT	(A8255+1),A
	IN	A,(A8255+1)
	CP	0F7H
	JR	Z,.L1

	LD	HL,MSG_NOT_FOUND
	CALL	PRINT
	CALL	KEYWAIT

.L1:	LD	A,0FFH
	OUT	(A8255+1),A

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
.L1:	IN	A,(A8255+1)
	AND	0FEH
	OUT	(A8255+1),A
	CALL	MMC_WAIT
	IN	A,(A8255+1)
	AND	0FDH
	RL	C
	JR	NC,.L2
	OR	02H
.L2:	OUT	(A8255+1),A
	CALL	MMC_WAIT
	IN	A,(A8255+1)
	OR	01H
	OUT	(A8255+1),A
	CALL	MMC_WAIT
	DJNZ	.L1
	POP	BC
	IN	A,(A8255+1)
	OR	02H
	OUT	(A8255+1),A
	RET

;=================================================
;[MMC]MMC����1�o�C�g�󂯎��
;IN  -
;OUT C=��M�f�[�^
;=================================================
MMC_1RD:
	LD	B,8
.LOOP:	IN	A,(A8255+1)
	AND	0FEH
	OUT	(A8255+1),A
        OR	001H
	OUT	(A8255+1),A
	XOR	A
	RL	C
	IN	A,(A8255+2)
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

	IN	A,(A8255+1)
	AND	0FEH
	OUT	(A8255+1),A
	CALL	MMC_WAIT
	IN	A,(A8255+1)
	OR	001H
	OUT	(A8255+1),A
	CALL	MMC_WAIT
	IN	A,(A8255+2)
	AND	010H
	JR	NZ,.LOOP

	LD	BC,0700H
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
	IN	A,(A8255+1)
	AND	11111110B
	OUT	(A8255+1),A
	CALL	MMC_WAIT
	IN	A,(A8255+1)
	OR	00000001B
	OUT	(A8255+1),A
	CALL	MMC_WAIT
	DJNZ	MMC_CLK
	RET

;=================================================
;[MMC]CS=H�ɂ���MMC�N���b�NX8
;=================================================
MMC_CLK8:
	IN	A,(A8255+1)
	OR	00000100B
	OUT	(A8255+1),A  			;CS=H
	LD	B,8
	CALL	MMC_CLK   			;MMC�N���b�N���s
	IN	A,(A8255+1)
	AND	11111011B
	OUT	(A8255+1),A  			;CS=L
	RET

;=================================================
;[MMC]MMC��SPI���[�h�ɏ���������
;=================================================
MMC_INIT:
	IN	A,(A8255+1)
	OR	00000100B
	OUT	(A8255+1),A
	LD	B,200
	CALL	MMC_CLK
	IN	A,(A8255+1)
	AND	11111011B
	OUT	(A8255+1),A
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

	DJNZ	MMC_READ
	RET

;=================================================
;[MMC]12�N���b�N�̃E�F�C�g�}��
;=================================================
MMC_WAIT:
	NOP
	NOP
	NOP
	RET

MSG_NOT_FOUND:	DB	"NOT FOUND",CR,LF,EOL

FILE_BFFR:	DS	200H			;�t�@�C���o�b�t�@

TIMEOUT:	DS	01H			;MMC�^�C���A�E�g�J�E���^
MMCADR0:	DS	01H			;MMC�A�h���X LSB
MMCADR1:	DS	01H			;
MMCADR2:	DS	01H			;
MMCADR3:	DS	01H			;MMC�A�h���X MSB

BPB:		DS	13H			;BPB�ۑ��G���A
PP_SCTR:	DS	04H			;�v���C�}���p�[�e�B�V�����̊J�n�Z�N�^��
ROOT_SCTR_SIZE:	DS	01H			;���[�g�f�B���N�g���̑��Z�N�^��
FAT_SCTR:	DS	04H			;FAT�̊J�n�Z�N�^�� BPB+3���R�s�[����DWORD������
ROOT_SCTR:	DS	04H			;���[�g�f�B���N�g���̊J�n�Z�N�^��
DATA_SCTR:	DS	04H			;�f�[�^�G���A�̊J�n�Z�N�^��

DWA:		DS	04H			;�ėp�_�u�����[�h�ϐ�
DW0:		DS	04H			;�_�u�����[�h�ϐ�
DW1:		DS	04H			;�_�u�����[�h�ϐ�
DW_SP_ORG:	DS	02H			;�_�u�����[�h�p�X�^�b�N�|�C���^�̈ꎞ�ޔ��G���A
DW_SP:		DS	02H			;�_�u�����[�h�p�X�^�b�N�|�C���^
		DS	10H			;�_�u�����[�h�p�X�^�b�N�G���A
DW_STACK	EQU	$			;
