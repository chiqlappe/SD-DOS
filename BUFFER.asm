
;-----------------------------
;バッファ構造体
;-----------------------------
;+00 セクタ＃ LSB
;+01
;+02
;+03 セクタ＃ MSB
;+04 バッファポインタ L
;+05 バッファポインタ H
;+06 更新フラグ
;-----------------------------

;=================================================
;[BFFR]バッファ構造体を初期化する
;IN  -
;OUT -
;=================================================
INIT_BFFR:
	LD	HL,FAT1_BFFR_STRCT		;=FAT1用
	LD	DE,FAT_BFFR			;バッファの先頭アドレス
	CALL	.SUB
	LD	HL,FAT2_BFFR_STRCT		;=FAT2用
	LD	DE,FAT_BFFR			;！バッファ領域をFATと共通にすることで複製になる！
	CALL	.SUB
	LD	HL,FILE_BFFR_STRCT		;=ファイル用
	LD	DE,FILE_BFFR			;
.SUB:	CALL	DW_CLR				;バッファ構造体のセクタ＃を00000000Hにセットする
	PUSH	HL				;
	POP	IX				;
	LD	(IX+IDX_BADR),E			;バッファの先頭アドレスをセットする
	LD	(IX+IDX_BADR+1),D		;
	LD	(IX+IDX_BUPD),FALSE		;バッファの更新フラグを降ろす
	CALL	CLR_BFFR			;バッファの内容をゼロクリアする
	RET					;

;=================================================
;[BFFR]バッファをメディアに書き込む
;・更新フラグが立っている場合のみ書き込まれる
;=================================================
FLUSH_BFFR:
	PUSH	IX				;
	LD	IX,FILE_BFFR_STRCT		;
	CALL	SAVE_BFFR			;
	LD	IX,FAT1_BFFR_STRCT		;
	CALL	SAVE_BFFR			;
	LD	IX,FAT2_BFFR_STRCT		;
	CALL	SAVE_BFFR			;
	POP	IX				;
	RET					;

;=================================================
;[BFFR]バッファの内容をゼロクリアする
;IN  IX=バッファ構造体のポインタ
;=================================================
CLR_BFFR:
	LD	L,(IX+IDX_BADR)			;HL<-バッファの先頭アドレス
	LD	H,(IX+IDX_BADR+1)		;
	PUSH	HL				;
	POP	DE				;
	INC	DE				;
	LD	(HL),00H			;
	LD	BC,SCTR_SIZE-1			;
	LDIR					;
	RET					;

;=================================================
;[BFFR]指定されたバッファにセクタを読み込む
;-------------------------------------------------
;IN  IX=バッファ構造体のポインタ,(DW0)=読み込みたいセクタ＃
;OUT (IX+0) ~ (IX+3)=読み込まれたセクタ＃
;=================================================
LOAD_BFFR:
	PUSH	IX				;
	POP	HL				;
	LD	DE,DW0				;=読み込みたいセクタ＃
	CALL	DW_CP				;目的のセクタがバッファされていれば終了
	JR	C,.L1				;条件:CY=0,Z=1
	RET	Z				;
.L1:	CALL	SAVE_BFFR			;現在のバッファ内容が更新されていればメディアに書き戻す
	LD	L,(IX+IDX_BADR)			;HL<-バッファの先頭アドレス
	LD	H,(IX+IDX_BADR+1)		;
	CALL	READ_SCTR			;セクタ(DW0)をバッファHLに読み込む。エラーなら戻らずに終了する
	LD	HL,DW0				;バッファ構造体のセクタ＃を更新する！最後に行うこと！
	PUSH	IX				;
	POP	DE				;
	CALL	DW_COPY				;

IF DEBUG
	PUSH	HL
	PUSH	DE
	PUSH	BC

	CALL	IPRINT
	DB	"<R>",EOL
	LD	HL,DW0
	CALL	PRT_DW_HEX
	CALL	PUT_CR

	POP	BC
	POP	DE
	POP	HL
ENDIF
	RET


;=================================================
;[BFFR]指定されたバッファをセクタに書き込む
;IN  IX=バッファ構造体のポインタ
;OUT 
;=================================================
SAVE_BFFR:
	LD	A,(IX+IDX_BUPD)			;バッファの更新フラグが降りていれば書き戻さない
	OR	A				;
	RET	Z				;
	CALL	DW0_PUSH			;！重要！
	LD	(IX+IDX_BUPD),FALSE		;バッファの更新フラグを降ろす
	PUSH	IX				;(DW0)<-バッファに読み込まれているセクタ＃
	POP	HL				;
	LD	DE,DW0				;
	CALL	DW_COPY				;
	LD	L,(IX+IDX_BADR)			;HL<-バッファの先頭アドレス
	LD	H,(IX+IDX_BADR+1)		;
	CALL	WRITE_SCTR			;セクタ(DW0)にバッファのデータを書き込む

IF DEBUG
	PUSH	HL
	PUSH	DE
	PUSH	BC

	CALL	IPRINT
	DB	"<W>",EOL
	LD	HL,DW0
	CALL	PRT_DW_HEX
	CALL	PUT_CR

	POP	BC
	POP	DE
	POP	HL
ENDIF

	CALL	DW0_POP				;！重要！
	RET


