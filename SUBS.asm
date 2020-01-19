;=================================================
;[SUB]インフォメーションスイッチがオンかチェックする
;IN  -
;OUT Z=1:オフ（情報を表示しないモード）
;=================================================
IS_INFO_ON:
	LD	A,(INFO_SW)
	AND	A
	RET

;=================================================
;[SUB]日付が79年かチェックする
;IN  (DT_YEAR)
;OUT CF=1:79年
;=================================================
IF FALSE
IS_YEAR79:
	LD	A,(DT_YEAR)			;
	CP	79H				;=79年
	RET	NZ				;
	CALL	IPRINT				;
	DB	"SET",CR,LF			;
	DB	"DATE$=",DQUOTE,"00/00/00",DQUOTE
	DB	":TIME$=",DQUOTE,"00:00:00",DQUOTE,CR,LF,EOL
	RET
ENDIF

;=================================================
;[SUB]一時停止
;IN  
;OUT :Z=1:STOPキーが押された
;=================================================
PAUSE:
	IN	A,(09H)				;
	BIT	00H,A				;STOP押下ならZ=1
	RET	Z				;処理中断へ
	BIT	07H,A				;エスケープ押下なら一時停止
	RET	NZ				;
	CALL	KEYWAIT				;リターン入力で再開
	CP	03H				;STOP押下ならZ=1
	RET					;

;=================================================
;[SUB]拡張子別にサブルーチンへジャンプする
;IN  (TGT_CLSTR)=ファイルのクラスタ＃,HL=サブルーチンテーブルポインタ
;OUT
;=================================================
EXT_TABLE_JUMP:
.L3:	PUSH	HL				;テーブルポインタを退避
	LD	DE,DIR_ENTRY+IDX_EXT		;DE<-ディレクトリエントリ拡張子部
	LD	B,03H				;B<-拡張子の文字数
.L2:	LD	A,(DE)				;入力された拡張子とテーブルを照合する
	CP	(HL)				;(DE):(HL)
	JR	NZ,.L1				;不一致処理へ
	INC	DE				;それぞれのポインタを進める
	INC	HL				;
	DJNZ	.L2				;文字数分だけ繰り返す

	POP	DE				;不要になったテーブルポインタを捨てる
	LD	E,(HL)				;DE<-拡張子に対応したサブルーチンのアドレス
	INC	HL				;
	LD	D,(HL)				;
	EX	DE,HL				;HL<-DE
	JP	(HL)				;サブルーチンへ

.L1:	POP	HL				;HL<-行の先頭アドレス
	LD	BC,0005H			;BC<-テーブル１行あたりのバイト数
	ADD	HL,BC				;テーブルのポインタを次の行に進める
	LD	A,(HL)				;値が00Hになるまで繰り返す
	OR	A				;
	JR	NZ,.L3				;

	LD	HL,MSG_NOT_SUPPORTED_EXT 	;不一致処理
	JP	ERR				;

;=================================================
;[SUB]入力された引数をワークにセットする
; "文字列",式1,式2 -> (ARG0),(ARG1),(ARG2),(ARG3)
; 式1,式2,式3は省略可
;IN  HL=TP
;OUT HL=TP,(ARG0)=文字列ポインタ,(ARG1~3)=WORD型,(ARGNUM)=有効なWORD型パラメータの数 0~3
;=================================================
GET_ARGS:
	CALL	RESET_ARGS			;入力パラメータ用ワークを初期化
	CALL	STR2ARG0			;(ARG0)<-文字列ポインタ

	DEC	HL				;！重要！
	RST	10H				;BASIC解析
	LD	A,(HL)				;カンマが無ければ終了する
	CP	","				;
	RET	NZ				;

	CALL	EXP2WORD			;(ARG1)<-式１の評価結果
	LD	(ARG1),DE			;
	CALL	.INC				;(ARGNUM)++
	LD	A,(HL)				;
	CP	","				;
	RET	NZ				;

	CALL	EXP2WORD			;(ARG2)<-式２の評価結果
	LD	(ARG2),DE			;
	CALL	.INC				;(ARGNUM)++
	LD	A,(HL)				;
	CP	","				;
	RET	NZ				;

	CALL	EXP2WORD			;(ARG2)<-式３の評価結果
	LD	(ARG3),DE			;

.INC:	PUSH	HL				;有効な入力パラメータの数を＋１する
	LD	HL,ARGNUM			;
	INC	(HL)				;
	POP	HL				;
	RET					;

