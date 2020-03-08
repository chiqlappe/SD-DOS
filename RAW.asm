;=================================================
;[RAW]任意のファイル読み込み
;IN  (ARG1)=開始アドレス
;OUT -
;=================================================
READ_RAW:
	CALL	PREP_READ		;
	CALL	GET_FIREWALL		;
	LD	A,(ARGNUM)		;
	DEC	A			;
	LD	E,ILLEGAL_FUNCTION_CALL	;引数が不正
	JP	NZ,ERROR		;

	LD	HL,DIR_ENTRY+IDX_SIZE	;
	LD	C,(HL)			;DE=ファイルサイズの下位２バイト
	INC	HL			;
	LD	B,(HL)			;
	INC	HL			;
	LD	E,(HL)			;BC=ファイルサイズの上位２バイト
	INC	HL			;
	LD	D,(HL)			;

	LD	A,E			;ファイルサイズが10000H以上ならエラー
	OR	D			;
	JR	Z,.L1			;
.ERR:	LD	E,OUT_OF_MEMORY		;
	JP	ERROR			;

.L1:	LD	HL,(ARG1)		;HL=開始アドレス
	PUSH	HL
	LD	E,C			;DE=ファイルサイズ
	LD	D,B			;
	EX	DE,HL			;DE=開始アドレス
	ADD	HL,DE			;
	DEC	HL			;HL=終了アドレス

	CALL	IS_INFO_ON		;
	JR	Z,.L2			;

	CALL	IPRINT			;
	DB	"[RAW]",CR,LF,EOL	;
	EX	DE,HL
	CALL	PRTHLHEX		;開始アドレスを表示
	LD	A,"-"			;
	RST	18H			;
	EX	DE,HL			;
	CALL	PRTHLHEX		;終了アドレスを表示
	CALL	PUT_CR			;

.L2:	CALL	IS_SAFE_ZONE		;セーフゾーンチェック
	POP	HL			;HL=開始アドレス

.LOOP:	CALL	FETCH_1BYTE		;メモリに書き込み
	LD	(HL),A			;
	INC	HL			;
	DEC	BC			;残りサイズ--
	LD	A,B			;
	OR	C			;
	JR	NZ,.LOOP		;

	RET				;
