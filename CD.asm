
;=================================================
;[CD]�f�B���N�g���G���g���o�b�t�@�̃G���g�������[���N���A����
;=================================================
CLR_DNAME:
	PUSH	HL				;
	LD	HL,DNAME			;
	CALL	NULL_STR			;
	POP	HL				;
	RET

;=================================================
;[CD]�p�X������Ŏw�肳�ꂽ�f�B���N�g���ɁA���[�L���O�f�B���N�g�����ړ�����
;IN  (ARG0)=�p�X������̐擪�A�h���X
;OUT HL=�G���g�����̐擪�A�h���X,(WDIR_CLSTR)=�V�������[�L���O�f�B���N�g���̃N���X�^��,(WDIR_ORG)=���s�O���[�L���O�f�B���N�g���̃N���X�^��
;=================================================
CHANGE_WDIR:
	CALL	STORE_WDIR			;���[�L���O�f�B���N�g���̃N���X�^����ޔ�����
	LD	HL,(ARG0)			;HL<-�p�X������̐擪�A�h���X
	CALL	SPLIT_FPATH			;�p�X�ƃt�@�C������00H�ŕ�������
	RET	NC				;CY=1�Ȃ�p�X�������݂���̂ŁA�f�B���N�g�����ړ�����
	CALL	TRACE_PATH			;
	INC	HL				;HL�͕����_���w���Ă���̂ŁA�P�i�߂ăt�@�C�����̐擪�ɍ��킹��
	RET

;=================================================
;[CD]���[�L���O�f�B���N�g�����A(DIR_ENTRY)�Ɉ�v����T�u�f�B���N�g���Ɉړ�����
;IN  (DIR_ENTRY+IDX_NAME),(DIR_ENTRY+IDX_ATRB)
;OUT (WDIR_CLSTR)
;=================================================
ENTER_SUBDIR:
	PUSH	HL				;
	LD	A,(DIR_ENTRY+IDX_NAME)		;������̐擪��00H�Ȃ璆�g�͋�Ȃ̂ŏI������
	OR	A				;
	JR	Z,.EXIT				;
	LD	HL,DNAME			;
	CALL	EOL2SPC				;�G���g������00H�����ׂ�20H�ɕϊ�����
	LD	A,ATRB_DIR			;
	LD	(DIR_ENTRY+IDX_ATRB),A		;
	CALL	GET_DENT.MAIN			;
	JP	Z,ERR_NOT_FOUND			;
	LD	HL,(DIR_ENTRY+IDX_FAT)		;HL<-��v�����f�B���N�g���G���g���̃N���X�^��
.E1:	LD	(WDIR_CLSTR),HL			;(WDIR_CLSTR)<-�f�B���N�g���G���g���̃N���X�^��
.EXIT:	POP	HL				;
	RET					;

;=================================================
;[CD]���[�L���O�f�B���N�g�������[�g�f�B���N�g���Ɉړ�����
;=================================================
ENTER_ROOT:
	PUSH	HL
	LD	HL,ROOT
	JR	ENTER_SUBDIR.E1

;=================================================
;[CD]�p�X�t���t�@�C�������A�p�X���ƃt�@�C�������ɕ�������
;�E�� "/DIR/DIR/FILE.EXT" -> "/DIR/DIR",00H,"FILE.EXT"
;IN  HL=������̐擪�A�h���X
;OUT HL=������̐擪�A�h���X,CY=1:�p�X�ƃt�@�C�����𕪊�����
;=================================================
SPLIT_FPATH:
	PUSH	HL				;
	PUSH	HL				;������̐擪�A�h���X��ޔ�
.L1:	LD	A,(HL)				;HL�𕶎���̖���+1�܂Ői�߂�
	INC	HL				;
	CALL	IS_EOT				;
	JR	NZ,.L1				;
	DEC	HL				;HL<-�����A�h���X
	POP	DE				;DE<-�擪�A�h���X
	CALL	CPHLDE				;�����A�h���X:�擪�A�h���X
	JR	Z,.EXIT				;������̐擪�A�h���X�Ɩ����A�h���X�������Ȃ�߂�BCY<-0
	PUSH	HL				;������̖����A�h���X��ޔ�
	OR	A				;
	SBC	HL,DE				;HL<-�����A�h���X-�擪�A�h���X=������̒���-1
	INC	HL				;HL<-������̒���
	LD	B,H				;BC<-������̒���
	LD	C,L				;
	POP	HL				;HL<-������̖����A�h���X
	LD	A,"/"				;A<-�������镶��
	CPDR					;A:(HL),HL--,BC--
	JR	Z,.FOUND			;
	OR	A				;CY<-0
	JR	.EXIT				;

.FOUND:	XOR	A				;�����_�Ɏ��ʗp�R�[�h��}������
	INC	HL				;
	LD	(HL),A				;
	SCF					;CY<-1
.EXIT:	POP	HL				;
	RET					;

;=================================================
;[CD]�p�X������̐擪����00H�܂ł͈̔͂���͂��A�������[�L���O�f�B���N�g�����ړ�����
;IN  HL=�p�X������̐擪�A�h���X
;OUT (WDIR_CLSTR)=�p�X�����񂩂狁�߂�ꂽ�N���X�^��,HL=�G���g�����̊J�n�A�h���X-1
;=================================================
TRACE_PATH:
	LD	A,(HL)				;�I�d�v�I�ŏ��̕�����00H�Ȃ�u���[�g�v�Ɉړ����ďI��
	OR	A				;�Ⴆ��"/FILE.EXT" �� 00H,"FILE.EXT" �ƕϊ�����邽��
	JR	Z,ENTER_ROOT			;
	CP	"/"				;�ŏ��̕�����"/"�Ȃ�u���[�g�v�Ɉړ�
	JR	NZ,.L4				;
	CALL	ENTER_ROOT			;
	INC	HL				;
.L4:	CALL	CLR_DNAME			;�o�b�t�@�̃G���g������00H�ŃN���A
.L1:	LD	A,(HL)				;A��00H�܂���22H�Ȃ�
	CALL	IS_EOT				;
	JR	Z,ENTER_SUBDIR			;�o�b�t�@�Ɏc���Ă���f�B���N�g���Ɉړ����ďI��
	INC	HL				;��؂蕶�����o
	CP	"/"				;
	JR	NZ,.ADD				;
	CALL	ENTER_SUBDIR			;�f�B���N�g���ړ����s
	JR	.L4				;

.ADD:	PUSH	HL				;
	CALL	FIX_CHR				;�����R�[�h���C��
	CALL	IS_NGCHR			;�g�p�ł��Ȃ����������o
	LD	HL,DNAME			;
	LD	C,A				;
	CALL	ADD_STR				;�G���g�����ɕ�����ǉ�����
	POP	HL				;
	JR	.L1				;

;=================================================
;[CD]���[�L���O�f�B���N�g���̃N���X�^����ޔ�����
;IN  (WDIR_CLSTR)
;OUT (WDIR_ORG)
;=================================================
STORE_WDIR:
	LD	HL,(WDIR_CLSTR)			;
	LD	(WDIR_ORG),HL			;
	RET

;=================================================
;[CD]���[�L���O�f�B���N�g���̃N���X�^���𕜋A����
;IN  (WDIR_ORG)
;OUT (WDIR_CLSTR)
;=================================================
RESTORE_WDIR:
	LD	HL,(WDIR_ORG)			;
	LD	(WDIR_CLSTR),HL			;
	RET

;=================================================
;[STR]�������00H��20H�ɕϊ�����
;IN  HL=������̐擪�A�h���X
;OUT ������(HL)
;=================================================
EOL2SPC:
	LD	B,(HL)				;B<-������
	INC	HL				;
.L1:	LD	A,(HL)				;
	OR	A				;
	JR	NZ,.L2				;
	LD	(HL),SPC			;
.L2:	INC	HL				;
	DJNZ	.L1				;
	RET