;=================================================
;[SUB]引数用ワークをリセットする
;IN  -
;OUT (ARG0~ARG3)<-0000H,ARGNUM<-0
;=================================================
RESET_ARGS:
;	PUSH	HL				;
;	LD	HL,0000H			;
;	LD	(ARG0),HL			;
;	LD	(ARG1),HL			;
;	LD	(ARG2),HL			;
;	LD	(ARG3),HL			;
;	XOR	A				;
;	LD	(ARGNUM),A			;
;	POP	HL

	PUSH	HL				;
	LD	B,09H				;
	LD	HL,ARG0				;
	XOR	A				;
.L1:	LD	(HL),A				;
	INC	HL				;
	DJNZ	.L1				;
	POP	HL				;
	RET					;

;=================================================
;[SUB]16進文字コード照合
;IN  A=文字コード
;OUT -
;=================================================
IS_HEX:
	PUSH	AF				;
	CALL	CAPITAL				;大文字化
	SUB	"0"				;"0"->0,"9"->9,"A"->17,"F"->22
	JR	C,.ERR				;00H~2FHを除外
	SUB	10				;"A"->7,"F"->12
	JR	C,.EXIT				;"0"~"9"を抽出
	SUB	7				;"A"->0,"F"->5
	JR	C,.ERR				;":"~"@"を除外
	SUB	6				;
	JR	C,.EXIT				;"A"~"F"を抽出

.ERR:	LD	E,ILLEGAL_FUNCTION_CALL		;
	JP	ERROR				;

.EXIT:	POP	AF				;
	RET					;

;=================================================
;[SUB]エラーメッセージ表示
;IN  HL=メッセージのアドレス
;OUT -
;=================================================
ERR:
	CALL	PRINT				;
	CALL	PUT_CR				;
	LD	E,UNPRINTABLE			;
	JP	ERROR				;

;=================================================
;[SUBS]YES / NO 入力待ち
;IN  HL=メッセージ用文字列のアドレス
;OUT Z=1:YES
;=================================================
YES_NO:
	CALL	PRINT				;
	CALL	IPRINT				;
	DB	"? (Y/N)",EOL			;
	CALL	KEYWAIT				;A<-入力コード
	CALL	CAPITAL				;大文字化
	PUSH	AF				;
	RST	18H				;エコーバック
	CALL	PUT_CR				;改行
	POP	AF				;
	CP	"Y"				;"Y"ならZ<-1
	RET	Z				;

	LD	HL,MSG_CANCELED			;
	CALL	PRINT				;
	OR	A				;Z<-0
	RET					;

;=================================================
;[SUBS]BCDをバイナリに変換する
;IN  A=BCD値
;OUT A=バイナリ値
;=================================================
BCD2BIN:
	PUSH	BC				;A=59Hの場合
	LD	C,A				;0101.1001B=59H
	AND	11110000B			;0101.0000B=50H
	SRL	A				;0010.1000B=28H=40
	LD	B,A				;B<-40
	SRL	A				;0001.0100B
	SRL	A				;0000.1010B
	SRL	A				;0000.0101B=5
	ADD	A,A				;=10
	ADD	A,B				;A<-A+B=10+40=50
	LD	B,A				;B=50
	LD	A,C				;A=0101.1001B=59H
	AND	00001111B			;A=0000.1001B=09H
	ADD	A,B				;A=A+B=9+50=59
	POP	BC				;
	RET					;

;=================================================
;[SUB]文字列を表示する
;IN  (SP)=文字列の先頭アドレス
;OUT -
;=================================================
IPRINT:
	EX	(SP),HL				;
	PUSH	AF				;
.L1:	LD	A,(HL)				;
	INC	HL				;
	OR	A				;
	JR	Z,.L2				;
	RST	18H				;
	JR	.L1				;
.L2:	POP	AF				;
	EX	(SP),HL				;
	RET					;

;=================================================
;[SUB]16進数を表示する
;IN  A
;OUT -
;=================================================
PUTHEX:
	PUSH	DE				;
	CALL	CNVBYTEHEX			;D,E<-文字
	LD	A,D				;
	RST	18H				;
	LD	A,E				;
	RST	18H				;
	POP	DE				;
	RET					;

;=================================================
;[SUB]ダブルワードを16進数で表示する
;IN  HL=ダブルワードのポインタ
;OUT 
;=================================================
PRT_DW_HEX:
	PUSH	BC				;
	PUSH	HL				;
	INC	HL				;
	INC	HL				;
	INC	HL				;
	LD	B,04H				;
.L1:	LD	A,(HL)				;
	CALL	PUTHEX				;
	DEC	HL				;
	DJNZ	.L1				;
	POP	HL				;
	POP	BC				;
	RET					;

