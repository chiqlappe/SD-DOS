
;--------------------------
;�f�B���N�g���G���g���\��
;--------------------------
;00~07H:�t�@�C����	:8	IDX_NAME
;08~0AH:�g���q		:3	IDX_EXT
;0B    :����		:1	IDX_ATRB
;0C~0DH:���g�p		:2
;0E~0FH:�쐬����	:2	IDX_CTIME
;10~11H:�쐬����	:2	IDX_CDATE
;12~13H:�A�N�Z�X���t	:2	IDX_ADATE
;14~15H:���g�p		:2
;16~17H:�X�V����	:2	IDX_TIME
;18~19H:�X�V���t	:2	IDX_DATE
;1A~1BH:FAT�G���g��	:2	IDX_FAT
;1C~1FH:�t�@�C���T�C�Y	:4	IDX_SIZE
;--------------------------

;=================================================
;[DIR]�G���g�����Ƒ����Ɉ�v����f�B���N�g���G���g����T����(DIR_ENTRY)�Ɋi�[����
;�E���[�L���O�f�B���N�g�������Ώ�
;IN  HL=�G���g�����̐擪�A�h���X,C=�����l
;OUT (DIR_ENTRY),Z=1:������Ȃ�����
;=================================================
GET_DENT:
	CALL	CLR_DENT_BFFR			;�f�B���N�g���G���g���o�b�t�@���N���A����
	LD	A,C				;
	LD	(DIR_ENTRY+IDX_ATRB),A		;
	CALL	STR2SFN				;�e�L�X�g�|�C���^�̕������8.3�`���t�@�C�����ɕϊ����A(DIR_ENTRY+IDX_NAME)�ɃZ�b�g����
.MAIN:	LD	HL,(WDIR_CLSTR)			;
	LD	IY,GET_DENT_SUB			;IY<-�f�B���N�g���G���g�������T�u���[�`��
	CALL	DIR_WALK			;�f�B���N�g�����񏈗�
	LD	A,(FOUND)			;A<-���ʃt���O
	OR	A				;�s��v�Ȃ�Z<-1
	RET					;

;=================================================
;[DIR]�f�B���N�g���G���g���̗L�������`�F�b�N����
;�E�����Ȃ璼�O�̌Ăяo�������L�����Z�����āA���̐e�ɖ߂�
;IN  HL=�f�B���N�g���G���g���̐擪�A�h���X
;OUT CY=1:�G���g���I�[
;=================================================
IS_VALID_DENT:
	LD	A,(HL)				;�G���g���̐擪���u�����v������ID�Ȃ�
	CP	ID_DISABLED			;���̃G���g���փX�L�b�v����
	JR	NZ,.L1				;
	POP	AF				;�߂�A�h���X���̂Ă�
	OR	A				;CY<-0
	RET					;
.L1:	OR	A				;�G���g���̐擪��00H�Ȃ�I����
	RET	NZ				;
	POP	AF				;�߂�A�h���X���̂Ă�
	SCF					;�I���t���O�𗧂Ă�
	RET					;

;=================================================
;[DIR]�ǂݍ��ݐ�p�����`�F�b�N
;IN  (DIR_ENTRY+IDX_ATRB)
;OUT -
;=================================================
IS_READ_ONLY:
	LD	A,(DIR_ENTRY+IDX_ATRB)		;
	AND	00000001B			;
	RET	Z				;
	LD	HL,MSG_READ_ONLY		;
	JP	ERR				;

;=================================================
;[DIR]�f�B���N�g���G���g����FAT�G���g������Ȃ�󂫃N���X�^��T���āA�l��FAT�G���g���ƃ^�[�Q�b�g�N���X�^�ɃZ�b�g����
;IN  (DIR_ENTRY+IDX_FAT)
;OUT (TGT_CLSTR)
;=================================================
SET_DENT_FAT:
	LD	HL,(DIR_ENTRY+IDX_FAT)		;HL<-FAT�G���g��
	LD	A,H				;
	OR	L				;
	JR	NZ,.L1				;FAT�G���g����0000H�Ȃ�󂫃N���X�^��T��
	LD	HL,(TGT_CLSTR)			;�󂫃N���X�^��T���N�_�ƂȂ�N���X�^��
	CALL	FIND_NULL_CLSTR			;HL<-�󂫃N���X�^��
	JR	C,.FOUND			;
	LD	HL,MSG_MEDIA_FULL		;������Ȃ���΃G���[
	JP	ERR				;

.FOUND:	LD	(DIR_ENTRY+IDX_FAT),HL		;FAT�G���g��<-�󂫃N���X�^��
.L1:	LD	(TGT_CLSTR),HL			;�^�[�Q�b�g�N���X�^<-FAT�G���g��
	RET

;=================================================
;[DIR]�w�肵�������Ɩ��O���������A��̃f�B���N�g���G���g�����쐬����
;�EFAT�G���g���l�ƃt�@�C���T�C�Y��0�ɃZ�b�g�����
;�E�f�B���N�g���G���g�������łɑ��݂���΁A�X�V�����݂̂�V��������
;IN  C=����,HL=���O�̐擪�A�h���X
;OUT Z=1:
;=================================================
TOUCH:
	CALL	GET_DENT			;���łɑ��݂����Z<-0
	JR	NZ,.UP				;
.NEW:	LD	HL,(WDIR_CLSTR)			;
	LD	IY,SEARCH_NULL_DENT		;IY<-���[�L���O�f�B���N�g�������G���g���̃A�h���X��T���T�u���[�`��
	CALL	DIR_WALK			;
	LD	A,(FOUND)			;
	OR	A				;
	JR	NZ,.L1				;
	LD	HL,MSG_DIR_FULL			;������Ȃ���΃G���[
	JP	ERR				;

.L1:	LD	HL,DIR_ENTRY+IDX_CTIME		;�f�B���N�g���G���g���o�b�t�@�́u�쐬�����v�Ɍ��ݓ������Z�b�g����
	CALL	SET_DATETIME			;
.UP:	LD	HL,DIR_ENTRY+IDX_TIME		;�f�B���N�g���G���g���o�b�t�@�́u�X�V�����v�Ɍ��ݓ������Z�b�g����
	CALL	SET_DATETIME			;
	RET					;

;=================================================
;[DIR]�f�B���N�g���G���g���o�b�t�@�̓��e�����f�B�A�ɏ�������
;IN  (DIR_ENTRY),(DIR_ENTRY.BP)
;=================================================
WRITE_DENT:
	LD	IX,FILE_BFFR_STRCT		;
	LD	HL,DIR_ENTRY.SCTR		;(DW0)<-�f�B���N�g���G���g���̊i�[��Z�N�^��
	LD	DE,DW0				;
	CALL	DW_COPY				;
	CALL	LOAD_BFFR			;
	LD	HL,(DIR_ENTRY.BP)		;
	EX	DE,HL				;DE<-�f�B���N�g���G���g���̊i�[��A�h���X
	LD	HL,DIR_ENTRY			;HL<-�f�B���N�g���G���g���o�b�t�@�̐擪�A�h���X
	LD	BC,DENT_SIZE			;BC<-�f�B���N�g���G���g���o�b�t�@�̃T�C�Y
	LDIR					;�f�B���N�g���G���g�����t�@�C���o�b�t�@�ɃR�s�[����
	LD	(IX+IDX_BUPD),TRUE		;�o�b�t�@�̍X�V�t���O�𗧂Ă�
	CALL	SAVE_BFFR			;�o�b�t�@�������߂�
	RET					;

;=================================================
;[DIR]�w�肳�ꂽ�A�h���X�ɃG���R�[�h���ꂽ���ݓ������Z�b�g����
;IN  HL=�������ݐ�̃A�h���X
;OUT 
;=================================================
SET_DATETIME:
	PUSH	HL				;�������ݐ�̃A�h���X��ޔ�
	CALL	TIME_READ			;�V�X�e�����[�N�ɓ����f�[�^���Z�b�g����
	LD	A,(DT_SEC)			;�b
	CALL	BCD2BIN				;
	LD	C,A				;
	LD	A,(DT_MIN)			;��
	CALL	BCD2BIN				;
	LD	E,A				;
	LD	A,(DT_HOUR)			;��
	CALL	BCD2BIN				;
	LD	D,A				;
	CALL	ENC_TIME			;IN:C,D,E OUT:HL=�G���R�[�h���ꂽ����
	EX	DE,HL				;
	POP	HL				;
	LD	(HL),E				;
	INC	HL				;
	LD	(HL),D				;
	INC	HL				;
	PUSH	HL				;�������ݐ�̃A�h���X��ޔ�
	LD	A,(DT_YEAR)			;�N BCD�`��
	CALL	BCD2BIN				;BCD���o�C�i���ɕϊ� IN:A,OUT:A
	ADD	A,20				;FAT16�ł͔N�̊�l���u1980�v�Ȃ̂ŁA���͒l��20�������� ��:2019->19+20=39
	LD	D,A				;
	LD	A,(DT_MONTH)			;��
	CALL	BCD2BIN				;
	LD	E,A				;
	LD	A,(DT_DAY)			;��
	CALL	BCD2BIN				;
	LD	C,A				;
	CALL	ENC_DATE			;IN:C,D,E OUT:HL=�G���R�[�h���ꂽ���t
	EX	DE,HL				;DE=�G���R�[�h���ꂽ���t
	POP	HL				;HL=�������ݐ�̃A�h���X
	LD	(HL),E				;
	INC	HL				;HL++
	LD	(HL),D				;
	RET					;

;=================================================
;[DIR]�f�B���N�g���̑S�G���g���ɑ΂����ʂȏ������s��
;�EGET_DENT_SUB
;�ESEARCH_NULL_DENT -> FIND_FREE_DENT
;�EPRT_DENT -> PRT_DENT
;IN  HL=�f�B���N�g���̃N���X�^��,IY=�T�u���[�`���̃A�h���X
;OUT 
;=================================================
DIR_WALK:
	LD	A,FALSE				;�����t���O���~�낷
	LD	(FOUND),A			;
	LD	IX,FILE_BFFR_STRCT		;
	LD	A,H				;HL=0000H�Ȃ烋�[�g�f�B���N�g���̏�����
	OR	L				;
	JR	Z,.ROOT				;
.L4:	PUSH	HL				;�N���X�^����ޔ�
	LD	A,(SCTRS_PER_CLSTR)		;B<-�N���X�^�̑��Z�N�^��
	LD	B,A				;
	CALL	GET_FIRST_SCTR			;(DW0)<-�N���X�^HL�̊J�n�Z�N�^��
	JR	.L2				;

.ROOT:	PUSH	HL				;�N���X�^����ޔ�(�X�^�b�N���킹�̃_�~�[)
	LD	A,(ROOT_SCTR_SIZE)		;B<-���[�g�f�B���N�g���̑��Z�N�^��
	LD	B,A				;
	LD	HL,ROOT_SCTR			;(DW0)<-���[�g�f�B���N�g���̊J�n�Z�N�^��
	LD	DE,DW0				;
	CALL	DW_COPY				;
.L2:	PUSH	BC				;���[�v�񐔂�ޔ�
	CALL	LOAD_BFFR			;�Z�N�^(DW0)���o�b�t�@IX�ɓǂݍ���
	LD	B,DENT_PER_SCTR			;=�P�Z�N�^������̃f�B���N�g���G���g����
	LD	L,(IX+IDX_BADR)			;HL<-�o�b�t�@�̐擪�A�h���X
	LD	H,(IX+IDX_BADR+1)		;
.L1:	PUSH	BC				;
	PUSH	HL				;
	PUSH	IX				;
	LD	DE,.RET				;�߂�A�h���X���X�^�b�N�ɐς�
	PUSH	DE				;
	JP	(IY)				;IY=���ʏ����̃T�u���[�`���A�h���X�BBC,HL,IX�ێ��BCY=1:EOD�ŏI���������Ƃ�����

.RET:	POP	IX				;
	POP	HL				;
	POP	BC				;
	JR	C,.QUIT				;CY=1�Ȃ�r���I����
.L3:	LD	DE,DENT_SIZE			;�o�b�t�@�|�C���^�����̃G���g���̐擪�ɐi�߂�
	ADD	HL,DE				;
	DJNZ	.L1				;�f�B���N�g���G���g���̐������J��Ԃ�
	CALL	DW0_INC				;�Z�N�^��++
	POP	BC				;���[�v�񐔂𕜋A
	DJNZ	.L2				;�N���X�^�̍ŏI�Z�N�^�܂ŏ�������
	POP	HL				;�N���X�^���𕜋A
	LD	A,H				;
	OR	L				;
	RET	Z				;���[�g�f�B���N�g���Ȃ玟�̃N���X�^�͖����̂ŁA�����ŏI������
	CALL	READ_FAT_DATA			;DE<-HL�N���X�^��FAT�f�[�^
	EX	DE,HL				;HL=���̃N���X�^��,DE=�s�v
	INC	HL				;���̃N���X�^����FFFFH�i�t�@�C���G���h�j�Ȃ�0000H�ɂȂ�
	LD	A,H				;�IINC���߂ł̓t���O�ω����Ȃ��̂Œ��ӁI
	OR	L				;
	RET	Z				;Z=1�Ȃ�I��
	DEC	HL				;HL��߂�
	JR	.L4				;

.QUIT:	POP	BC				;���[�v�J�E���^BC���̂Ă�
	POP	HL				;�N���X�^��HL���̂Ă�
	RET					;

;=================================================
;[DIR]��̃f�B���N�g���G���g����T��
;�E�V�����t�@�C����f�B���N�g�����쐬���鎞�ɕK�v
;IN  HL=�f�B���N�g���G���g���̐擪�A�h���X
;OUT Z=0:������Ȃ�����
;=================================================
SEARCH_NULL_DENT:
	LD	A,(HL)				;
	CP	ID_DISABLED			;
	JR	Z,.FOUND			;
	OR	A				;CY<-0
	RET	NZ				;A!=0�Ȃ�߂� �ICY=0�ɂȂ��Ă��邱�Ƃɒ��ӁI
.FOUND:	CALL	DENT_FOUND			;�G���g���������������Ƃ�m�点��t���O��l���Z�b�g����
	RET					;

;=================================================
;[DIR]�G���g�����Ƒ�������v����f�B���N�g���G���g����(DIR_ENTRY)�ɓǂݍ���
;�EDIR_WALK�p�T�u���[�`��
;�E20H �t�@�C���i�A�[�J�C�u�j
;�E10H �f�B���N�g��
;IN  HL=�����ΏۂƂȂ�f�B���N�g���G���g���̐擪�A�h���X
;OUT (DIR_ENTRY),(FOUND)=TRUE:��������
;=================================================
GET_DENT_SUB:
	CALL	IS_VALID_DENT			;�f�B���N�g���G���g���̗L�������`�F�b�N����
	PUSH	HL				;�t�@�C���o�b�t�@�|�C���^��ޔ�
	LD	DE,DIR_ENTRY			;DE<-�f�B���N�g���G���g���o�b�t�@�̐擪�A�h���X
	LD	B,DNAME_SIZE			;
.L1:	LD	A,(DE)				;�G���g�������ƍ�
	CP	(HL)				;
	JR	NZ,.EXIT			;��v���Ȃ���ΏI��
	INC	DE				;
	INC	HL				;
	DJNZ	.L1				;�G���g�����̕����������J��Ԃ�
	LD	A,(HL)				;A<-��������鑤�̑����l
	LD	C,A				;�����l��ޔ�
	AND	00001110B			;=�{�����[��+�V�X�e��+�B������
	JR	NZ,.EXIT			;�����ꂩ�̃r�b�g�������Ă���ΏI��
	LD	A,C				;�����l�𕜋A
	AND	00010000B			;�f�B���N�g�������ȊO���}�X�N����
	LD	C,A				;C<-�}�X�N���ꂽ�����l
	LD	A,(DE)				;A<-�������鑤�̑����l
	OR	A				;00H�Ȃ瑮���`�F�b�N���ȗ�
	JR	Z,.FOUND			;
	AND	00010000B			;�f�B���N�g�������ȊO���}�X�N����
	CP	C				;�f�B���N�g�������݂̂��r
	JR	NZ,.EXIT			;��v���Ȃ���ΏI��
.FOUND:	POP	HL				;�o�b�t�@�|�C���^�𕜋A
	PUSH	HL				;�o�b�t�@�|�C���^��ޔ�
	LD	DE,DIR_ENTRY			;��v�����f�B���N�g���G���g����(DIR_ENTRY)�ɃR�s�[����
	LD	BC,DENT_SIZE			;
	LDIR					;
	POP	HL				;�o�b�t�@�|�C���^�𕜋A
	CALL	DENT_FOUND			;��v�������Ƃ�m�点��t���O��l���Z�b�g����
	RET					;

.EXIT:	OR	A				;CY<-0
	POP	HL				;
	RET					;

;=================================================
;[DIR]GET_DENT_SUB�ŃG���g���������������Ƃ�m�点��t���O��l���Z�b�g����
;IN  HL=�o�b�t�@�|�C���^,DW0=�Z�N�^��
;OUT (DIR_ENTRY.BP),(DIR_ENTRY.SCTR),(FOUND),CY<-1
;=================================================
DENT_FOUND:
	LD	(DIR_ENTRY.BP),HL		;�f�B���N�g���G���g�����̃o�b�t�@�|�C���^<-HL
	LD	HL,DW0				;
	LD	DE,DIR_ENTRY.SCTR		;
	CALL	DW_COPY				;�f�B���N�g���G���g�����̃Z�N�^��<-(DW0)
	LD	A,TRUE				;�����t���O�𗧂Ă�
	LD	(FOUND),A			;
	SCF					;�I���t���O�𗧂Ă�
	RET					;

;=================================================
;[DIR]�G���g�����o�� FILES���ߗp
;�EDIR_WALK�p�T�u���[�`��
;IN  HL=�o�b�t�@�|�C���^
;OUT CY:1=END OF DATA
;=================================================
PRT_DENT:
	CALL	IS_VALID_DENT			;
	PUSH	BC				;
	PUSH	HL				;
	PUSH	IX				;
	PUSH	HL				;IX<-�o�b�t�@�|�C���^
	POP	IX				;
	CALL	PAUSE				;�ꎞ��~����
	JR	NZ,.L6				;STOP�L�[�Œ��f
	SCF					;�����I���t���O�𗧂Ă�
	JR	.EXIT2				;

.L6:	LD	A,(IX+0BH)			;=�����l
	LD	E,A				;
	AND	00001110B			;�B���t�@�C���A�V�X�e���A�{�����[��������r������
	JR	NZ,.EXIT			;
	LD	A,E				;
	AND	00010000B			;=�u�f�B���N�g���v����
	JR	NZ,.DIR				;
	CALL	IPRINT				;
	DB	"      ",DQUOTE,EOL		;
	JR	.NAME				;�t�@�C���E�f�B���N�g�����\����

.DIR:	CALL	IPRINT				;�f�B���N�g���}�[�N�\��
	DB	"<DIR> ",DQUOTE,EOL		;
.NAME	LD	B,DNAME_SIZE			;�t�@�C���E�f�B���N�g�����\��
	LD	C,00H				;�󔒃J�E���^
.L1:	LD	A,(HL)				;
	CP	SPC				;�󔒂��s���I�h�ɒu��������
	JR	Z,.L3				;
.L2:	RST	18H				;
	INC	HL				;
	DJNZ	.L1				;
.L5:	LD	A,DQUOTE			;��d���p���\��
	RST	18H				;

IF FALSE
	CALL	IPRINT				;FAT�G���g���\��
	DB	3AH,27H,EOL			;
	LD	L,(IX+1AH)			;
	LD	H,(IX+1BH)			;
	CALL	PRTHLHEX			;
ENDIF


	LD	A,C				;�ʒu���킹�p�̋󔒕\��
	OR	A				;
	JR	Z,.L8				;
.L7:	CALL	PUT_SPC				;
	DEC	C				;
	JR	NZ,.L7				;
.L8:	CALL	IPRINT				;
	DB	27H,EOL				;= "'"

IF SHOW_DATE
	LD	E,(IX+18H)			;
	LD	D,(IX+19H)			;
	CALL	PRT_FDATE			;���t�\��
	CALL	PUT_SPC				;
	LD	E,(IX+16H)			;
	LD	D,(IX+17H)			;
	CALL	PRT_FTIME			;�����\��
ELSE
	CALL	PRT_FSIZE			;�t�@�C���T�C�Y�o��
ENDIF


	CALL	PUT_CR				;���s
.EXIT:	OR	A				;CY<-0
.EXIT2:	POP	IX				;
	POP	HL				;
	POP	BC				;
	RET					;

.L4:	LD	A,(HL)				;�󔒕����s���I�h�ɒu��������
	CP	SPC				;
	JR	Z,.L3				;
	PUSH	AF				;
	LD	A,"."				;
	RST	18H				;
	POP	AF				;
	DEC	C				;
	JR	.L2				;
.L3:	INC	HL				;�o�b�t�@�|�C���^++
	INC	C				;�󔒃J�E���^++
	DJNZ	.L4				;
	JR	.L5				;

;=================================================
;[DIR]�f�B���N�g���G���g���o�b�t�@���N���A����
;=================================================
CLR_DENT_BFFR:
	EXX
	LD	HL,DIR_ENTRY			;
	LD	DE,DIR_ENTRY+1			;
	LD	BC,DENT_SIZE-1			;
	LD	(HL),00H			;
	LDIR					;
	EXX					;
	RET					;

