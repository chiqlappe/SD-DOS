
;=================================================
;[CMD]CMD命令
;=================================================
CMD:
	LD	C,00H				;ジャンプ用インデックスの初期値
	LD	DE,CMD_TABLE			;コマンドテーブルポインタ(CP)の初期値
	JP	WORD_JUMP			;

;=================================================
;[CMD]CMD V 命令 "VALID" DOSプログラムのチェックサムを出力する
;=================================================
CMD_V:
	PUSH	HL
	OR	A				;
	LD	HL,WORK_AREA			;
	LD	DE,6000H			;
	PUSH	DE				;
	SBC	HL,DE				;
	LD	B,H				;
	LD	C,L				;BC<-DOSプログラム全体のバイト数
	POP	HL				;HL<-6000H
	LD	DE,0000H			;=チェックサム
.L1:	LD	A,(HL)				;
	ADD	A,E				;
	LD	E,A				;
	LD	A,D				;
	ADC	A,00H				;DE+=(HL)
	LD	D,A				;
	INC	HL				;
	DEC	BC				;
	LD	A,B				;
	OR	C				;
	JR	NZ,.L1				;

	CALL	PUT_CR
	LD	H,D
	LD	L,E
	CALL	PRTHLHEX
	CALL	PUT_CR

	JP	CLOSE_CMD

;=================================================
;[CMD]CMD F 命令 "FREE"	フリーエリアを拡張する
;=================================================
CMD_F:
	LD	HL,FREE_AREA
	JP	SETFREADR

;=================================================
;[CMD]CMD P 命令 "PROPERTY"	ディレクトリエントリのプロパティ表示
;=================================================
CMD_P:
	CALL	STR2ARG0			;
	PUSH	HL				;
	CALL	IS_FAT16			;
	CALL	CHANGE_WDIR			;HL<-エントリ名の先頭アドレス
	LD	C,00H				;=全属性
	CALL	GET_DENT			;
	JP	Z,ERR_NOT_FOUND			;
	CALL	DUMP_DENT			;メインルーチン
	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD

;=================================================
;[CMD]CMD ON 命令 "INFO ON"	インフォメーションを表示する
;=================================================
CMD_ON:
	LD	A,TRUE

INFO:	PUSH	HL
	LD	(INFO_SW),A
	INC	A
	JR	NZ,.L1
	CALL	IPRINT
	DB	"INFO ON",CR,LF,EOL
.L1:	JP	CLOSE_CMD


;=================================================
;[CMD]CMD OFF 命令 "INFO OFF"
;=================================================
CMD_OFF:
	LD	A,FALSE
	JR	INFO

;=================================================
;[CMD]CMD R 命令 "RUN" 実行フラグを立ててロードする
;=================================================
CMD_R:
	LD	A,TRUE				;実行フラグを立てる
	LD	(EXECFLG),A			;
	CALL	RESET_ARGS			;入力パラメータを無効にする
	CALL	STR2ARG0			;
	CALL	LOAD.E1				;

	LD	A,(EXECFLG)
	AND	A
	RET	Z
	JP	RUN


;=================================================
;[CMD]RBYTE命令 任意のバイナリファイルをメモリに読み込む
;=================================================
RBYTE:
	CALL	GET_ARGS			;
	PUSH	HL				;
	CALL	IS_FAT16			;
	CALL	CHANGE_WDIR			;
	CALL	DNAME2CLSTR			;
	CALL	READ_RAW
	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD			;

;=================================================
;[CMD]LOAD命令 ファイルをメモリに読み込む
;=================================================
LOAD:
	XOR	A				;実行フラグを降ろす
	LD	(EXECFLG),A			;
	CALL	GET_ARGS			;

.E1:	PUSH	HL				;CMD Rのエントリポイント
	CALL	IS_FAT16			;
	CALL	CHANGE_WDIR			;
	CALL	DNAME2CLSTR			;
	LD	HL,EXT_LOAD_TABLE		;
	CALL	EXT_TABLE_JUMP			;拡張子に対応したロードルーチンへジャンプする
	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD			;

