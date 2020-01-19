
;�o�T	PC-Techknow8000�i�V�X�e���\�t�g�j
;	PC-8001�}�V���ꊈ�p�n���h�u�b�N �����ҁi�G�a�V�X�e���g���[�f�B���O������Ёj

;-----------------------------
;ASCII �萔
;-----------------------------
BEL		EQU	07H
BS		EQU	08H
LF		EQU	0AH
CL		EQU	0CH
CR		EQU	0DH
SPC		EQU	20H
DQUOTE		EQU	22H
SQUOTE		EQU	27H

;-----------------------------
;PC-8001�V�X�e���R�[��
;-----------------------------

;0000H
WARMBOOT	EQU	06AH	;�z�b�g�X�^�[�g
BASIC		EQU	081H	;BASIC�֖߂�
PUTCH		EQU	0257H	;A���W�X�^��ASCII�o�� (-)
BEEP		EQU	0350H	;BEEP��炷 (A,F,E,H,L)
LOCATE		EQU	03A9H	;LOCATE(H,L)
CLRLN		EQU	0451H	;�P�s����(A,F,B,C,D,E,F,H,L)
CLS		EQU	045AH	;��ʏ���
WIDTH		EQU	0843H	;WIDTH���� HL�Ƀp�����[�^�̃|�C���^�����ăR�[������ "WIDTH 80,25" = 38H,30H,2CH,32H,35H,00H
WIDTH_X		EQU	09A3H	;WIDTH���� A<-������
WIDTH_Y		EQU	09D7H	;WIDTH���� A<-�c����
CURSOFF		EQU	0BD2H	;�J�[�\������
CURSON		EQU	0BE2H	;�J�[�\���\��
ISBRK		EQU	0CF1H	;STOP,ESC�L�[������CY<-1 �񉟉���Z<-1
KEYWAIT		EQU	0F75H	;�P�������͑҂� A<-CODE (A,F)

;1000H
TIME_READ	EQU	01602H	;�^�C�}IC�̓����������[�N�ɏ�������
TIME_WRT	EQU	01663H	;���[�N�̓��������^�C�}IC�ɏ�������
SETFREADR	EQU	017E9H	;�t���[�G���A�̊J�n�A�h���X��HL�ɃZ�b�g����
DISKB_ERR	EQU	01875H	;Disk Basic Feature �G���[
SCRNEDIT	EQU	01B7EH	;�X�N���[���ҏW���s KEYBUF�ɓ��͕����� STOP�L�[�ɂ�钆�f��CY<-1 (ALL)

;2000H
PRTHLDEC	EQU	02D13H	;HL���W�X�^�̒l��10�i���ŏo�͂��� 0�}�~

;3000H
CNVFACDEC	EQU	0309FH	;16�r�b�g10�i������ϊ� FAC��(HL)�ȍ~�ɕ�����Ŋi�[����
ERROR		EQU	03BF9H	;�G���[�o�� E<-�G���[�R�[�h
PRGFIT		EQU	03D76H	;BASIC�v���O�����̃A�h���X�����̔Ԓn�Ƀt�B�b�g������
NEW		EQU	03DE0H	;NEW
RUN		EQU	03DF4H	;RUN
INPUT		EQU	03E5CH	;=INPUT KEYBUF�ɓ��͕�����+0 HL<-KEYBUF-1

;4000H
TPSEEK		EQU	0409BH	;���̕�����������܂ŃX�g�����O�|�C���^��i�߂� ������Ȃ����Z<-1
CNVDECWORD	EQU	044C7H	;(HL)�ȍ~�Ɋi�[���ꂽ"0"~"65529"��10�i���������2�o�C�g�̐��l�ɕϊ�����DE�ɓ���� 
EVALEXP		EQU	04A8FH	;�X�g�����O�|�C���^�̎���]������FAC�ɓ����

;5000H
PRINT		EQU 	052EDH	;(HL)�ȍ~�Ɋi�[���ꂽ��������o�͂��� (ALL)
BYTE_EVALEXP	EQU	056FAH	;�X�g�����O�|�C���^�̎���]������A�ɓ����

FAC2INT		EQU	0592AH	;HL<-INT(FAC)
MON		EQU	05C66H	;���j�^���A
GETADRS		EQU	05E21H	;�L�[�{�[�h����4����16�i����͂���HL�Ɋi�[����
CNVBYTEHEX	EQU	05E83H	;1�o�C�g�̐��l��2�o�C�g��16�i������ɕϊ� A->D,E
RNUM2RAD	EQU	05B85H	;�s�ԍ����s�A�h���X
RAD2RNUM	EQU	05B86H	;�s�A�h���X���s�ԍ��BBASIC�ۑ��O�Ɏ��s����
CNVHEXBYTE	EQU	05EA0H	;2�o�C�g��16�i�������1�o�C�g�̐��l�ɕϊ� D,E->A
PRTHLHEX	EQU	05EC0H	;HL���W�X�^�̒l��4����16�i���ŏo�͂��� (A)
PRTAHEX		EQU	05EC5H	;A���W�X�^�̒l��2����16�i���ŏo�͂��� (A)
CPHLDE		EQU	05ED3H	;�y�A���W�X�^��r HL-DE (-)
CAPITAL		EQU	05FC1H	;�啶����
PUT_CR		EQU 	05FCAH	;���s�o�� (A)
PUT_SPC		EQU	05FD4H	;�X�y�[�X�o��


;-----------------------------
;PC-8001���[�N�G���A
;-----------------------------
FKEY_FLAG	EQU	0EA68H	;�t�@���N�V�����L�[��������Ă����1�ɂȂ�
DT_SEC		EQU	0EA76H	;�b BCD�`�� "CALL TIME_READ"���K�v
DT_MIN		EQU	0EA77H	;��
DT_HOUR		EQU	0EA78H	;��
DT_DAY		EQU	0EA79H	;��
DT_MONTH	EQU	0EA7AH	;��
DT_YEAR		EQU	0EA7BH	;�N
FKEYDATA	EQU	0EA7CH	;�t�@���N�V�����L�[�̓��e

FKEY_POINTER	EQU	0EAC0H	;���Z�b�g��ACTIVE_FKEY�ɃZ�b�g����Ă���A�h���X
STACK_BEGIN	EQU	0EB50H	;�X�^�b�N�̒�
EXECLINENUM	EQU	0EB52H	;���ݎ��s���̍s�ԍ� ��~����0FFFFH
BASBEGIN	EQU	0EB54H	;N-BASIC�̃v���O�����G���A�擪�A�h���X ~0EB55H (8021H)
KEYBUF		EQU	0EC96H	;�L�[���͂��ꂽ������̊i�[��
ACTIVE_FKEY	EQU	0EDC0H	;������Ă���t�@���N�V�����L�[�̃A�h���X
FREE_END	EQU	0EF54H	;�t���[�G���A�̍ŏI�A�h���X ~0EF55H (0E9FFH)
STR_BEGIN	EQU	0EF79H	;������t���[�X�y�[�X�擪�A�h���X ~0EF7AH
VARBEGIN	EQU	0EFA0H	;�ϐ��G���A�̐擪�A�h���X   ~0EFA1H ( 8023H)
ARRBEGIN	EQU	0EFA2H	;�z��G���A�̐擪�A�h���X   ~0EFA3H ( 8023H)
FREBEGIN	EQU	0EFA4H	;�t���[�G���A�̐擪�A�h���X ~0EFA5H ( 8023H)
SYSUNUSED	EQU	0F216H	;�V�X�e�����g�p�̈�	    ~0F2FFH 233�o�C�g
VRAM		EQU	0F300H	;VRAM�G���A                 ~0FEB7H
BOOTSTACK	EQU	0FF3DH	;���Z�b�g���̃X�^�b�N�G���A ~0FFFEH 193�o�C�g

RS232BF1	EQU	0EDCEH	;RS-232C CH1 �o�b�t�@       ~0EE4DH 128�o�C�g
RS232BF2	EQU	0EE4EH	;RS-232C CH2 �o�b�t�@       ~0EECDH 128�o�C�g
IEEEWK		EQU	0EED2H	;IEEE�p���[�N�G���A	    ~0EEF5H 35�o�C�g

ENT_CMD		EQU	0F0FDH	;�g�����߂̃G���g���A�h���X+1
ENT_TALK	EQU	0F10CH	;
ENT_POLL	EQU	0F115H	;
ENT_MERGE	EQU	0F13CH	;
ENT_KILL	EQU	0F142H	;
ENT_LOAD	EQU	0F139H	;
ENT_SAVE	EQU	0F14BH	;
ENT_FILES	EQU	0F14EH	;
ENT_MOUNT	EQU	0F154H	;
ENT_NAME	EQU	0F13FH	;
ENT_RBYTE	EQU	0F11BH	;

;-----------------------------
;�G���[�R�[�h
;-----------------------------
SYNTAX_ERROR		EQU	02H
ILLEGAL_FUNCTION_CALL	EQU	05H
OUT_OF_MEMORY		EQU	07H
STRING_TOO_LONG		EQU	0FH
UNPRINTABLE		EQU	15H
MISSING_OPERAND		EQU	16H
LINE_BFFR_OVERFLOW	EQU	17H
BAD_FILE_DATA		EQU	19H
;FILE_NOT_FOUND		EQU	35H
;FILE_ALREADY_EXISTS	EQU	3AH

