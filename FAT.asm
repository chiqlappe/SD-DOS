
;=================================================
;[FAT]FATのリンク先をすべて「空き」にする
;IN  HL=クラスタ＃
;OUT 
;=================================================
ERASE_FAT_LINK:
.L1:	CALL	READ_FAT_DATA			;
	LD	A,D				;FATデータが0000Hなら終了
	OR	E				;
	RET	Z				;

	PUSH	DE				;FATデータを退避
	LD	DE,0000H			;
	CALL	WRITE_FAT_DATA			;クラスタHLのFATデータを0000Hにセットする
	POP	HL				;FATデータを復帰
	INC	HL				;FATデータがFFFFHなら終了
	LD	A,H				;
	OR	L				;
	RET	Z				;
	DEC	HL				;HLをもとに戻す
	LD	DE,MIN_CLSTR			;DE<-最小論理クラスタ＃
	CALL	CPHLDE				;
	JR	C,.EXIT2			;
	LD	DE,MAX_CLSTR+1			;DE<-最大論理クラスタ＃+1
	CALL	CPHLDE				;
	JR	C,.L1

.EXIT2:
	DB	0FFH				;TRAP

;=================================================
;[FAT]FATデータをFATバッファに書き込む
;IN  HL=クラスタ＃,DE=FATデータ
;OUT 
;=================================================
WRITE_FAT_DATA:
	PUSH	IX				;！重要！
	LD	IX,FAT1_BFFR_STRCT		;
	PUSH	DE				;FATデータを退避
	PUSH	HL				;クラスタ＃を退避
	CALL	GET_FAT_SCTR			;(DW0)<-クラスタ＃に対応するFATのセクタ＃
	CALL	LOAD_BFFR			;
	POP	HL				;クラスタ＃を復帰
	CALL	GET_FAT_POINTER			;HL<-FATバッファのポインタ
	POP	DE				;FATデータを復帰
	LD	(HL),E				;データをFATバッファに書き込む
	INC	HL				;
	LD	(HL),D				;
	LD	A,TRUE
	LD	(FAT1_BFFR_STRCT+IDX_BUPD),A	;FAT1バッファの更新フラグを立てる
	LD	(FAT2_BFFR_STRCT+IDX_BUPD),A	;FAT2バッファの更新フラグを立てる
	POP	IX				;
	RET

;=================================================
;[FAT]FAT2バッファ構造体のセクタ＃をFAT1と同期する
;IN  -
;OUT (FAT2_BFFR_STRCT.SCTR)
;=================================================
SYNC_FAT2_SCTR:
	PUSH	IX				;！重要！
	LD	IX,FAT2_BFFR_STRCT		;
	LD	HL,(FAT1_BFFR_STRCT.SCTR) 	;HL<-バッファされているFATセクタ＃の下位2バイト！上位2バイトは必ず0000Hなので無視する！
	LD	DE,(FAT_SIZE)			;DE<-FAT１面に必要なセクタ数
	ADD	HL,DE				;HL<-FATに対応するFAT2のセクタ＃
	LD	(FAT2_BFFR_STRCT.SCTR),HL 	;FAT2バッファ構造体のセクタ＃に、FATに対応するFAT2のセクタ＃をセットする！セクタ＃の上位２バイトは必ず0000Hなので手を付けない！
	POP	IX				;
	RET					;

;=================================================
;[FAT]FATデータをFATから読み出す
;IN  HL=クラスタ＃
;OUT DE=FATデータ=次のクラスタ＃
;=================================================
READ_FAT_DATA:
	PUSH	HL				;
	PUSH	IX				;！重要！
	PUSH	HL				;クラスタ＃を退避
	CALL	GET_FAT_SCTR			;(DW0)<-クラスタ＃に対応するFATのセクタ＃
	LD	IX,FAT1_BFFR_STRCT		;
	CALL	LOAD_BFFR			;セクタ(DW0)をFATバッファに読み込む
	CALL	SYNC_FAT2_SCTR			;FAT2バッファ構造体のセクタ＃をFATに合わせる
	POP	HL				;クラスタ＃を復帰
	CALL	GET_FAT_POINTER			;HL<-FATバッファポインタ
	LD	E,(HL)				;DE<-次のクラスタ＃
	INC	HL				;
	LD	D,(HL)				;
	POP	IX				;
	POP	HL				;
	RET					;