;=================================================
;[CMD]SAVE命令 メモリ内容をファイルに書き込む
;=================================================
SAVE:
	CALL	GET_ARGS			;(ARG0)=ファイルパス＋ファイル名の格納アドレス、(ARG1)=先頭アドレス,(ARG2)=終了アドレス
	PUSH	HL				;
	CALL	IS_FAT16			;
	LD	C,ATRB_FILE			;
	CALL	PREP_DENT			;
	CALL	IS_READ_ONLY			;
	LD	HL,EXT_SAVE_TABLE		;
	CALL	EXT_TABLE_JUMP			;拡張子に対応したセーブルーチンへジャンプする
	CALL	WRITE_DENT			;
	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD			;

;=================================================
;[CMD] ファイルパスで指定されたディレクトリにエントリを作成する
;IN  (ARG0)=ファイルパス＋エントリ名,C=作成するエントリの属性
;OUT (ARG0)=エントリ名の先頭アドレス
;=================================================
PREP_DENT:
	PUSH	BC				;
	CALL	CHANGE_WDIR			;
	LD	(ARG0),HL			;
	POP	BC				;
	CALL 	TOUCH				;
	CALL	SET_DENT_FAT			;
	RET

;=================================================
;[CMD]POLL命令 ワーキングディレクトリを変更する
;=================================================
POLL:
	CALL	STR2BUFF			;
	PUSH	HL				;
	CALL	IS_FAT16			;
	LD	HL,STR_BUFF			;
	CALL	TRACE_PATH			;
	JP	CLOSE_CMD			;

;=================================================
;[CMD]KILL命令 ファイルを削除する
;=================================================
KILL:
	CALL	STR2ARG0			;
	PUSH	HL				;
	CALL	IS_FAT16			;
	LD	HL,MSG_KILL_FILE		;
	CALL	YES_NO				;
	JR	NZ,.EXIT			;
	CALL	CHANGE_WDIR			;
.L1:	LD	C,ATRB_FILE			;
	CALL	GET_DENT			;
	JP	Z,ERR_NOT_FOUND
	CALL	IS_READ_ONLY			;
	LD	HL,(DIR_ENTRY+IDX_FAT)		;
	LD	A,H				;FATエントリが0000Hならディレクトリエントリのみ削除する
	OR	L				;それ以外は
	CALL	NZ,ERASE_FAT_LINK		;FATリンク先をすべて消去する
.DIR:	LD	HL,DIR_ENTRY			;ディレクトリエントリバッファの先頭に0E5Hをセットする
	LD	(HL),ID_DISABLED		;これによりディレクトリエントリが無効になる
	CALL	WRITE_DENT			;ディレクトリエントリバッファをファイルバッファにコピーする
	CALL	FLUSH_BFFR			;全バッファ書き込み
	CALL	RESTORE_WDIR			;
.EXIT:	JP	CLOSE_CMD

;=================================================
;[CMD]MOUNT命令 SDカードのプライマリパーティションをマウントする
;=================================================
MOUNT:
	PUSH	HL
	CALL	INIT_8255			;PPI初期化
	CALL	MMC_INIT			;MMC初期化
	CALL	READ_MBR			;パーティション開始セクタ＃をセットする
	CALL	READ_IPL			;FAT16フォーマットチェック
	CALL	READ_BPB			;BPB情報から導かれる定数をワークにセットする
	CALL	INIT_FAT16			;FAT16関連ワーク初期化！バッファクリアのため必ず最後に実行する！
	CALL	PRT_VOLUME			;ボリューム名表示
;	CALL	IS_YEAR79			;日付が未入力ならメッセージを出力
	POP	HL				;
	CALL	AUTOEXEC			;
	RET					;

;=================================================
;[CMD]FILES命令 指定されたディレクトリのエントリ一覧を表示する
;=================================================
FILES:
	CP	":"				;
	JR	Z,.L1				;
	OR	A				;
	JR	Z,.L1				;
	CALL	POLL				;
.L1:	PUSH	HL				;
	CALL	IS_FAT16			;
	LD	HL,(WDIR_CLSTR)			;
	LD	IY,PRT_DENT			;
	CALL	DIR_WALK			;
	POP	HL				;
	RET					;

;=================================================
;[CMD]MERGE命令 メモリの内容をCMTファイルに追記する
;=================================================
MERGE:
	CALL	GET_ARGS			;
	PUSH	HL				;
	CALL	IS_FAT16			;
	CALL	CHANGE_WDIR			;
	LD	C,ATRB_FILE			;
	CALL	GET_DENT			;
	JP	Z,ERR_NOT_FOUND			;
	CALL	IS_READ_ONLY			;
	CALL	SET_FP_END			;FPをファイル終端にセットする
	CALL	WRITE_CMT.MERGE			;CMTファイルの追記実行
	CALL	WRITE_DENT			;
	CALL	RESTORE_WDIR			;
	POP	HL				;
	RET					;

