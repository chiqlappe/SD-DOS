
;=============================
;���ʃ��x��
;=============================

FALSE			EQU	00H
TRUE			EQU	!FALSE
EOL			EQU	00H

;=============================
;��p���x��
;=============================

USE_VIRTUAL_LED		EQU	TRUE		;MMC�h���C�o�p
USE_VIRTUAL_SOUND	EQU	TRUE		;
SHOW_DATE		EQU	FALSE		;FILES�œ�����\������

CLSTR_STACK_SIZE	EQU	10H		;[CD.ASM]�N���X�^�X�^�b�N�T�C�Y

IDX_PP_SCTR		EQU	01C6H		;[FS.ASM]�v���C�}���p�[�e�B�V�����J�n�Z�N�^���ւ̃C���f�b�N�X�l
IDX_BPB			EQU	000BH		;[FS.ASM]BPB�̈�ւ̃C���f�b�N�X�l

SCTR_SIZE		EQU	200H		;�Z�N�^�T�C�Y
DENT_PER_SCTR		EQU	10H		;�P�Z�N�^������̃f�B���N�g���G���g����
MIN_CLSTR		EQU	 0002H		;�N���X�^���̍ŏ��l
MAX_CLSTR		EQU	0FFF6H		;�N���X�^���̍ő�l�i���_�l�j

DNAME_SIZE		EQU	0BH		;�f�B���N�g���G���g�����̃T�C�Y 8+3=11
DENT_SIZE		EQU	20H		;�f�B���N�g���G���g���S�̂̃T�C�Y

ROOT			EQU	0000H		;���[�g�f�B���N�g���̃N���X�^�� ���ۂ̃N���X�^���ł͂Ȃ��P�Ȃ鎯�ʗpID

IDX_NAME		EQU	00H		;�f�B���N�g�����̃I�t�Z�b�g�l ���O �P�P�o�C�g�i�g���q�����܂ށj
IDX_EXT			EQU	08H		;�f�B���N�g�����̃I�t�Z�b�g�l �g���q �R�o�C�g
IDX_ATRB		EQU	0BH		;�f�B���N�g�����̃I�t�Z�b�g�l �����l �P�o�C�g
IDX_CTIME		EQU	0EH		;�f�B���N�g�����̃I�t�Z�b�g�l �쐬���� �Q�o�C�g
IDX_CDATE		EQU	10H		;�f�B���N�g�����̃I�t�Z�b�g�l �쐬��   �Q�o�C�g
IDX_ADATE		EQU	12H		;�f�B���N�g�����̃I�t�Z�b�g�l �A�N�Z�X�� �Q�o�C�g
IDX_TIME		EQU	16H		;�f�B���N�g�����̃I�t�Z�b�g�l �X�V���� �Q�o�C�g
IDX_DATE		EQU	18H		;�f�B���N�g�����̃I�t�Z�b�g�l �X�V��   �Q�o�C�g
IDX_FAT			EQU	1AH		;�f�B���N�g�����̃I�t�Z�b�g�l FAT�G���g���ԍ� �Q�o�C�g
IDX_SIZE		EQU	1CH		;�f�B���N�g�����̃I�t�Z�b�g�l �t�@�C���T�C�Y  �S�o�C�g

IDX_BADR		EQU	04H		;�o�b�t�@���̃I�t�Z�b�g�l �o�b�t�@�̐擪�A�h���X �Q�o�C�g
IDX_BUPD		EQU	06H		;�o�b�t�@���̃I�t�Z�b�g�l �X�V�t���O �P�o�C�g

SEPARATOR		EQU	"/"
ATRB_DIR		EQU	10H		;�f�B���N�g���G���g���̑����l
ATRB_FILE		EQU	20H		;
ID_DISABLED		EQU	0E5H		;���������ꂽ�f�B���N�g���G���g���̔F���R�[�h

ATRB_SIZE		EQU	06H		;�t�@�C������������̃T�C�Y

;WORK_AREA		EQU	07B00H		;���[�N�G���A
STR_BUFF		EQU	0FF3DH		;������o�b�t�@ ~0FF9CH
STR_BUFF_SIZE		EQU	50H		;������o�b�t�@�̃T�C�Y�i�I���R�[�h�P�������܂ށj

;STACK_AREA		EQU	0FFFFH
CB_BYTES		EQU	0200H		;�R�[���o�b�N�Ԋu�̃o�C�g�� 512�o�C�g=1�Z�N�^�T�C�Y