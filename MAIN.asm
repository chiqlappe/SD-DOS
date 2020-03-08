
;=================================================
;PC-8001 SD-SYSTEM
;=================================================

;�E�v�]�A�s��񍐂�Twitter @chiqlappe���ɂ��肢���܂��B


INCLUDE "LABELS.ASM"
INCLUDE	"N80.ASM"

DEBUG	EQU	FALSE				;

	ORG	06000H

	DB	"AB"				;�����N���p�}�[�J�[

if DEBUG
	CALL	INIT_DEBUG			;�f�o�b�O���[�`��������
endif

	CALL	INIT_FAT16			;FAT16�֘A���[�N������
	CALL	INIT_DW				;�_�u�����[�h�p�X�^�b�N������
	CALL	INIT_CMDHOOK			;�R�}���h�t�b�N��������
	CALL	INIT_FKEY			;�t�@���N�V�����L�[�ݒ�ύX
	CALL	INIT_BASIC			;BASIC������
	CALL	CMD_ON				;�C���t�H���[�V�����X�C�b�`

	LD	HL,MSG_TITLE			;�^�C�g���\��
	CALL	PRINT				;
	RET					;

;=================================================
;BASIC������
;=================================================
INIT_BASIC:
	LD	HL,0EF58H			;�X�g�����O�f�B�X�N���v�^������
	LD	(0EF56H),HL			;
	LD	HL,8021H			;
	LD	(BASBEGIN),HL			;BASIC�擪�A�h���X
	INC	HL				;
	INC	HL				;
	LD	(VARBEGIN),HL			;�ϐ��擪�A�h���X
	INC	HL				;
	INC	HL				;
	LD	(ARRBEGIN),HL			;�z��擪�A�h���X
	INC	HL				;
	INC	HL				;
	LD	(FREBEGIN),HL			;�t���[�G���A�擪�A�h���X
	RET					;

;=================================================
;�t�@���N�V�����L�[�o�^
;=================================================
INIT_FKEY:
	LD	HL,FKEYDATA			;
	LD	DE,.DATA			;
	LD	C,03H				;
.L2:	LD	B,05H				;
.L1:	LD	A,(DE)				;
	LD	(HL),A				;
	INC	HL				;
	INC	DE				;
	DJNZ	.L1				;
	CALL	.L3				;
	DEC	C				;
	JR	NZ,.L2				;
	RET					;

.L3:	PUSH	BC				;
	XOR	A				;
	LD	B,11				;
.L4:	LD	(HL),A				;
	INC	HL				;
	DJNZ	.L4				;
	POP	BC				;
	RET					;

.DATA:	DB	"mount"				;F1
	DB	"load "				;F2
	DB	"files"				;F3

;=================================================
;�R�}���h�t�b�N�̏�������
;=================================================
INIT_CMDHOOK:
	LD	HL,FILES			;�t�@�C���ꗗ��\������
	LD	(ENT_FILES),HL			;
	LD	HL,LOAD				;�t�@�C�������[�h����
	LD	(ENT_LOAD),HL			;
	LD	HL,MOUNT			;SDC���}�E���g����
	LD	(ENT_MOUNT),HL			;
	LD	HL,SAVE				;�t�@�C�����Z�[�u����
	LD	(ENT_SAVE),HL			;
	LD	HL,CMD				;�ėp�R�}���h
	LD	(ENT_CMD),HL			;
	LD	HL,KILL				;�t�@�C�����폜����
	LD	(ENT_KILL),HL			;
	LD	HL,POLL				;���[�L���O�f�B���N�g����ύX����
	LD	(ENT_POLL),HL			;
	LD	HL,MERGE			;CMT�t�@�C���Ƀv���O������ǋL����
	LD	(ENT_MERGE),HL			;
	LD	HL,NAME				;�t�@�C������ύX����
	LD	(ENT_NAME),HL			;

	LD	HL,RBYTE			;�C�ӂ̃t�@�C�������[�h����
	LD	(ENT_RBYTE),HL			;

	RET					;

;=================================================
;�C���N���[�h�t�@�C��
;=================================================

if DEBUG
INCLUDE "DEBUG.asm"				;�f�o�b�O�p�c�[��
endif

INCLUDE	"MMC.asm"				;MMC�h���C�o
INCLUDE	"FAT.asm"				;FAT
INCLUDE	"BUFFER.asm"				;�o�b�t�@
INCLUDE	"CD.asm"				;�f�B���N�g���ύX
INCLUDE	"DIR.asm"				;�f�B���N�g���G���g��
INCLUDE	"FS.asm"				;�t�@�C���V�X�e��
INCLUDE	"SUBS.asm"				;�ėp�T�u���[�`��
INCLUDE	"DWORD.asm"				;�_�u�����[�h
INCLUDE	"FP.asm"				;�t�@�C���|�C���^
INCLUDE	"TP.asm"				;�e�L�X�g�|�C���^
INCLUDE	"CMT.asm"				;CMT�t�@�C���֘A
INCLUDE	"BIN.asm"				;BIN�t�@�C���֘A
INCLUDE	"BAS.asm"				;BAS�t�@�C���֘A
INCLUDE	"RAW.asm"				;�C�Ӄt�@�C���֘A
INCLUDE	"DATE.asm"				;����
INCLUDE	"DUMP.asm"				;�_���v�\��
INCLUDE	"CMD.asm"				;�R�}���h
INCLUDE	"STR.asm"				;�����񏈗�
INCLUDE "MESSAGES.asm"				;���b�Z�[�W������
INCLUDE	"ERROR.asm"				;�G���[����

;=================================================
;�Œ�f�[�^
;=================================================

FAT_CODE:
	DB	"FAT16   "			;FAT���ʃR�[�h

NG_CHR:
	DB	";" , "[" , "]" , ":" , DQUOTE	;�G���g�����Ɏg�p�ł��Ȃ�����
	DB	";" , "|" , "=" , "," , "\"	;
	DB	" " , "/"			;
NG_CHR_END	EQU	$			;


CMD_TABLE:
	DB	"F",EOL				;CMD F �t���[�G���A�g��
	DB	95H,EOL				;CMD ON �C���t�H���[�V�����X�C�b�` �I�� 95H="ON"�̒��Ԍ���R�[�h
	DB	"OFF",EOL			;CMD OFF �C���t�H���[�V�����X�C�b�` �I�t
	DB	"P",EOL				;CMD P �v���p�e�B�\��
	DB	"R",EOL				;CMD R �t�@�C�����s
	DB	"V",EOL				;CMD V �`�F�b�N�T���Z�o
	DB	"CP",EOL			;CMD CP �t�@�C���R�s�[
	DB	"D",EOL				;CMD D �Z�N�^�_���v
	DB	"EX",EOL			;CMD EX �T�u�f�B���N�g���g��
	DB	"MD",EOL			;CMD MD �T�u�f�B���N�g���쐬
	DB	"S",EOL				;CMD S �f�B���N�g���G���g�����ŃZ�N�^�_���v
	DB	EOL				;END MARKER

JUMP_TABLE:
	DW	CMD_F				;
	DW	CMD_ON				;
	DW	CMD_OFF				;
	DW	CMD_P				;
	DW	CMD_R				;
	DW	CMD_V				;
JT_CP:	DW	DISKB_ERR			;
JT_D:	DW	DISKB_ERR			;
JT_EX:	DW	DISKB_ERR			;
JT_MD:	DW	DISKB_ERR			;
JT_S:	DW	DISKB_ERR			;

EXT_LOAD_TABLE:					;�t�@�C���ǂݍ��ݗp�T�u���[�`���e�[�u��
						;�E�g���q 3BYTE,�W�����v��A�h���X 2BYTE
	DB	"CMT"				;
	DW	READ_CMT			;
	DB	"BIN"				;
	DW	READ_BIN			;
	DB	"BAS"				;
	DW	READ_BAS			;
	DB	EOL				;

EXT_SAVE_TABLE:					;�t�@�C���������ݗp�T�u���[�`���e�[�u��
						;�E�g���q 3BYTE,�W�����v��A�h���X 2BYTE
	DB	"CMT"				;
	DW	WRITE_CMT			;
	DB	"BIN"				;
	DW	WRITE_BIN			;
	DB	"BAS"				;
	DW	WRITE_BAS			;
	DB	EOL				;

;DEFAULT_EXT:					;
;	DB	"CMT"				;

;=================================================
;���[�N�G���A
;=================================================

WORK_AREA:

FAT_BFFR:	DS	200H			;FAT�o�b�t�@
FILE_BFFR:	DS	200H			;�t�@�C���o�b�t�@

ARG0:		DS	02H			;�R�}���h�̓��̓p�����[�^
ARG1:		DS	02H			;
ARG2:		DS	02H			;
ARG3:		DS	02H			;
ARGNUM:		DS	01H			;�L���ȓ��̓p�����[�^�̐� 0~3

EXECFLG:	DS	01H			;���[�h����s�t���O
EXECADR:	DS	02H			;���[�h����s�A�h���X

FAT1_BFFR_STRCT:				;�o�b�t�@�\���́iFAT�p�j
	.SCTR:	DS	04H			;+00 �Z�N�^��
	.BP:	DS	02H			;+04 �o�b�t�@�|�C���^
	.FLG:	DS	01H			;+06 �X�V�t���O
FAT2_BFFR_STRCT:				;�o�b�t�@�\���́iFAT2�p�j
	.SCTR:	DS	04H			;+00 �Z�N�^��
	.BP:	DS	02H			;+04 �o�b�t�@�|�C���^
	.FLG:	DS	01H			;+06 �X�V�t���O
FILE_BFFR_STRCT:				;�o�b�t�@�\���́i�t�@�C���A�f�B���N�g�����p�j
	.SCTR:	DS	04H			;+00 �Z�N�^��
	.BP:	DS	02H			;+04 �o�b�t�@�|�C���^
	.FLG:	DS	01H			;+06 �X�V�t���O

DNAME:		DS	01H			;DNAME�̕������w�蕔 �IDIR_ENTRY�̒��O�ɒu�����ƁI
DIR_ENTRY:	DS	20H			;+00 �f�B���N�g���G���g�����
DIR_ENTRY.SCTR:	DS	04H			;+32 ���^��̃Z�N�^��
DIR_ENTRY.BP:	DS	02H			;+36 �o�b�t�@�|�C���^

FOUND:		DS	01H			;�w�肳�ꂽ�f�B���N�g���G���g��������������TRUE�ɂȂ�
BPB:		DS	13H			;BPB�ۑ��G���A
PP_SCTR:	DS	04H			;�v���C�}���p�[�e�B�V�����̊J�n�Z�N�^��
ROOT_SCTR_SIZE:	DS	01H			;���[�g�f�B���N�g���̑��Z�N�^��
FAT_SCTR:	DS	04H			;FAT�̊J�n�Z�N�^�� BPB+3���R�s�[����DWORD������
ROOT_SCTR:	DS	04H			;���[�g�f�B���N�g���̊J�n�Z�N�^��
DATA_SCTR:	DS	04H			;�f�[�^�G���A�̊J�n�Z�N�^��

WDIR_CLSTR:	DS	02H			;���[�L���O�f�B���N�g���̊J�n�N���X�^��
WDIR_ORG:	DS	02H			;���[�L���O�f�B���N�g���̊J�n�N���X�^���ޔ�p
TGT_CLSTR:	DS	02H			;�^�[�Q�b�g�i�t�@�C���܂��̓T�u�f�B���N�g���j�̊J�n�N���X�^��

FP:		DS	04H			;�t�@�C���|�C���^
FP_CLSTR:	DS	02H			;FP�ƌ��т��t�@�C���̃J�����g�N���X�^���BFP�ƘA�����ĕω�����
FP_CLSTR_SN:	DS	02H			;FP�������A�h���X���A�擪���牽�Ԗڂ̃N���X�^�Ɋ܂܂�邩�������I�N���X�^���ł͂Ȃ��I
FP_SCTR_SN:	DS	01H			;FP�������A�h���X���A�N���X�^���̉��Ԗڂ̃Z�N�^�Ɋ܂܂�邩�������I�Z�N�^���ł͂Ȃ��I

ATRB:		DS	01H			;�t�@�C�������\���p������̕������w�蕔
		DS	06H			;�t�@�C�������\���p������{��

FIREWALL:	DS	02H			;�}�V���ꂪ���̃A�h���X����ɐN�����Ȃ��悤�ɂ���

TIMEOUT:	DS	01H			;MMC�^�C���A�E�g�J�E���^
MMCADR0:	DS	01H			;MMC�A�h���X LSB
MMCADR1:	DS	01H			;
MMCADR2:	DS	01H			;
MMCADR3:	DS	01H			;MMC�A�h���X MSB

DWA:		DS	04H			;�ėp�_�u�����[�h�ϐ�
DW0:		DS	04H			;�_�u�����[�h�ϐ�
DW1:		DS	04H			;�_�u�����[�h�ϐ�
DW_SP_ORG:	DS	02H			;�_�u�����[�h�p�X�^�b�N�|�C���^�̈ꎞ�ޔ��G���A
DW_SP:		DS	02H			;�_�u�����[�h�p�X�^�b�N�|�C���^
		DS	10H			;�_�u�����[�h�p�X�^�b�N�G���A
DW_STACK	EQU	$			;

CP_SCTR:	DS	04H			;�R�s�[��Z�N�^��
CP_DENT:	DS	20H			;�R�s�[��f�B���N�g���G���g��
CP_DENT.SCTR:	DS	04H			;�R�s�[��f�B���N�g���G���g���̃Z�N�^��
CP_DENT.BP:	DS	02H			;�R�s�[��f�B���N�g���G���g���̃o�b�t�@�|�C���^

CHECKSUM:	DS	02H			;�`�F�b�N�T���p
INFO_SW:	DS	01H			;�C���t�H���[�V�����\�����[�h
IS_CALLBACK:	DS	01H			;�R�[���o�b�N���s�t���O
CALLBACK:	DS	02H			;�R�[���o�b�N�A�h���X

INFO_BUF:	DS	10H			;���o�͗p������o�b�t�@

FREE_AREA	EQU	$			;�t���[�G���A�J�n�A�h���X


;-----------------------------

;BPB���狁�߂���l
SCTRS_PER_CLSTR	EQU	BPB+2			;�P�N���X�^������̃Z�N�^��	  40H
FAT_START	EQU	BPB+3			;FAT�J�n�Z�N�^��		0008H
ROOT_SIZE	EQU	BPB+6			;�����[�g�f�B���N�g����		0200H
FAT_SIZE	EQU	BPB+11			;FAT�P�ʂɕK�v�ȃZ�N�^��	00F0H


;-----------------------------

INCLUDE	"EXT.asm"				;�g�����ߌQ