;=================================================
;[CMD]NAME命令 ディレクトリエントリ名を変更する
;=================================================
NAME:
	CALL	GET_2STR_ARGS			;２つの文字列の先頭アドレスを引数にセットする
	PUSH	HL				;
	CALL	IS_FAT16			;
	CALL	CHANGE_WDIR			;
	LD	(ARG0),HL			;
	LD	HL,(ARG1)			;
	PUSH	HL				;新しいエントリ名を退避
	LD	C,00H				;
	CALL	GET_DENT			;
	JP	NZ,ERR_EXISTS			;存在していればエラー
	LD	HL,(ARG0)			;HL<-現在のエントリ名の先頭アドレス
	LD	C,00H				;
	CALL	GET_DENT			;
	JP	Z,ERR_NOT_FOUND			;存在しなければエラー
	CALL	IS_READ_ONLY			;
	POP	HL				;新しいエントリ名を復帰
	CALL	STR2SFN				;現在のディレクトリエントリ名を新しいエントリ名で上書きする
	LD	HL,DIR_ENTRY+IDX_TIME		;ディレクトリエントリバッファの「更新日時」に現在日時をセットする
	CALL	SET_DATETIME			;
	CALL	WRITE_DENT			;
	CALL	RESTORE_WDIR			;
	JP	CLOSE_CMD			;

;=================================================
;[CMD]２つの文字列の先頭アドレスを引数にセットする
;IN  HL=TP
;OUT HL=TP,(ARG0)=1番目の文字列,(ARG1)=2番めの文字列
;=================================================
GET_2STR_ARGS:
	CALL	OPEN_DQUOTE			;
	LD	(ARG0),HL			;
	CALL	CLOSE_DQUOTE			;
	DEC	HL				;！重要！
	RST	10H				;
	CALL	TPSEEK				;
	DB	","				;
	CALL	OPEN_DQUOTE			;
	LD	(ARG1),HL			;
	CALL	CLOSE_DQUOTE			;
	RET

;=================================================
;[CMD]テキストポインタを適切な位置に合わせてBASIC解析を実行する
;=================================================
CLOSE_CMD:
	POP	HL				;
	DEC	HL				;！重要！
	RST	10H				;
	RET					;

;=================================================
;[CMD]ARG0とARG1を交換する
;=================================================
SWAP_ARGS:
	LD	HL,(ARG0)			;
	PUSH	HL				;
	LD	HL,(ARG1)			;
	LD	(ARG0),HL			;
	POP	HL				;
	LD	(ARG1),HL			;
	RET					;

;=================================================
;[CMD]クラスタ内の全セクタをゼロクリアする
;IN  HL=クラスタ＃,IX=バッファ構造体
;OUT 
;=================================================
CLR_CLSTR:
	CALL	DW0_PUSH			;セクタ＃を退避
	CALL	GET_FIRST_SCTR			;
	CALL	CLR_BFFR			;バッファIXをゼロクリアする
	LD	A,(SCTRS_PER_CLSTR)		;
	LD	B,A				;B<-１クラスタあたりのセクタ数
.L1:	PUSH	BC				;
	LD	HL,DW0				;バッファ構造体のセクタ＃を更新する
	PUSH	IX				;
	POP	DE				;
	CALL	DW_COPY				;(IX+0)<-(DW0)
	LD	(IX+IDX_BUPD),TRUE		;バッファの更新フラグを立てる
	CALL	SAVE_BFFR			;バッファIXを書き込む
	CALL	DW0_INC				;セクタ＃++
	POP	BC				;
	DJNZ	.L1				;
	CALL	DW0_POP				;セクタ＃を復帰
	RET

;=================================================
;[CMD]文字列式の結果が格納されたアドレスを(ARG0)にセットする
;IN  
;OUT (ARG0),HL=TP
;=================================================
STR2ARG0:
	CALL	STR2BUFF			;
	LD	DE,STR_BUFF			;
	LD	(ARG0),DE			;
	RET					;

