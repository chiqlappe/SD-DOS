
;=================================================
;[STR]".",".."������̔���
;IN  HL=TP
;OUT (DIR_ENTRY)
;�E������"."���邢��".."�̏ꍇ�ɂ̂�(DIR_ENTRY)�ɃZ�b�g�����
;=================================================
IS_DOT:
	PUSH	HL				;TP�ޔ�
	LD	B,DNAME_SIZE			;B<-�t�@�C�����S�̂̒���
	LD	A,(HL)				;A<-�擪�̕���
	CP	"."				;
	JR	NZ,.EXIT			;"."�łȂ���ΏI��
	CALL	SFN_ADD_STR			;�f�B���N�g���G���g���o�b�t�@�ɃZ�b�g
	DEC	B				;=�c��̕�����
	LD	A,(HL)				;
	CP	"."				;
	JR	NZ,.L2				;"."
	CALL	SFN_ADD_STR			;".."
	DEC	B				;
	LD	A,(HL)				;
.L2:	CALL	IS_EOT				;"."�̌�ɕ�������������G���[
	JR	Z,.L1				;
	LD	E,ILLEGAL_FUNCTION_CALL		;
	JP	ERROR				;

.L1:	CALL	SFN_ADD_SPC			;B�̐������o�͐�ɋ󔒂�������
	POP	BC				;�ޔ����Ă���TP���̂Ă�
	POP	BC				;CALL�̖߂����̂Ă�
	RET					;

.EXIT:	POP	HL				;TP���A
	RET					;

;=================================================
;[STR]�������8.3�`���t�@�C�����ɕϊ�����
;IN  HL=TP
;OUT (DNAME+1)=8.3�`���t�@�C����,HL=������̃|�C���^
;�E�ŏ��Ɍ��ꂽ�s���I�h�́A(8-n)�̋󔒂ɒu��������
;�E�Q�Ԗڈȍ~�̃s���I�h�͖���
;=================================================
STR2SFN:
	LD	DE,DNAME			;DE<-������̏o�͐�
	EX	DE,HL				;�o�͐�̒��g��NULL�ɂ���
	CALL	NULL_STR			;
	EX	DE,HL				;
	CALL	IS_DOT				;"..","."�̔���
	XOR	A				;A'=�������J�E���^
	EX	AF,AF'				;A'<-0
	LD	B,08H				;��������t�@�C������
.L1:	LD	A,(HL)				;A<-(TP)
	CALL	IS_EOT				;��d���p����00H�Ȃ�
	JR	Z,.L7				;�c��̃t�@�C��������20H�Ŗ��߂� �I�g���q��͕��ł����p���邽��HL�͓������Ȃ��I
	CP	"."				;�s���I�h�Ȃ�IHL��i�߂āI�c��̃t�@�C��������20H�Ŗ��߂�
	JR	NZ,.L4				;����ȊO�Ȃ當����(DNAME)�ɕ���A��������
	INC	HL				;TP++
.L7:	CALL	SFN_ADD_SPC			;B�̐������o�͐�ɋ󔒂�������
	JR	.L2				;

.L4:	CALL	SFN_ADD_STR			;(DNAME)�ɕ���A��������
	CALL	.COUNT				;������A'++
	DJNZ	.L1				;
.L2:	LD	B,03H				;��������g���q��
.L3:	LD	A,(HL)				;A<-(TP)
	CALL	IS_EOT				;
	JR	NZ,.L5				;��d���p����00H�Ȃ�
	CALL	SFN_ADD_SPC			;B�̐������o�͐�ɋ󔒂�������
	JR	.EXIT				;�I����

.L5:	CP	"."				;�I�d�v�I�g���q���Ƀs���I�h������ΑS�ăX�L�b�v����
	JR	NZ,.L6				;
	INC	HL				;TP++
	JR	.L3				;
.L6:	CALL	SFN_ADD_STR			;(DNAME)�ɕ���A��������
	CALL	.COUNT				;������A'++
	DJNZ	.L3				;
	LD	A,(HL)				;�t�@�C�����̍ő啶�����𒴂��ē��͂��Ă�����G���[�ɂ���
	CALL	IS_EOT				;
	JR	Z,.EXIT				;
	LD	E,ILLEGAL_FUNCTION_CALL		;
	JP	ERROR				;

.EXIT:	EX	AF,AF'				;A'=�������J�E���^
	OR	A				;�o�͂��ꂽ������̕��������O�Ȃ�G���[
	RET	NZ				;
	LD	HL,MSG_NO_NAME			;
	JP	ERR				;

.COUNT:	EX	AF,AF'				;�������J�E���^++
	INC	A				;
	EX	AF,AF'				;
	RET					;

;=================================================
;[STR]�t�@�C�����p������ɂP�����ǉ�����
;IN  A=�����R�[�h,HL=TP,DE=�o�͐�̃|�C���^
;=================================================
SFN_ADD_STR:
	CALL	FIX_CHR				;�����R�[�h���C��
	CALL	IS_NGCHR			;�g�p�ł��Ȃ����������o
	LD	C,A				;
	EX	DE,HL				;
	CALL	ADD_STR				;�o�͐�ɕ�����������
	EX	DE,HL				;
	INC	DE				;�o�͐�̃|�C���^��i�߂�
	INC	HL				;�e�L�X�g�|�C���^��i�߂�
	RET					;

;=================================================
;[STR]�t�@�C�����p������ɋ󔒂��w�萔�����ǉ�����
;IN  B=�ǉ����鐔,HL=TP,DE=�o�͐�̃|�C���^
;=================================================
SFN_ADD_SPC:
	LD	C,SPC				;
	EX	DE,HL				;HL=�o�͐�̃|�C���^,DE=TP
.L1:	CALL	ADD_STR				;(DEST)+=20H
	INC	HL				;�o�͐�̃|�C���^��i�߂�
	DJNZ	.L1				;
	EX	DE,HL				;HL=TP,DE=�o�͐�̃|�C���^
	RET					;

;=================================================
;[STR]�啶������"^"->"~"�̏C��
;IN  A=�����R�[�h
;OUT A=�C�����ꂽ�����R�[�h
;=================================================
FIX_CHR:
	CALL	CAPITAL				;�啶����
	CP	"^"				;"^"���A�L�[�{�[�h������͂ł��Ȃ�����"~"�ɕϊ�����
	RET	NZ				;
	LD	A,"~"				;
	RET					;

;=================================================
;[STR]�G���g�����Ɏg�p�ł��Ȃ������`�F�b�N
;IN  A=�Ώۂ̕���
;OUT Z=1:NG�����ƈ�v����
;=================================================
IS_NGCHR:
	PUSH	BC				;
	PUSH	HL				;
	LD	HL,NG_CHR			;
	LD	BC,NG_CHR_END - NG_CHR		;BC<-NG_CHR�̑�������
	CPIR					;
	JR	Z,.ERR				;
	POP	HL				;
	POP	BC				;
	RET					;

.ERR:	LD	HL,MSG_NG_CHR			;
	JP	ERR				;

;=================================================
;[STR]��d���p����00H�̃`�F�b�N �����̕������͂Ɏg�p�����
;IN  A=�����R�[�h
;OUT Z=1:������I��
;=================================================
IS_EOT:	CP	DQUOTE				;A����d���p���܂���0�Ȃ�Z<-1
	RET	Z				;
	OR	A				;
	RET					;

;=================================================
;[STR]�w�肳�ꂽ�Œ蒷������S�̂𕶎��Ŗ��߂�
;IN  HL=�Œ蒷������̃|�C���^,C=�����R�[�h
;OUT
;=================================================
NULL_STR:
	LD	C,00H				;
FILL_STR:
	PUSH	BC				;
	PUSH	HL				;
	LD	B,(HL)				;
	INC	HL				;
.L1:	LD	(HL),C				;
	INC	HL				;
	DJNZ	.L1				;
	POP	HL				;
	POP	BC				;
	RET					;

;=================================================
;[STR]�Œ蒷������̍ŏ���NULL�����𕶎��Œu��������
;NULL�����������ꍇ�͖��������
;IN  HL=�����ϐ��̃|�C���^,C=�ǉ����镶���R�[�h
;OUT�@
;=================================================
ADD_STR:
	PUSH	BC				;
	PUSH	HL				;
	LD	B,(HL)				;B<-������
.L2:	INC	HL				;
	LD	A,(HL)				;�|�C���^�������l��00H�Ȃ�A���̈ʒu��C���Z�b�g����
	OR	A				;����ȊO�Ȃ�00H��������܂ŌJ��Ԃ�
	JR	NZ,.L3				;
	LD	(HL),C				;
	JR	.EXIT				;
.L3:	DJNZ	.L2				;
.EXIT:	POP	HL				;
	POP	BC				;
	RET					;