;=================================================
;[FAT]クラスタHLのFATデータが含まれるセクタ＃を(DW0)に求める = FAT_SCTR + (クラスタ＃の上位バイト)
;IN  HL=クラスタ＃
;OUT (DW0)=セクタ＃
;=================================================
GET_FAT_SCTR:
	CALL	DW0_CLR				;(DW0)<-クラスタ＃の上位バイト
	LD	A,H				;
	LD	(DW0),A				;
	LD	HL,DW0				;(DW0)<-(DW0)+(FAT_SCTR)
	LD	DE,FAT_SCTR			;
	CALL	DW_ADD				;
	RET					;

;=================================================
;[FAT]クラスタのFATデータを示すポインタを求める = バッファアドレス + (クラスタ＃の下位バイト * 2)
;IN  HL=クラスタ＃,IX=FATバッファ構造体のポインタ
;OUT HL=ポインタ
;=================================================
GET_FAT_POINTER:
	XOR	A				;A<-0
	LD	H,A				;H<-0
	LD	A,L				;A<-L
	SLA	A				;A<-A*2 & CY
	LD	L,A				;L<-A
	RL	H				;CYをHのLSBへ
	LD	E,(IX+IDX_BADR)			;DE<-FATバッファの先頭アドレス+(クラスタ＃の下位バイト*2)
	LD	D,(IX+IDX_BADR+1)		;
	ADD	HL,DE				;
	RET					;

;=================================================
;[FAT]FATから空きクラスタを探す
;・！入力クラスタ＃は探索対象外！
;IN  HL=クラスタ＃
;OUT HL=空きクラスタ＃,CY=1:見つかった
;=================================================
FIND_NULL_CLSTR:
	PUSH	HL				;二次探索用にクラスタ＃を退避
	LD	DE,MAX_CLSTR			;
	EX	DE,HL				;
	OR	A				;CY<-0
	SBC	HL,DE				;
	EX	DE,HL				;
	JR	C,.ERR1				;クラスタ＃が上限値を超えていたらエラー
	JR	Z,.L4				;クラスタ＃＝最終クラスタ＃なら二次探索へ
	LD	B,D				;BC=カウンタ<-最終クラスタ＃-クラスタ＃
	LD	C,E				;
	INC	HL				;！重要！次のクラスタ＃から探索
.L1:	CALL	.SUB				;FATデータが0000HならZ=1になる
	JR	NZ,.L2				;
	POP	DE				;降順探索用スタックを捨てる
	JR	.FOUND				;発見したので終了へ
.L2:	INC	HL				;クラスタ＃を１進める
	DEC	BC				;カウンタが０になるまで繰り返す
	LD	A,B				;
	OR	C				;
	JR	NZ,.L1				;
.L4:	POP	HL				;クラスタ＃復帰
	LD	BC,MIN_CLSTR			;クラスタ＃＝最小クラスタ＃なら終了へ
	OR	A				;
	SBC	HL,BC				;
	JR	C,.ERR1				;クラスタ＃が下限値を超えていたらエラー
	JR	Z,.NOT				;
	LD	B,H				;BC=カウンタ<-クラスタ＃-最小クラスタ＃
	LD	C,L				;
	LD	HL,MIN_CLSTR			;HL<-最小クラスタ＃
.L3:	CALL	.SUB				;FATデータが0000HならZ=1になる
	JR	Z,.FOUND			;発見したので終了へ
	INC	HL				;クラスタ＃を１進める
	DEC	BC				;カウンタが０になるまで繰り返す
	LD	A,B				;
	OR	C				;
	JR	NZ,.L3				;
.NOT:	OR	A				;見つからなかった CY<-0
	RET					;

.FOUND:	SCF					;発見で終了 CY<-1
	RET					;

.SUB:	PUSH	HL				;クラスタ＃退避
	PUSH	BC
	CALL	READ_FAT_DATA			;DE<-FATデータ
	POP	BC
	POP	HL				;クラスタ＃復帰
	LD	A,D				;FATデータが0000HならZ=1
	OR	E				;
	RET					;

.ERR1:	DB	0FFH				;TRAP

