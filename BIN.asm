
;=================================================
;[BIN]セーフゾーンチェック
;DE~HLのアドレス領域がスタック領域を犯していないかチェックする
;フリーエリアの底＜開始アドレス または 終了アドレス＜境界値 であればセーフ
;IN  DE=開始アドレス,HL=終了アドレス
;OUT -
;=================================================
IS_SAFE_ZONE:
	PUSH	HL
	LD	HL,(FREE_END)		;HL<-フリーエリアの底
	CALL	CPHLDE			;フリーエリアの底-開始アドレス
	POP	HL			;HL=終了アドレス
	RET	C			;フリーエリアの底<開始アドレス

	PUSH	DE			;
	LD	DE,(FIREWALL)		;DE<-スタックエリアとフリーエリアの境界値
	CALL	CPHLDE			;終了アドレス-境界値
	POP	DE			;DE=開始アドレス
	RET	C			;境界値>終了アドレス

	JP	CHECK_STACK_AREA.ERR	;エラー

;=================================================
;[BIN]バイナリファイルの読み込み
;IN  (TGT_CLSTR),(ARG0),(ARG1)=新しい開始アドレス<省略可>
;OUT -
;=================================================
READ_BIN:
	CALL	PREP_READ		;
	CALL	GET_FIREWALL		;
	LD	(FIREWALL),DE		;

	CALL	FETCH_1BYTE		;
	LD	L,A			;HL<-マシン語ファイルの開始アドレス
	CALL	FETCH_1BYTE		;
	LD	H,A			;
	CALL	FETCH_1BYTE		;
	LD	E,A			;DE<-マシン語ファイルの終了アドレス
	CALL	FETCH_1BYTE		;
	LD	D,A			;
	CALL	FETCH_1BYTE		;
	LD	C,A			;BC<-マシン語ファイルの実行アドレス
	CALL	FETCH_1BYTE		;
	LD	B,A			;
	LD	(EXECADR),BC		;実行アドレスをセット

	CALL	IS_INFO_ON		;ファイル情報を出力
	JR	Z,.L6			;
	PUSH	DE			;=終了アドレス
	PUSH	HL			;=開始アドレス
	CALL	IPRINT			;
	DB	"[BIN]",CR,LF		;
	DB	"ADDRESS:",EOL		;
	CALL	PRTHLHEX		;開始アドレスを表示
	LD	A,"-"			;
	RST	18H			;
	EX	DE,HL			;
	CALL	PRTHLHEX		;終了アドレスを表示
	LD	H,B			;
	LD	L,C			;
	LD	A,H			;
	OR	L			;
	JR	Z,.L10			;
	LD	A,":"			;実行アドレスを出力
	RST	18H			;
	CALL	PRTHLHEX		;
	CALL	PUT_CR			;
.L10:	POP	HL			;HL<-開始アドレス
	POP	DE			;DE<-終了アドレス

.L6:	EX	DE,HL			;DE=開始アドレス,HL=終了アドレス
	CALL	CPHLDE			;終了アドレスが、開始アドレスより小さければエラー
	JR	NC,.L5			;
	LD	E,BAD_FILE_DATA		;
	JP	ERROR			;

.L5:	CALL	IS_SAFE_ZONE		;セーフゾーンチェック
	OR	A			;CY<-0
	SBC	HL,DE			;HL<-終了アドレス-開始アドレス
	LD	B,H			;
	LD	C,L			;
	INC	BC			;BC<-ファイルサイズ
	LD	H,D			;HL<-DE=開始アドレス
	LD	L,E			;

	LD	A,(ARGNUM)		;A<-入力パラメータ数
	AND	A			;入力パラメータ数が0なら.L2へ
	JR	Z,.L2

	LD	HL,(ARG1)		;HL<-新しい開始アドレス
	CP	1			;入力パラメータ数が1なら.L2へ
	JR	Z,.L2

	INC	HL			;(ARG1)は0FFFFHか？
	LD	A,H			;
	OR	L			;
	JR	Z,.L9			;
	LD	E,ILLEGAL_FUNCTION_CALL	;引数が不正
	JP	ERROR			;

.L9:	LD	H,D			;HL<-開始アドレス
	LD	L,E			;
	LD	A,TRUE			;コールバックフラグを立てる
	LD	(IS_CALLBACK),A		;
	LD	DE,(ARG2)		;コールバックアドレスをセット
	LD	(CALLBACK),DE		;

