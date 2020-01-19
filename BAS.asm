
;=================================================
;[BAS]BASファイルの読み込み
;IN  (TGT_CLSTR)
;OUT -
;=================================================
READ_BAS:
	CALL	PREP_READ		;

	LD	A,(ARGNUM)		;入力パラメータ数が0でなければエラーへ
	AND	A			;
	JR	Z,.L1			;

	LD	E,ILLEGAL_FUNCTION_CALL	;引数が不正
	JP	ERROR

.L1:	CALL	IS_INFO_ON		;
	JR	Z,.L4			;
	CALL	IPRINT			;
	DB	"[BAS]",CR,LF,EOL	;

.L4:	LD	HL,(BASBEGIN)		;
	CALL	GET_FIREWALL		;
.L2:	LD	B,BAS_ZERO		;
.L3:	PUSH	BC			;
	CALL	FETCH_1BYTE		;
	LD	(HL),A			;
	POP	BC			;
	CALL	CPHLDE			;OUT OF MEMORY チェック
	JR	C,.L5			; HL=アドレス
	LD	E,OUT_OF_MEMORY		; DE=境界値
	JP	ERROR			; HL>=DEでエラー
.L5:	INC	HL			;転送先アドレス++
	OR	A			;値が00Hでなければゼロカウンタを初期値に戻す
	JR	NZ,.L2			;
	DJNZ	.L3			;値が00HならBのカウントダウンを続ける

	JP	FIN_READ_BASIC		;


;=================================================
;[BAS]BASファイルの書き込み
;IN  (TGT_CLSTR)
;OUT -
;=================================================
WRITE_BAS:
	CALL	IS_BASIC		;
	JP	Z,ERR_EMPTY_FILE	;

	CALL	PREP_WRITE		;
	CALL	RAD2RNUM		;BASICの行アドレスを行番号に変換する！重要！

	LD	A,(ARGNUM)		;入力パラメータ数が0でなければエラーへ
	AND	A			;
	JR	Z,.L1			;

	LD	E,ILLEGAL_FUNCTION_CALL	;引数が不正
	JP	ERROR

.L1:	CALL	IPRINT			;
	DB	"[BAS]",CR,LF,EOL	;

	LD	DE,(BASBEGIN)		;=先頭アドレス
	LD	HL,(VARBEGIN)		;=終了アドレス
	PUSH	HL			;
	OR	A			;CY<-0
	SBC	HL,DE			;HL<-終了アドレス-先頭アドレス
	LD	B,H			;
	LD	C,L			;BC<-プログラムのサイズ
	POP	HL			;
	EX	DE,HL			;HL=先頭アドレス,DE=終了アドレス
.L2:	LD	A,(HL)			;
	CALL	POST_1BYTE		;
	INC	HL			;
	DEC	BC			;
	LD	A,B			;
	OR	C			;
	JR	NZ,.L2			;

	JP	FIN_WRITE		;

