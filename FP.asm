
;-------------------------------------------------
;�t�@�C���|�C���^FP�̍\��
;-------------------------------------------------
;MSB                             LSB
;00000000 00000000 00000000 00000000
;                         1 11111111: 0~ 8  9bit �I�t�Z�b�g�l        0~511
;                   111111          : 9~14  6bit �Z�N�^�V���A����    0~63       FP_SCTR_SN
;-1111111 11111111 1                :15~30 16bit �N���X�^�V���A����  0~65535	FP_CLSTR_SN
;
;�E�I�t�Z�b�g�l�@�@�@�c�o�b�t�@���ł̑��Έʒu                 0~511
;�E�Z�N�^�V���A�����@�c�N���X�^���\������Z�N�^�̃V���A����   0~(BPB+2)-1
;�E�N���X�^�V���A�����c�t�@�C�����\������N���X�^�̃V���A���� 0~65535
;
;�@��FP�̍ő�l�̓t�@�C���T�C�Y
;-------------------------------------------------

;=================================================
;[FP]FP�֘A�̃��[�N������������i�ǂݍ��݁��������݁j
;IN  HL=�t�@�C���̊J�n�N���X�^��
;OUT (FP),(FP_CLSTR),(FP_SCTR_SN)
;=================================================
INIT_FP:
	PUSH	HL				;
	LD	(FP_CLSTR),HL			;(FP_CLSTR)<-�t�@�C���̊J�n�N���X�^��
	LD	HL,FP				;(FP)<-00.00.00.00H
	CALL	DW_CLR				;
	XOR	A				;(FP_SCTR_SN)<-00H
	LD	(FP_SCTR_SN),A			;
	LD	HL,0000H			;(FP_CLSTR_SN)<-0000H
	LD	(FP_CLSTR_SN),HL		;
	POP	HL				;
	RET					;

;=================================================
;[FP]�I�t�Z�b�g�l�̃[������
;IN  HL=FP�̃|�C���^
;OUT Z=1:FP�̃I�t�Z�b�g�l�̓[��
;=================================================
IS_FP_OFST_ZERO:
	LD	A,(HL)				;FP�̉��ʂX�r�b�g���`�F�b�N
	OR	A				;
	RET	NZ				;
	INC	HL				;
	LD	A,(HL)				;
	SRL	A				;
	RET					;

;=================================================
;[FP]FP�֘A���[�N����Z�N�^�������߂�
;IN (FP_CLSTR),(FP_CLSTR_SN),(FP_SCTR_SN)
;OUT (DW0)
;=================================================
FP2SCTR:
	CALL	GET_FP_CLSTR			;DE<-FP�����݂���N���X�^��
	EX	DE,HL				;HL<-FP�����݂���N���X�^��
	CALL	GET_FIRST_SCTR			;(DW0)<-FP�����݂���N���X�^�̊J�n�Z�N�^��
	LD	HL,DW1				;(DW1)<-00000000H
	CALL	DW_CLR				;
	LD	A,(FP_SCTR_SN)			;(DW1)<-�Z�N�^�V���A����
	LD	(DW1),A				;
	CALL	DW0_ADD				;(DW0)<-�J�n�Z�N�^��+�Z�N�^�V���A����=�ړI�̃Z�N�^��
	RET					;

;=================================================
;[FP]�t�@�C����(FP_CLSTR_SN)�Ԗڂ̃N���X�^���ƁA����FAT�G���g�������߂�
;IN  (FP_CLSTR)=�t�@�C���̐擪�N���X�^��,(FP_CLSTR_SN)=FP�������A�h���X���A�擪���牽�Ԗڂ̃N���X�^�Ɋ܂܂�邩
;OUT DE=�N���X�^��,HL=FAT�G���g��
;=================================================
GET_FP_CLSTR:
	LD	DE,(FP_CLSTR)			;DE<-�t�@�C���̐擪�N���X�^���B�f�t�H���g�̕Ԃ�l
	LD	A,(FP_CLSTR_SN)			;
	LD	B,A				;
	INC	B				;�I�d�v�I
	EX	DE,HL				;HL=�t�@�C���̐擪�N���X�^��
.L1:	PUSH	BC				;�ŏI�N���X�^�T�[�`
	CALL	READ_FAT_DATA			;DE<-�N���X�^��HL��FAT�G���g��
	EX	DE,HL				;HL=FAT�G���g��,DE=�N���X�^��
	POP	BC				;
	DJNZ	.L1				;
	RET					;

;=================================================
;[FP]FP�������Z�N�^���o�b�t�@�ɓǂݍ��ށi�ǂݍ��݁j
;IN  (FP_CLSTR),(FP_SCTR_SN),IX=�o�b�t�@�\���̂̃|�C���^
;OUT (DW0),(DW1)
;=================================================
READ_FP_SCTR:
	CALL	FP2SCTR				;FP�֘A���[�N����Z�N�^�������߂�
	CALL	LOAD_BFFR			;�Z�N�^(DW0)���o�b�t�@�\����IX�ɓǂݍ��� IX�̃Z�N�^�����X�V�����
	RET					;

;=================================================
;[FP]FP�������������̒l���擾��FP++����i�ǂݍ��݁j
;�I�Z�N�^���o�b�t�@�Ɏ�荞�܂�Ă��邱�ƁI
;IN  FP,IX=�o�b�t�@�\���̂̃|�C���^
;OUT A=(FP)�̒l,FP
;=================================================
FETCH_1BYTE:
	EXX					;
	CALL	FP2BP				;A<-FP�������������̒l
	LD	A,(HL)				;
	CALL	INC_FP				;FP++
	EXX					;
	RET					;

;=================================================
;[FP]FP�ƃo�b�t�@�\����IX����AFP�������o�b�t�@�|�C���^�����߂�
;IN  FP,IX=�o�b�t�@�\���̂̃|�C���^
;OUT HL=�o�b�t�@�|�C���^
;=================================================
FP2BP:
	LD	HL,(FP)				;HL<-FP�̉��ʂQ�o�C�g
	LD	A,H				;H<-��ʂV�r�b�g���I�t
	AND	00000001B			;
	LD	H,A				;HL=�I�t�Z�b�g�l
	LD	E,(IX+IDX_BADR)			;HL<-�o�b�t�@�A�h���X+�I�t�Z�b�g�l=�o�b�t�@�|�C���^
	LD	D,(IX+IDX_BADR+1)		;
	ADD	HL,DE				;
	RET					;

;=================================================
;[FP]�t�@�C���|�C���^���P�i�߂�i�ǂݍ��݁j
;IN  FP
;OUT FP
;=================================================
INC_FP:
	PUSH	AF				;�I�d�v �I
	LD	HL,FP				;(FP)++
	CALL	DW_INC				;
	LD	A,(HL)				;�o�b�t�@�|�C���^�� 0.00000000B �ł����
	OR	A				;�V���ɃZ�N�^��ǂݍ���
	JR	NZ,.EXIT			;
	INC	HL				;
	LD	A,(HL)				;
	SRL	A				;
	JR	C,.EXIT				;
	PUSH	AF				;B<-(SCTRS_PER_CLSTR)=(BPB+2)
	LD	A,(SCTRS_PER_CLSTR)		;
	LD	B,A				;
	DEC	B				;=FP����Z�N�^�V���A���������߂邽�߂̃r�b�g�}�X�N
	POP	AF				;
	AND	B				;
	LD	(FP_SCTR_SN),A			;
	JR	NZ,.L1				;�Z�N�^�V���A�������O�Ȃ�
	CALL	NEXT_CLSTR			;���̃N���X�^����FAT���狁�߂�
	JR	NZ,.L1				;���̃N���X�^����0FFFFH�̏ꍇ��
	LD	HL,MSG_SCTR_OVERFLOW		;�t�@�C������𒴉߂������ƂɂȂ�̂ŃG���[�I��
	JP	ERR				;

.L1:	CALL	READ_FP_SCTR			;FP�������Z�N�^���o�b�t�@�ɓǂݍ���
.EXIT:	POP	AF				;
	RET					;

;=================================================
;[FP]�N���X�^���P�����߂�i�ǂݍ��݁j
;IN  (FP_CLSTR),(FP_CLSTR_SN)
;OUT (FP_CLSTR),(FP_CLSTR_SN),Z=1:EOF
;=================================================
NEXT_CLSTR:
	PUSH	DE				;
	PUSH	HL				;
	LD	HL,(FP_CLSTR_SN)		;(FP_CLSTR_SN)++
	INC	HL				;
	LD	(FP_CLSTR_SN),HL		;
	LD	HL,(FP_CLSTR)			;���݂̃N���X�^����FAT�f�[�^��ǂݎ��
	CALL	READ_FAT_DATA			;
	LD	(FP_CLSTR),DE			;���̃N���X�^���ɍX�V����
	INC	DE				;FAT�̒l��FFFFH�i�t�@�C���G���h�j�Ȃ�Z=1�ɂȂ�
	LD	A,D				;�IINC���߂ł̓t���O�ω����Ȃ��̂Œ��ӁI
	OR	E				;
	POP	HL				;
	POP	DE				;
	RET					;

;=================================================
;[FP]FP����N���X�^�V���A�����A�Z�N�^�V���A�����A�I�t�Z�b�g�l�����߂�
;IN  FP
;OUT (FP_CLSTR_SN),(FP_SCTR_SN),HL=�I�t�Z�b�g�l 0000H~01FFH
;=================================================
PARSE_FP:
	LD	HL,FP				;HL<-FP
	LD	E,(HL)				;E<-(FP)=�I�t�Z�b�g�l�̉��ʃo�C�g
	INC	HL				;HL=FP+1
	LD	A,(HL)				;A<-(FP+1)
	AND	00000001B			;=�I�t�Z�b�g�l�����߂邽�߂̃r�b�g�}�X�N
	LD	D,A				;D<-�I�t�Z�b�g�l�̏�ʃo�C�g
	PUSH	DE				;<-FP��0~8BIT
	LD	A,(SCTRS_PER_CLSTR)		;A=0100.0000B=40H
	DEC	A				;A=0011.1111B=3FH
	PUSH	AF				;
	LD	D,(HL)				;D=XXXX.XXXoB=(FP+1)
	SRL	D				;D=0XXX.XXXXB �E�V�t�g���āA�I�t�Z�b�g�����̂P�r�b�g�𗎂Ƃ�
	AND	D				;A=00XX.XXXXB
	LD	(FP_SCTR_SN),A			;<-FP��9~14BIT
	POP	AF				;A=0011.1111B=3FH
	SLA	A				;A=0111.1110B=7EH �I�t�Z�b�g�����̂P�r�b�g�����󂯂�
	INC	A				;A=0111.1111B=7FH ���̃r�b�g�p�^�[�����g���ĕK�v�ȃr�b�g���𒊏o����
	LD	E,(HL)				;E=csss.sssoB=(FP+1) c=cluster,s=SCTR,o=offset bit
	INC	HL				;
	LD	C,(HL)				;C=(FP+2)
	INC	HL				;
	LD	B,(HL)				;B=(FP+3)
.L1:	SLA	A				;A=1111.1110B CY=0
	JR	C,.L2				;CY=1�Ȃ甲����
	RL	E				;B,C,E���L�����[�t�������[�e�[�g
	RL	C				;
	RL	B				;
	JR	.L1				;

.L2:	LD	(FP_CLSTR_SN),BC		;<-FP��15~30BIT
	POP	HL				;HL=�I�t�Z�b�g�l
	RET					;

;=================================================
;[FP]FP�������t�@�C���o�b�t�@�̃������ɒl���Z�b�g��FP++����i�������݁j
;IN  FP,IX=�t�@�C���o�b�t�@�\���̂̃|�C���^,A=(FP)�ɏ������ޒl
;OUT FP
;=================================================
POST_1BYTE:
	EXX					;
	PUSH	AF				;
	CALL	FP2BP				;FP�ƃo�b�t�@�\����IX����o�b�t�@�|�C���^HL�����߂�
	POP	AF				;
	LD	(HL),A				;(�o�b�t�@�|�C���^)<-A
	LD	A,TRUE				;
	LD	(FILE_BFFR_STRCT.FLG),A		;�o�b�t�@�̍X�V�t���O�𗧂Ă�
	CALL	INC_FP_W			;FP++
	EXX					;
	RET					;

;=================================================
;[FP]�t�@�C���|�C���^���P�i�߂�i�������݁j
;IN  FP,IX=�t�@�C���o�b�t�@�\���̂̃|�C���^
;OUT FP
;=================================================
INC_FP_W:
	LD	HL,FP				;�t�@�C���|�C���^���P�i�߂�
	CALL	DW_INC				;
	LD	A,(HL)				;�o�b�t�@�|�C���^(FP�̉��ʂX�r�b�g)��0.00000000B�ɂȂ�����A�Z�N�^�����ɐi�߂�
	OR	A				;����ȊO�͏I����
	JR	NZ,.EXIT			;
	INC	HL				;
	LD	A,(HL)				;
	SRL	A				;
	JR	C,.EXIT				;
	PUSH	AF				;�����ł�A�̉��ʂU�r�b�g���Z�N�^�V���A�����ɂȂ��Ă���
	LD	A,(SCTRS_PER_CLSTR)		;
	LD	B,A				;B<-(SCTRS_PER_CLSTR)
	DEC	B				;=FP����Z�N�^�V���A���������߂邽�߂̃r�b�g�}�X�N
	POP	AF				;
	AND	B				;
	LD	(FP_SCTR_SN),A			;(FP_SCTR_SN)<-�Z�N�^�V���A����
	JR	NZ,.NEW				;�Z�N�^�V���A�������O�łȂ����
	LD	HL,(FP_CLSTR)			;HL<-���݂̃N���X�^��
	CALL	READ_FAT_DATA			;DE<-�N���X�^HL��FAT�G���g��
	LD	A,D				;FAT�G���g�����Z�b�g����Ă���΁A��������̂܂܎g��
	OR	E				;
	JR	Z,.NULL				;
	LD	(FP_CLSTR),DE			;���݂̃N���X�^��<-�N���X�^HL��FAT�G���g��
	JR	.NEW				;

.NULL:	CALL	FIND_NULL_CLSTR			;�󂫃N���X�^��HL��FAT���狁�߂� OUT HL,CY=1:��������
	JR	C,.FOUND			;
	LD	HL,(FP_CLSTR)			;HL<-���݂̃N���X�^��
	LD	DE,0FFFFH			;DE<-FAT�̏I���R�[�h
	CALL	WRITE_FAT_DATA			;���݂̃N���X�^����FAT�G���g���ɏI���R�[�h���Z�b�g����
	LD	HL,MSG_MEDIA_FULL		;�G���[�I��
	JP	ERR				;

.FOUND:	EX	DE,HL				;DE=�󂫃N���X�^��
	LD	HL,(FP_CLSTR)			;HL<-���݂̃N���X�^��
	LD	(FP_CLSTR),DE			;���݂̃N���X�^��<-�󂫃N���X�^��
	CALL	WRITE_FAT_DATA			;�N���X�^��HL��FAT�G���g���ɋ󂫃N���X�^��DE���Z�b�g�������N������
.NEW:	CALL	SAVE_BFFR			;���݂̃t�@�C���o�b�t�@���X�V����Ă���΃��f�B�A�ɏ�������
	CALL	CLR_BFFR			;���̃Z�N�^�p�Ƀt�@�C���o�b�t�@���N���A����
	CALL	FP2SCTR				;(DW0)<-FP�̃Z�N�^��
	LD	HL,DW0				;�o�b�t�@�\���̂̃Z�N�^��<-(DW0)
	PUSH	IX				;
	POP	DE				;
	CALL	DW_COPY				;
.EXIT:	RET					;

;=================================================
;[FP]FP���t�@�C���I�[�ɃZ�b�g���A�t�@�C���o�b�t�@�ɍŏI�Z�N�^��ǂݍ���
;IN  (DIR_ENTRY)
;OUT (FP),(FP_CLSTR),(FP_CLSTR_SN),(FP_SCTR_SN)
;=================================================
SET_FP_END:
	LD	HL,(DIR_ENTRY+IDX_FAT)		;HL<-�t�@�C���̃N���X�^��
	LD	A,H				;
	OR	L				;
	JP	Z,ERR_EMPTY_FILE		;�N���X�^����0000H�Ȃ�G���[
	LD	(FP_CLSTR),HL			;(FP_CLSTR)<-�t�@�C���̊J�n�N���X�^��
	LD	HL,DIR_ENTRY+IDX_SIZE		;HL<-�t�@�C���T�C�Y�̃|�C���^
	LD	DE,FP				;DE<-�t�@�C���|�C���^
	CALL	DW_COPY				;FP<-(�t�@�C���T�C�Y)=�t�@�C���̏I�[�ʒu
	CALL	PARSE_FP			;FP����(FP_CLSTR_SN),(FP_SCTR_SN)�����߂�
	CALL	GET_FP_CLSTR			;DE<-FP�����݂���N���X�^��,HL<-����FAT�G���g��
	INC	HL				;FAT�̒l��FFFFH�i�t�@�C���I�[�j�Ȃ�Z=1�ɂȂ�IINC���߂̓t���O�ω����Ȃ��I
	LD	A,H				;
	OR	L				;
	JR	Z,.L1				;�t�@�C���I�[�łȂ���΃G���[
	LD	HL,MSG_BAD_FORMAT		;�I�����ꂽ�N���X�^��FAT��0FFFFH�łȂ�
	JP	ERR				;

.L1:	CALL	READ_FP_SCTR			;FP�������Z�N�^���o�b�t�@�ɓǂݍ���
	RET					;