.L2:	LD	DE,CB_BYTES		;=コールバックタイミングカウンタ

.LOOP:	CALL	FETCH_1BYTE		;メモリに書き込み
	LD	(HL),A			;
	INC	HL			;

.L1:	LD	A,(IS_CALLBACK)		;
	AND	A			;
	JR	Z,.L8			;

	DEC	DE			;コールバックタイミングカウンタを減らす
	LD	A,D			;
	OR	E			;
	JR	NZ,.L8			;
	PUSH	HL			;
	LD	HL,.RET			;戻り先アドレスをスタックに積む
	PUSH	HL			;
	LD	HL,(CALLBACK)		;
	JP	(HL)			;
.RET:	LD	DE,CB_BYTES		;コールバックタイミングカウンタをリセットする
	POP	HL			;

.L8:	DEC	BC			;残りサイズ--
	LD	A,B			;
	OR	C			;
	JR	NZ,.LOOP		;

.L7:	LD	HL,(EXECADR)		;HL<-実行アドレス
	LD	A,L			;実行アドレスが0000Hなら終了へ
	OR	H			;
	JR	Z,.L3			;

	LD	A,(EXECFLG)		;フラグが立っていたら機械語プログラムを実行する
	AND	A			;
	JR	Z,.L3			;
	XOR	A			;フラグを降ろす
	LD	(EXECFLG),A		;
	JR	EXECUTE			;実行

.L3:	RET				;

;=================================================
;機械語プログラムを実行する
; IN	(EXECADR)
;=================================================
EXECUTE:
	CALL	CLS
	LD	DE,0FE40H	;VRAM
	LD	HL,.L1
	LD	BC,5
	LDIR			; VRAM <- FUNCTION KEY DATA
	PUSH	DE
	LD	A,(EXECADR+1)
	CALL	CNVBYTEHEX
	POP	HL
	LD	(HL),D
	INC	HL
	LD	(HL),E
	INC	HL
	LD	A,(EXECADR)
	CALL	CNVBYTEHEX
	LD	(HL),D
	INC	HL
	LD	(HL),E
	INC	HL
	LD	(HL),0DH
	INC	HL
	LD	(HL),0

	LD	A,1
	LD	(FKEY_FLAG),A
	LD	HL,0FE40H
	LD	(ACTIVE_FKEY),HL
	JP	BASIC

.L1:	DB	"MON",CR,"G"


;=================================================
;[BIN]バイナリファイルの書き込み
;IN  (TGT_CLSTR),(ARG0),(ARG1)=開始アドレス,(ARG2)=終了アドレス,(ARG3)=実行アドレス<省略可>
;OUT -
;=================================================
WRITE_BIN:
	CALL	PREP_WRITE		;

	LD	A,(ARGNUM)		;入力パラメータ数が2未満ならエラーへ
	CP	2			;
	JR	C,.ERR			;

	LD	DE,(ARG1)		;DE<-開始アドレス
	LD	HL,(ARG2)		;HL<-終了アドレス
	PUSH	HL			;
	INC	HL			;サイズ算出用に１を加算
	OR	A			;
	SBC	HL,DE			;
	LD	B,H			;BC<-サイズ
	LD	C,L			;
	POP	HL			;
	JR	Z,.ERR			;サイズが０ならエラー
	JR	NC,.L1			;サイズが正の数なら.L1へ

.ERR:	LD	E,ILLEGAL_FUNCTION_CALL	;引数が不正
	JP	ERROR			;

.L1:	PUSH	BC			;サイズを退避

	CALL	PRT_WRITE_BIN_INFO	;
	EX	DE,HL			;HL=開始アドレス,DE=終了アドレス
	LD	A,L			;開始アドレス部
	CALL	POST_1BYTE		;
	LD	A,H			;
	CALL	POST_1BYTE		;

	LD	A,E			;終了アドレス部
	CALL	POST_1BYTE		;
	LD	A,D			;
	CALL	POST_1BYTE		;

	PUSH	HL			;
	LD	HL,(ARG3)		;
	LD	A,L			;実行アドレス部
	CALL	POST_1BYTE		;
	LD	A,H			;
	CALL	POST_1BYTE		;
	POP	HL			;

	POP	BC			;サイズを復帰
.L2:	LD	A,(HL)			;
	CALL	POST_1BYTE		;
	INC	HL			;
	DEC	BC			;
	LD	A,B			;
	OR	C			;
	JR	NZ,.L2			;

	JP	FIN_WRITE		;


