
;=================================================
;[FAT]FAT�̃����N������ׂāu�󂫁v�ɂ���
;IN  HL=�N���X�^��
;OUT 
;=================================================
ERASE_FAT_LINK:
.L1:	CALL	READ_FAT_DATA			;
	LD	A,D				;FAT�f�[�^��0000H�Ȃ�I��
	OR	E				;
	RET	Z				;

	PUSH	DE				;FAT�f�[�^��ޔ�
	LD	DE,0000H			;
	CALL	WRITE_FAT_DATA			;�N���X�^HL��FAT�f�[�^��0000H�ɃZ�b�g����
	POP	HL				;FAT�f�[�^�𕜋A
	INC	HL				;FAT�f�[�^��FFFFH�Ȃ�I��
	LD	A,H				;
	OR	L				;
	RET	Z				;
	DEC	HL				;HL�����Ƃɖ߂�
	LD	DE,MIN_CLSTR			;DE<-�ŏ��_���N���X�^��
	CALL	CPHLDE				;
	JR	C,.EXIT2			;
	LD	DE,MAX_CLSTR+1			;DE<-�ő�_���N���X�^��+1
	CALL	CPHLDE				;
	JR	C,.L1

.EXIT2:
	DB	0FFH				;TRAP

;=================================================
;[FAT]FAT�f�[�^��FAT�o�b�t�@�ɏ�������
;IN  HL=�N���X�^��,DE=FAT�f�[�^
;OUT 
;=================================================
WRITE_FAT_DATA:
	PUSH	IX				;�I�d�v�I
	LD	IX,FAT1_BFFR_STRCT		;
	PUSH	DE				;FAT�f�[�^��ޔ�
	PUSH	HL				;�N���X�^����ޔ�
	CALL	GET_FAT_SCTR			;(DW0)<-�N���X�^���ɑΉ�����FAT�̃Z�N�^��
	CALL	LOAD_BFFR			;
	POP	HL				;�N���X�^���𕜋A
	CALL	GET_FAT_POINTER			;HL<-FAT�o�b�t�@�̃|�C���^
	POP	DE				;FAT�f�[�^�𕜋A
	LD	(HL),E				;�f�[�^��FAT�o�b�t�@�ɏ�������
	INC	HL				;
	LD	(HL),D				;
	LD	A,TRUE
	LD	(FAT1_BFFR_STRCT+IDX_BUPD),A	;FAT1�o�b�t�@�̍X�V�t���O�𗧂Ă�
	LD	(FAT2_BFFR_STRCT+IDX_BUPD),A	;FAT2�o�b�t�@�̍X�V�t���O�𗧂Ă�
	POP	IX				;
	RET

;=================================================
;[FAT]FAT2�o�b�t�@�\���̂̃Z�N�^����FAT1�Ɠ�������
;IN  -
;OUT (FAT2_BFFR_STRCT.SCTR)
;=================================================
SYNC_FAT2_SCTR:
	PUSH	IX				;�I�d�v�I
	LD	IX,FAT2_BFFR_STRCT		;
	LD	HL,(FAT1_BFFR_STRCT.SCTR) 	;HL<-�o�b�t�@����Ă���FAT�Z�N�^���̉���2�o�C�g�I���2�o�C�g�͕K��0000H�Ȃ̂Ŗ�������I
	LD	DE,(FAT_SIZE)			;DE<-FAT�P�ʂɕK�v�ȃZ�N�^��
	ADD	HL,DE				;HL<-FAT�ɑΉ�����FAT2�̃Z�N�^��
	LD	(FAT2_BFFR_STRCT.SCTR),HL 	;FAT2�o�b�t�@�\���̂̃Z�N�^���ɁAFAT�ɑΉ�����FAT2�̃Z�N�^�����Z�b�g����I�Z�N�^���̏�ʂQ�o�C�g�͕K��0000H�Ȃ̂Ŏ��t���Ȃ��I
	POP	IX				;
	RET					;

;=================================================
;[FAT]FAT�f�[�^��FAT����ǂݏo��
;IN  HL=�N���X�^��
;OUT DE=FAT�f�[�^=���̃N���X�^��
;=================================================
READ_FAT_DATA:
	PUSH	HL				;
	PUSH	IX				;�I�d�v�I
	PUSH	HL				;�N���X�^����ޔ�
	CALL	GET_FAT_SCTR			;(DW0)<-�N���X�^���ɑΉ�����FAT�̃Z�N�^��
	LD	IX,FAT1_BFFR_STRCT		;
	CALL	LOAD_BFFR			;�Z�N�^(DW0)��FAT�o�b�t�@�ɓǂݍ���
	CALL	SYNC_FAT2_SCTR			;FAT2�o�b�t�@�\���̂̃Z�N�^����FAT�ɍ��킹��
	POP	HL				;�N���X�^���𕜋A
	CALL	GET_FAT_POINTER			;HL<-FAT�o�b�t�@�|�C���^
	LD	E,(HL)				;DE<-���̃N���X�^��
	INC	HL				;
	LD	D,(HL)				;
	POP	IX				;
	POP	HL				;
	RET					;

;=================================================
;[FAT]�N���X�^HL��FAT�f�[�^���܂܂��Z�N�^����(DW0)�ɋ��߂� = FAT_SCTR + (�N���X�^���̏�ʃo�C�g)
;IN  HL=�N���X�^��
;OUT (DW0)=�Z�N�^��
;=================================================
GET_FAT_SCTR:
	CALL	DW0_CLR				;(DW0)<-�N���X�^���̏�ʃo�C�g
	LD	A,H				;
	LD	(DW0),A				;
	LD	HL,DW0				;(DW0)<-(DW0)+(FAT_SCTR)
	LD	DE,FAT_SCTR			;
	CALL	DW_ADD				;
	RET					;

;=================================================
;[FAT]�N���X�^��FAT�f�[�^�������|�C���^�����߂� = �o�b�t�@�A�h���X + (�N���X�^���̉��ʃo�C�g * 2)
;IN  HL=�N���X�^��,IX=FAT�o�b�t�@�\���̂̃|�C���^
;OUT HL=�|�C���^
;=================================================
GET_FAT_POINTER:
	XOR	A				;A<-0
	LD	H,A				;H<-0
	LD	A,L				;A<-L
	SLA	A				;A<-A*2 & CY
	LD	L,A				;L<-A
	RL	H				;CY��H��LSB��
	LD	E,(IX+IDX_BADR)			;DE<-FAT�o�b�t�@�̐擪�A�h���X+(�N���X�^���̉��ʃo�C�g*2)
	LD	D,(IX+IDX_BADR+1)		;
	ADD	HL,DE				;
	RET					;

;=================================================
;[FAT]FAT����󂫃N���X�^��T��
;�E�I���̓N���X�^���͒T���ΏۊO�I
;IN  HL=�N���X�^��
;OUT HL=�󂫃N���X�^��,CY=1:��������
;=================================================
FIND_NULL_CLSTR:
	PUSH	HL				;�񎟒T���p�ɃN���X�^����ޔ�
	LD	DE,MAX_CLSTR			;
	EX	DE,HL				;
	OR	A				;CY<-0
	SBC	HL,DE				;
	EX	DE,HL				;
	JR	C,.ERR1				;�N���X�^��������l�𒴂��Ă�����G���[
	JR	Z,.L4				;�N���X�^�����ŏI�N���X�^���Ȃ�񎟒T����
	LD	B,D				;BC=�J�E���^<-�ŏI�N���X�^��-�N���X�^��
	LD	C,E				;
	INC	HL				;�I�d�v�I���̃N���X�^������T��
.L1:	CALL	.SUB				;FAT�f�[�^��0000H�Ȃ�Z=1�ɂȂ�
	JR	NZ,.L2				;
	POP	DE				;�~���T���p�X�^�b�N���̂Ă�
	JR	.FOUND				;���������̂ŏI����
.L2:	INC	HL				;�N���X�^�����P�i�߂�
	DEC	BC				;�J�E���^���O�ɂȂ�܂ŌJ��Ԃ�
	LD	A,B				;
	OR	C				;
	JR	NZ,.L1				;
.L4:	POP	HL				;�N���X�^�����A
	LD	BC,MIN_CLSTR			;�N���X�^�����ŏ��N���X�^���Ȃ�I����
	OR	A				;
	SBC	HL,BC				;
	JR	C,.ERR1				;�N���X�^���������l�𒴂��Ă�����G���[
	JR	Z,.NOT				;
	LD	B,H				;BC=�J�E���^<-�N���X�^��-�ŏ��N���X�^��
	LD	C,L				;
	LD	HL,MIN_CLSTR			;HL<-�ŏ��N���X�^��
.L3:	CALL	.SUB				;FAT�f�[�^��0000H�Ȃ�Z=1�ɂȂ�
	JR	Z,.FOUND			;���������̂ŏI����
	INC	HL				;�N���X�^�����P�i�߂�
	DEC	BC				;�J�E���^���O�ɂȂ�܂ŌJ��Ԃ�
	LD	A,B				;
	OR	C				;
	JR	NZ,.L3				;
.NOT:	OR	A				;������Ȃ����� CY<-0
	RET					;

.FOUND:	SCF					;�����ŏI�� CY<-1
	RET					;

.SUB:	PUSH	HL				;�N���X�^���ޔ�
	PUSH	BC
	CALL	READ_FAT_DATA			;DE<-FAT�f�[�^
	POP	BC
	POP	HL				;�N���X�^�����A
	LD	A,D				;FAT�f�[�^��0000H�Ȃ�Z=1
	OR	E				;
	RET					;

.ERR1:	DB	0FFH				;TRAP

