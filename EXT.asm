
;=================================================
;�g���R�}���h
;=================================================


	ORG	0C000H

INIT_EXT_CMD:
	LD	HL,CMD_D
	LD	(JT_D),HL
	LD	HL,CMD_S
	LD	(JT_S),HL
	LD	HL,CMD_CP
	LD	(JT_CP),HL
	LD	HL,CMD_MD
	LD	(JT_MD),HL
	LD	HL,CMD_EX
	LD	(JT_EX),HL

	CALL	IPRINT
	DB	"READY !",CR,LF,EOL

	JP	BASIC


;=================================================
;[CMD]CMD D���� "DUMP"
;�E�Z�N�^���͂W����16�i������Ŏw�肷��
; CMD D			���O�̃Z�N�^�����_���v
; CMD D "00000008"	�w�肳�ꂽ�Z�N�^�����_���v
; CMD D SC$
;=================================================
CMD_D:
	DEC	HL				;�e�L�X�g�|�C���^���P�߂�
	RST	10H				;
	OR	A				;
	JR	Z,.L2				;
	CALL	STR2BUFF			;
	PUSH	HL				;TP�ޔ�
	LD	HL,STR_BUFF			;
	LD	DE,DW0+03H			;DE<-�_�u�����[�h��MSB
	LD	B,04H				;B<-8�� / 2
.L1:	PUSH	DE				;
	LD	A,(HL)				;
	CALL	IS_HEX				;
	LD	D,A				;
	INC	HL				;
	LD	A,(HL)				;
	CALL	IS_HEX				;
	LD	E,A				;
	INC	HL				;
	CALL	CNVHEXBYTE			;A<-�����R�[�hD,E���o�C�i���ϊ������l
	POP	DE				;
	LD	(DE),A				;�_�u�����[�h(DW0)��MSB������l���Z�b�g���Ă���
	DEC	DE				;
	DJNZ	.L1				;
	JR	.L3

.L2:	PUSH	HL				;
.L3:	CALL	IS_FAT16			;
	CALL	DUMP_SCTR			;���C�����[�`��
	JP	CLOSE_CMD			;

;=================================================
;[DUMP]�Z�N�^���_���v�o�͂���
;IN  (DW0)=�Z�N�^��
;=================================================
DUMP_SCTR:
	CALL	IS_FAT16			;
	LD	A,80				;WIDTH 80,??
	CALL	WIDTH_X				;
	LD	IX,FILE_BFFR_STRCT		;=�t�@�C���o�b�t�@�\����
.L4:	CALL	LOAD_BFFR			;(DW0)�Z�N�^���t�@�C���o�b�t�@�ɓǂݍ���
	LD	HL,(FILE_BFFR_STRCT.BP)		;HL<-�t�@�C���o�b�t�@�̐擪�A�h���X
	LD	C,02H				;�P�Z�N�^�͂Q�y�[�W�\��
	LD	D,00H				;�I�t�Z�b�g�l�\���p�J�E���^
.L3:	CALL	.HEADER				;��ʏ����ƃZ�N�^���\��
	LD	B,10H				;=�s��
.L2:	PUSH	BC				;�s����ޔ�
	LD	A,D				;�I�t�Z�b�g�l��\��
	CALL	PRTAHEX				;
	CALL	IPRINT				;
	DB	"0 :",EOL			;
	INC	D				;�J�E���^++
	LD	B,10H				;=��
	PUSH	HL				;�o�b�t�@�̃A�h���X��ޔ�
.L1:	PUSH	BC				;�񐔂�ޔ�
	LD	A,(HL)				;A<-(�o�b�t�@)
	CALL	PRTAHEX				;16�i���ŕ\��
	CALL	PUT_SPC				;��
	INC	HL				;�A�h���X++
	POP	BC				;�񐔂𕜋A
	DJNZ	.L1				;B--
	CALL	PUT_SPC				;��
	LD	B,10H				;=��
	POP	HL				;�o�b�t�@�̃A�h���X�𕜋A
.L6:	PUSH	BC				;�񐔂�ޔ�
	LD	A,(HL)				;A<-(�o�b�t�@)
	CP	20H				;
	JR	NC,.L7				;
	LD	A,"."				;
.L7	RST	18H				;
	INC	HL				;
	POP	BC				;
	DJNZ	.L6				;B--
	CALL	PUT_CR				;���s
	POP	BC				;�s���𕜋A
	DJNZ	.L2				;B--
	CALL	KEYWAIT				;�P�������͑҂�
	CP	03H				;STOP
	RET	Z				;�I��
	CP	BS				;BACKSPACE
	JR	NZ,.L5				;
	DEC	C				;�Q�y�[�W�ڂȂ�P�y�[�W�ڂɖ߂�
	JR	Z,.L4				;
	CALL	DW0_DEC				;�Z�N�^��--
	JR	NC,.L4				;�L�����[�t���O�����Ă�00000000H�ɖ߂�
	CALL	DW0_INC				;
	JR	.L4				;

.L5:	DEC	C				;�y�[�W��--
	JR	NZ,.L3				;
	CALL	DW0_INC				;�Z�N�^��++
	JR	.L4				;

.HEADER:
	PUSH	BC				;
	PUSH	HL				;
	LD	A,0CH				;��ʏ���
	RST	18H				;
	CALL	IPRINT				;
	DB	"    :",EOL			;
	LD	BC,1000H			;B<-10H,C<-00H
.L10:	LD	A,"+"				;"+0 +1 ... +F "
	RST	18H				;
	LD	A,C				;
	CP	10				;
	JR	C,.L11				;
	ADD	A,07H				;
.L11:	ADD	A,"0"				;
	RST	18H				;
	CALL	PUT_SPC				;
	INC	C				;
	DJNZ	.L10				;
	CALL	IPRINT				;
	DB	" SECTOR=",EOL			;
	LD	HL,DW0				;�Z�N�^����\��
	CALL	PRT_DW_HEX			;
	CALL	PUT_CR				;
	POP	HL				;
	POP	BC				;
	RET					;


;=================================================
;[CMD]CMD S ���� "SOURCE"
; CMD S "FILE.EXT"	�t�@�C���̊J�n�Z�N�^���_���v
; CMD S "/"		���[�g�f�B���N�g���̊J�n�Z�N�^���_���v
; CMD S FN$
;=================================================
CMD_S:
	CALL	STR2ARG0			;
	PUSH	HL				;
	CALL	IS_FAT16			;
	CALL	CHANGE_WDIR			;
	LD	(ARG0),HL			;
	LD	A,(HL)				;
	CALL	IS_EOT				;�G���g�������󂩁H
	JR	NZ,.L1				;
	LD	HL,(WDIR_CLSTR)			;�G���g��������Ȃ烏�[�L���O�f�B���N�g���̃N���X�^�����g��
	CALL	GET_FIRST_SCTR			;
	JR	.L2				;

.L1:	LD	C,00H				;
	CALL	GET_DENT			;
	JP	Z,ERR_NOT_FOUND			;���݂��Ȃ���΃G���[
	LD	HL,(DIR_ENTRY+IDX_FAT)		;=��v�����t�@�C����FAT�G���g��
	LD	A,H				;FAT�G���g����0000H�Ȃ��t�@�C���Ȃ̂ŃG���[��
	OR	L				;
	JP	Z,ERR_EMPTY_FILE		;
	CALL	GET_FIRST_SCTR			;
.L2:	CALL	DUMP_SCTR			;���C�����[�`��
	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD


;=================================================
;[CMD]CMD CP ���� �t�@�C�����R�s�[����
; CMD CP "/DIR/FROM.EXT","/DIR/TO.EXT"
;=================================================
CMD_CP:
	CALL	GET_2STR_ARGS			;(ARG0)=�R�s�[��,(ARG1)=�R�s�[��
	PUSH	HL				;
	CALL	IS_FAT16			;
	LD	HL,DWA				;(DWA)<-�Z�N�^�T�C�Y
	LD	BC,0000H			;
	LD	DE,SCTR_SIZE			;
	CALL	DW_LD				;
	CALL	SWAP_ARGS			;(ARG0)<->(ARG1)
	LD	C,ATRB_FILE			;
	CALL	PREP_DENT			;
	CALL	IS_READ_ONLY			;
	LD	HL,DIR_ENTRY			;�f�B���N�g���G���g���o�b�t�@�̓��e���R�s�[�p�o�b�t�@�ɓ]������
	LD	DE,CP_DENT			;
	LD	BC,DENT_SIZE+06H		;�o�b�t�@�|�C���^�ƃZ�N�^�����܂߂�
	LDIR					;
	LD	HL,(TGT_CLSTR)			;HL<-�R�s�[��t�@�C���̐擪�N���X�^��
	CALL	GET_FIRST_SCTR			;
	LD	HL,DW0				;
	LD	DE,CP_SCTR			;
	CALL	DW_COPY				;
	CALL	RESTORE_WDIR			;�I�d�v�I
	CALL	SWAP_ARGS			;(ARG0)<->(ARG1)
	CALL	CHANGE_WDIR			;
	LD	C,ATRB_FILE			;
	CALL	GET_DENT			;
	JP	Z,ERR_NOT_FOUND			;������Ȃ���΃G���[
	LD	HL,DIR_ENTRY+IDX_SIZE		;
	LD	DE,FP				;
	CALL	DW_COPY				;(FP)<-�R�s�[���t�@�C���̃t�@�C���T�C�Y
	LD	HL,DIR_ENTRY+IDX_SIZE		;�R�s�[���̃t�@�C���T�C�Y���R�s�[��ɓ]������
	LD	DE,CP_DENT+IDX_SIZE		;
	CALL	DW_COPY				;
	LD	HL,(DIR_ENTRY+IDX_FAT)		;HL<-�R�s�[���t�@�C���̃N���X�^��
	LD	IX,FILE_BFFR_STRCT		;

	;-----------------------------------------

.LOOP:	PUSH	HL				;�N���X�^���ޔ�
	CALL	GET_FIRST_SCTR			;(DW0)<-�N���X�^HL�̃Z�N�^��
	LD	A,(SCTRS_PER_CLSTR)		;
	LD	B,A				;�P�N���X�^���\������Z�N�^���������[�v����
.L1:	PUSH	BC				;�J�E���^�ޔ�
	CALL	COPY_SCTR			;�Z�N�^�R�s�[����
	CALL	DW0_INC				;�R�s�[���̃Z�N�^��++
	LD	HL,CP_SCTR			;�R�s�[��̃Z�N�^��++
	CALL	DW_INC				;
	LD	HL,FP				;(FP)<-(FP)-�Z�N�^�T�C�Y
	LD	DE,DWA				;
	CALL	DW_SUB				;
	JR	C,.EXIT				;(FP) <  0 �Ȃ�I����
	CALL	DW_DEC				;
	JR	C,.EXIT				;(FP) == 0 �Ȃ�I����
	CALL	DW_INC				;
	POP	BC				;�J�E���^���A
	DJNZ	.L1				;

	;-----------------------------------------

	;�R�s�[�� �󂫃N���X�^��������
	LD	HL,(TGT_CLSTR)			;�N���X�^HL�ȊO�̋󂫃N���X�^��T��
	CALL	FIND_NULL_CLSTR			;HL<-�󂫃N���X�^��,CY=1:��������
	JR	C,.FOUND			;
	LD	HL,(TGT_CLSTR)			;�󂫂�������Ȃ���΃G���[����
	LD	DE,0FFFFH			;=FAT�̏I���R�[�h
	CALL	WRITE_FAT_DATA			;�������ݒ��̃N���X�^��FAT�G���g���ɏI���R�[�h���Z�b�g����
	LD	HL,MSG_MEDIA_FULL		;�G���[�I��
	JP	ERR				;

.FOUND:	LD	DE,(TGT_CLSTR)			;DE<-(TGT_CLSTR)=���݂̃N���X�^��
	LD	(TGT_CLSTR),HL			;(TGT_CLSTR)<-HL=�󂫃N���X�^��
	EX	DE,HL				;HL=���݂̃N���X�^��,DE=�󂫃N���X�^��
	CALL	WRITE_FAT_DATA			;�N���X�^HL��FAT�G���g���ɋ󂫃N���X�^DE���Z�b�g�������N������
	LD	HL,(TGT_CLSTR)			;HL<-�󂫃N���X�^��
	CALL	GET_FIRST_SCTR			;(DW0)<-�󂫃N���X�^�̊J�n�Z�N�^��
	LD	HL,DW0				;(CP_SCTR)<-(DW0)
	LD	DE,CP_SCTR			;
	CALL	DW_COPY				;

	;-----------------------------------------

	;�R�s�[������
	POP	HL				;�N���X�^�����A
	CALL	READ_FAT_DATA			;DE<-�N���X�^HL�̎��̃N���X�^��
	PUSH	DE				;
	POP	HL				;HL<-���̃N���X�^��
	INC	HL				;����̂��߁A�N���X�^���ɂP��������
	LD	A,H				;HL��0FFFFH�̎��A�P�������0000H�ɂȂ邱�Ƃ𗘗p���Ă���
	OR	L				;
	LD	E,BAD_FILE_DATA			;���̃N���X�^����0FFFFH�Ȃ�G���[
	JP	Z,ERROR				;
	DEC	HL				;HL�����ɖ߂�
	JR	.LOOP				;

	;-----------------------------------------

.EXIT:	POP	BC				;�J�E���^���̂Ă�
	POP	HL				;�N���X�^�����̂Ă�
	LD	HL,CP_DENT			;�R�s�[�p�o�b�t�@�̓��e���f�B���N�g���G���g���o�b�t�@�ɓ]������
	LD	DE,DIR_ENTRY			;
	LD	BC,DENT_SIZE+06H		;
	LDIR					;
	CALL	WRITE_DENT			;�f�B���N�g���G���g���o�b�t�@�̓��e�����f�B�A�ɏ�������
	LD	HL,(TGT_CLSTR)			;HL<-�ŏI�N���X�^��
	LD	DE,0FFFFH			;�ŏI�N���X�^��FAT�G���g����FFFFH����������
	CALL	WRITE_FAT_DATA			;
	CALL	FLUSH_BFFR			;
	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD			;

;=================================================
;[FS]�Z�N�^���R�s�[����
;IN  IX=�o�b�t�@�\����,(DW0)=�Z�N�^��,(CP_SCTR)=�R�s�[��̃Z�N�^��
;OUT 
;=================================================
COPY_SCTR:
	CALL	LOAD_BFFR			;�Z�N�^(DW0)���t�@�C���o�b�t�@�ɓǂݍ���
	PUSH	IX				;�o�b�t�@�̃Z�N�^���ɁA�R�s�[��̃Z�N�^�����Z�b�g����
	POP	DE				;
	LD	HL,CP_SCTR			;
	CALL	DW_COPY				;
	LD	A,TRUE				;�o�b�t�@�̍X�V�t���O�𗧂Ă�
	LD	(IX+IDX_BUPD),A			;
	CALL	SAVE_BFFR			;�o�b�t�@��������
	RET					;



;=================================================
;[CMD]CMD MD���� �T�u�f�B���N�g���쐬
; CMD MD "/DIR1/DIR2"
; CMD MD SD$
;=================================================
CMD_MD:
	CALL	STR2ARG0			;
	PUSH	HL				;
	CALL	IS_FAT16			;
	LD	IX,FILE_BFFR_STRCT		;
	CALL	CHANGE_WDIR			;
	LD	C,00H				;
	CALL	GET_DENT			;
	JP	NZ,ERR_EXISTS			;���݂��Ă���΃G���[
	LD	A,ATRB_DIR			;
	LD	(DIR_ENTRY+IDX_ATRB),A		;
	CALL 	TOUCH.NEW			;�N���X�^���Ɠ��������Z�b�g����
	CALL	SET_DENT_FAT			;
	CALL	WRITE_DENT			;
	LD	HL,(TGT_CLSTR)			;HL<-�V�K�쐬���ꂽ�T�u�f�B���N�g���̊J�n�N���X�^��
	LD	DE,0FFFFH			;�N���X�^HL��FAT�G���g����FFFFH����������
	CALL	WRITE_FAT_DATA			;
	CALL	FLUSH_BFFR			;�S�o�b�t�@�����f�B�A�ɏ�������
	LD	HL,(TGT_CLSTR)			;
	CALL	GET_FIRST_SCTR			;
	CALL	CLR_CLSTR			;�N���X�^HL������������
	LD	HL,DW0				;�o�b�t�@�\���̂̃Z�N�^��<-�J�n�Z�N�^��
	PUSH	IX				;
	POP	DE				;
	CALL	DW_COPY				;
	CALL	CLR_DENT_BFFR			;�f�B���N�g���G���g���o�b�t�@���N���A���AFAT�G���g���l�ƃt�@�C���T�C�Y��0�ɂ���
	LD	A,ATRB_DIR			;
	LD	(DIR_ENTRY+IDX_ATRB),A		;
	LD	HL,DIR_ENTRY+IDX_CTIME		;�u�쐬�����v���Z�b�g����
	CALL	SET_DATETIME			;
	LD	HL,DIR_ENTRY+IDX_TIME		;�u�X�V�����v���Z�b�g����
	CALL	SET_DATETIME			;
	LD	HL,DNAME			;�G���g�������󔒂Ŗ��߂�
	LD	C,SPC				;
	CALL	FILL_STR			;
	LD	A,"."				;�G���g����<-"."
	LD	(DIR_ENTRY+IDX_NAME),A		;
	LD	HL,(TGT_CLSTR)			;HL<-�T�u�f�B���N�g�����g�̃N���X�^��
	EX	DE,HL				;
	LD	HL,DIR_ENTRY+IDX_FAT		;�f�B���N�g���G���g���o�b�t�@��FAT�G���g��<-���g�̃N���X�^��
	LD	(HL),E				;
	INC	HL				;
	LD	(HL),D				;
	PUSH	IX				;
	POP	HL				;
	LD	DE,IDX_BADR			;
	ADD	HL,DE				;
	LD	E,(HL)				;
	INC	HL				;
	LD	D,(HL)				;DE<-�o�b�t�@�\���̂̃o�b�t�@�|�C���^
	PUSH	DE				;�o�b�t�@�\���̂̃o�b�t�@�|�C���^��ޔ�
	LD	HL,DIR_ENTRY			;
	LD	BC,DENT_SIZE			;
	LDIR					;�f�B���N�g���o�b�t�@�̓��e���t�@�C���o�b�t�@�ɃR�s�[����
	LD	A,"."				;�G���g����<-".."
	LD	(DIR_ENTRY+IDX_NAME+1),A	;
	LD	HL,(WDIR_CLSTR)			;HL<-���[�L���O�f�B���N�g���̃N���X�^��
	EX	DE,HL				;
	LD	HL,DIR_ENTRY+IDX_FAT		;�f�B���N�g���G���g���o�b�t�@��FAT�G���g��<-�e�f�B���N�g���̃N���X�^��
	LD	(HL),E				;
	INC	HL				;
	LD	(HL),D				;
	POP	HL				;�o�b�t�@�\���̂̃o�b�t�@�|�C���^�𕜋A
	LD	DE,DENT_SIZE			;
	ADD	HL,DE				;
	EX	DE,HL				;DE<-���̃G���g���ʒu
	LD	HL,DIR_ENTRY			;
	LD	BC,DENT_SIZE			;
	LDIR					;
	LD	(IX+IDX_BUPD),TRUE		;�o�b�t�@�̍X�V�t���O�𗧂Ă�
	CALL	FLUSH_BFFR			;FAT�ƃt�@�C���o�b�t�@�����f�B�A�ɏ�������
	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD			;


;=================================================
;[CMD]CMD EX���� �T�u�f�B���N�g���g��
;�E�T�u�f�B���N�g���ɐV�����N���X�^��ǉ����āA�G���g���i�[�T�C�Y���g������
; CMD EX "DIR"
; CMD EX SD$
;=================================================
CMD_EX:
	CALL	STR2ARG0			;
	PUSH	HL				;
	CALL	IS_FAT16			;
	CALL	CHANGE_WDIR			;
	LD	(ARG0),HL			;
	LD	C,ATRB_DIR			;
	CALL	GET_DENT			;
	JP	Z,ERR_NOT_FOUND			;
	LD	HL,MSG_EXPAND			;
	CALL	YES_NO				;
	JR	NZ,.EXIT			;
	LD	HL,(DIR_ENTRY+IDX_FAT)		;
	LD	A,H				;
	OR	L				;
	LD	E,ILLEGAL_FUNCTION_CALL		;
	JP	Z,ERROR				;FAT�G���g�������o�^(0000H)�Ȃ�G���[
.L2:	CALL	READ_FAT_DATA			;DE<-�N���X�^HL�̃����N��N���X�^���BHL�ێ�
	INC	DE				;DE++
	LD	A,D				;
	OR	E				;
	JR	Z,.L1				;DE=0000H ?
	DEC	DE				;DE--
	EX	DE,HL				;HL<-�����N��N���X�^��
	JR	.L2				;

.L1:	PUSH	HL				;�ŏI�N���X�^���ޔ�
	CALL	FIND_NULL_CLSTR			;HL<-�󂫃N���X�^��
	EX	DE,HL				;DE=�󂫃N���X�^��
	POP	HL				;HL<-�ŏI�N���X�^��
	JR	C,.FOUND			;
	LD	HL,MSG_MEDIA_FULL		;�󂫃N���X�^��������Ȃ���΃G���[�I��
	JP	ERR				;

.FOUND:	PUSH	DE				;�󂫃N���X�^���ޔ�
	CALL	WRITE_FAT_DATA			;�N���X�^HL��FAT�f�[�^�Ƃ���DE���Z�b�g����
	EX	DE,HL				;HL=�ŏI�N���X�^��
	LD	DE,0FFFFH			;�ŏI�N���X�^��FAT�G���g���ɏI���R�[�h���Z�b�g����
	CALL	WRITE_FAT_DATA			;
	CALL	FLUSH_BFFR			;FAT�����f�B�A�ɏ�������
	POP	HL				;�󂫃N���X�^�����A
	LD	IX,FILE_BFFR_STRCT		;
	CALL	CLR_CLSTR			;�N���X�^������
.EXIT:	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD			;


