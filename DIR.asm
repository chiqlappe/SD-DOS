
;--------------------------
;ディレクトリエントリ構造
;--------------------------
;00~07H:ファイル名	:8	IDX_NAME
;08~0AH:拡張子		:3	IDX_EXT
;0B    :属性		:1	IDX_ATRB
;0C~0DH:未使用		:2
;0E~0FH:作成時刻	:2	IDX_CTIME
;10~11H:作成日時	:2	IDX_CDATE
;12~13H:アクセス日付	:2	IDX_ADATE
;14~15H:未使用		:2
;16~17H:更新時刻	:2	IDX_TIME
;18~19H:更新日付	:2	IDX_DATE
;1A~1BH:FATエントリ	:2	IDX_FAT
;1C~1FH:ファイルサイズ	:4	IDX_SIZE
;--------------------------

;=================================================
;[DIR]エントリ名と属性に一致するディレクトリエントリを探して(DIR_ENTRY)に格納する
;・ワーキングディレクトリ内が対象
;IN  HL=エントリ名の先頭アドレス,C=属性値
;OUT (DIR_ENTRY),Z=1:見つからなかった
;=================================================
GET_DENT:
	CALL	CLR_DENT_BFFR			;ディレクトリエントリバッファをクリアする
	LD	A,C				;
	LD	(DIR_ENTRY+IDX_ATRB),A		;
	CALL	STR2SFN				;テキストポインタの文字列を8.3形式ファイル名に変換し、(DIR_ENTRY+IDX_NAME)にセットする
.MAIN:	LD	HL,(WDIR_CLSTR)			;
	LD	IY,GET_DENT_SUB			;IY<-ディレクトリエントリ検索サブルーチン
	CALL	DIR_WALK			;ディレクトリ巡回処理
	LD	A,(FOUND)			;A<-結果フラグ
	OR	A				;不一致ならZ<-1
	RET					;

;=================================================
;[DIR]ディレクトリエントリの有効性をチェックする
;・無効なら直前の呼び出し元をキャンセルして、その親に戻す
;IN  HL=ディレクトリエントリの先頭アドレス
;OUT CY=1:エントリ終端
;=================================================
IS_VALID_DENT:
	LD	A,(HL)				;エントリの先頭が「無効」を示すIDなら
	CP	ID_DISABLED			;次のエントリへスキップする
	JR	NZ,.L1				;
	POP	AF				;戻りアドレスを捨てる
	OR	A				;CY<-0
	RET					;
.L1:	OR	A				;エントリの先頭が00Hなら終了へ
	RET	NZ				;
	POP	AF				;戻りアドレスを捨てる
	SCF					;終了フラグを立てる
	RET					;

;=================================================
;[DIR]読み込み専用属性チェック
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
;[DIR]ディレクトリエントリのFATエントリが空なら空きクラスタを探して、値をFATエントリとターゲットクラスタにセットする
;IN  (DIR_ENTRY+IDX_FAT)
;OUT (TGT_CLSTR)
;=================================================
SET_DENT_FAT:
	LD	HL,(DIR_ENTRY+IDX_FAT)		;HL<-FATエントリ
	LD	A,H				;
	OR	L				;
	JR	NZ,.L1				;FATエントリが0000Hなら空きクラスタを探す
	LD	HL,(TGT_CLSTR)			;空きクラスタを探す起点となるクラスタ＃
	CALL	FIND_NULL_CLSTR			;HL<-空きクラスタ＃
	JR	C,.FOUND			;
	LD	HL,MSG_MEDIA_FULL		;見つからなければエラー
	JP	ERR				;

.FOUND:	LD	(DIR_ENTRY+IDX_FAT),HL		;FATエントリ<-空きクラスタ＃
.L1:	LD	(TGT_CLSTR),HL			;ターゲットクラスタ<-FATエントリ
	RET

;=================================================
;[DIR]指定した属性と名前を持った、空のディレクトリエントリを作成する
;・FATエントリ値とファイルサイズは0にセットされる
;・ディレクトリエントリがすでに存在すれば、更新日時のみを新しくする
;IN  C=属性,HL=名前の先頭アドレス
;OUT Z=1:
;=================================================
TOUCH:
	CALL	GET_DENT			;すでに存在すればZ<-0
	JR	NZ,.UP				;
.NEW:	LD	HL,(WDIR_CLSTR)			;
	LD	IY,SEARCH_NULL_DENT		;IY<-ワーキングディレクトリから空エントリのアドレスを探すサブルーチン
	CALL	DIR_WALK			;
	LD	A,(FOUND)			;
	OR	A				;
	JR	NZ,.L1				;
	LD	HL,MSG_DIR_FULL			;見つからなければエラー
	JP	ERR				;

.L1:	LD	HL,DIR_ENTRY+IDX_CTIME		;ディレクトリエントリバッファの「作成日時」に現在日時をセットする
	CALL	SET_DATETIME			;
.UP:	LD	HL,DIR_ENTRY+IDX_TIME		;ディレクトリエントリバッファの「更新日時」に現在日時をセットする
	CALL	SET_DATETIME			;
	RET					;

;=================================================
;[DIR]ディレクトリエントリバッファの内容をメディアに書き込む
;IN  (DIR_ENTRY),(DIR_ENTRY.BP)
;=================================================
WRITE_DENT:
	LD	IX,FILE_BFFR_STRCT		;
	LD	HL,DIR_ENTRY.SCTR		;(DW0)<-ディレクトリエントリの格納先セクタ＃
	LD	DE,DW0				;
	CALL	DW_COPY				;
	CALL	LOAD_BFFR			;
	LD	HL,(DIR_ENTRY.BP)		;
	EX	DE,HL				;DE<-ディレクトリエントリの格納先アドレス
	LD	HL,DIR_ENTRY			;HL<-ディレクトリエントリバッファの先頭アドレス
	LD	BC,DENT_SIZE			;BC<-ディレクトリエントリバッファのサイズ
	LDIR					;ディレクトリエントリをファイルバッファにコピーする
	LD	(IX+IDX_BUPD),TRUE		;バッファの更新フラグを立てる
	CALL	SAVE_BFFR			;バッファを書き戻す
	RET					;

;=================================================
;[DIR]指定されたアドレスにエンコードされた現在日時をセットする
;IN  HL=書き込み先のアドレス
;OUT 
;=================================================
SET_DATETIME:
	PUSH	HL				;書き込み先のアドレスを退避
	CALL	TIME_READ			;システムワークに日時データをセットする
	LD	A,(DT_SEC)			;秒
	CALL	BCD2BIN				;
	LD	C,A				;
	LD	A,(DT_MIN)			;分
	CALL	BCD2BIN				;
	LD	E,A				;
	LD	A,(DT_HOUR)			;時
	CALL	BCD2BIN				;
	LD	D,A				;
	CALL	ENC_TIME			;IN:C,D,E OUT:HL=エンコードされた時刻
	EX	DE,HL				;
	POP	HL				;
	LD	(HL),E				;
	INC	HL				;
	LD	(HL),D				;
	INC	HL				;
	PUSH	HL				;書き込み先のアドレスを退避
	LD	A,(DT_YEAR)			;年 BCD形式
	CALL	BCD2BIN				;BCDをバイナリに変換 IN:A,OUT:A
	ADD	A,20				;FAT16では年の基準値が「1980」なので、入力値に20を加える 例:2019->19+20=39
	LD	D,A				;
	LD	A,(DT_MONTH)			;月
	CALL	BCD2BIN				;
	LD	E,A				;
	LD	A,(DT_DAY)			;日
	CALL	BCD2BIN				;
	LD	C,A				;
	CALL	ENC_DATE			;IN:C,D,E OUT:HL=エンコードされた日付
	EX	DE,HL				;DE=エンコードされた日付
	POP	HL				;HL=書き込み先のアドレス
	LD	(HL),E				;
	INC	HL				;HL++
	LD	(HL),D				;
	RET					;

;=================================================
;[DIR]ディレクトリの全エントリに対し共通な処理を行う
;・GET_DENT_SUB
;・SEARCH_NULL_DENT -> FIND_FREE_DENT
;・PRT_DENT -> PRT_DENT
;IN  HL=ディレクトリのクラスタ＃,IY=サブルーチンのアドレス
;OUT 
;=================================================
DIR_WALK:
	LD	A,FALSE				;発見フラグを降ろす
	LD	(FOUND),A			;
	LD	IX,FILE_BFFR_STRCT		;
	LD	A,H				;HL=0000Hならルートディレクトリの処理へ
	OR	L				;
	JR	Z,.ROOT				;
.L4:	PUSH	HL				;クラスタ＃を退避
	LD	A,(SCTRS_PER_CLSTR)		;B<-クラスタの総セクタ数
	LD	B,A				;
	CALL	GET_FIRST_SCTR			;(DW0)<-クラスタHLの開始セクタ＃
	JR	.L2				;

.ROOT:	PUSH	HL				;クラスタ＃を退避(スタック合わせのダミー)
	LD	A,(ROOT_SCTR_SIZE)		;B<-ルートディレクトリの総セクタ数
	LD	B,A				;
	LD	HL,ROOT_SCTR			;(DW0)<-ルートディレクトリの開始セクタ＃
	LD	DE,DW0				;
	CALL	DW_COPY				;
.L2:	PUSH	BC				;ループ回数を退避
	CALL	LOAD_BFFR			;セクタ(DW0)をバッファIXに読み込む
	LD	B,DENT_PER_SCTR			;=１セクタ当たりのディレクトリエントリ数
	LD	L,(IX+IDX_BADR)			;HL<-バッファの先頭アドレス
	LD	H,(IX+IDX_BADR+1)		;
.L1:	PUSH	BC				;
	PUSH	HL				;
	PUSH	IX				;
	LD	DE,.RET				;戻りアドレスをスタックに積む
	PUSH	DE				;
	JP	(IY)				;IY=共通処理のサブルーチンアドレス。BC,HL,IX保持。CY=1:EODで終了したことを示す

.RET:	POP	IX				;
	POP	HL				;
	POP	BC				;
	JR	C,.QUIT				;CY=1なら途中終了へ
.L3:	LD	DE,DENT_SIZE			;バッファポインタを次のエントリの先頭に進める
	ADD	HL,DE				;
	DJNZ	.L1				;ディレクトリエントリの数だけ繰り返す
	CALL	DW0_INC				;セクタ＃++
	POP	BC				;ループ回数を復帰
	DJNZ	.L2				;クラスタの最終セクタまで処理する
	POP	HL				;クラスタ＃を復帰
	LD	A,H				;
	OR	L				;
	RET	Z				;ルートディレクトリなら次のクラスタは無いので、ここで終了する
	CALL	READ_FAT_DATA			;DE<-HLクラスタのFATデータ
	EX	DE,HL				;HL=次のクラスタ＃,DE=不要
	INC	HL				;次のクラスタ＃がFFFFH（ファイルエンド）なら0000Hになる
	LD	A,H				;！INC命令ではフラグ変化しないので注意！
	OR	L				;
	RET	Z				;Z=1なら終了
	DEC	HL				;HLを戻す
	JR	.L4				;

.QUIT:	POP	BC				;ループカウンタBCを捨てる
	POP	HL				;クラスタ＃HLを捨てる
	RET					;

;=================================================
;[DIR]空のディレクトリエントリを探す
;・新しいファイルやディレクトリを作成する時に必要
;IN  HL=ディレクトリエントリの先頭アドレス
;OUT Z=0:見つからなかった
;=================================================
SEARCH_NULL_DENT:
	LD	A,(HL)				;
	CP	ID_DISABLED			;
	JR	Z,.FOUND			;
	OR	A				;CY<-0
	RET	NZ				;A!=0なら戻る ！CY=0になっていることに注意！
.FOUND:	CALL	DENT_FOUND			;エントリが見つかったことを知らせるフラグや値をセットする
	RET					;

;=================================================
;[DIR]エントリ名と属性が一致するディレクトリエントリを(DIR_ENTRY)に読み込む
;・DIR_WALK用サブルーチン
;・20H ファイル（アーカイブ）
;・10H ディレクトリ
;IN  HL=検索対象となるディレクトリエントリの先頭アドレス
;OUT (DIR_ENTRY),(FOUND)=TRUE:見つかった
;=================================================
GET_DENT_SUB:
	CALL	IS_VALID_DENT			;ディレクトリエントリの有効性をチェックする
	PUSH	HL				;ファイルバッファポインタを退避
	LD	DE,DIR_ENTRY			;DE<-ディレクトリエントリバッファの先頭アドレス
	LD	B,DNAME_SIZE			;
.L1:	LD	A,(DE)				;エントリ名を照合
	CP	(HL)				;
	JR	NZ,.EXIT			;一致しなければ終了
	INC	DE				;
	INC	HL				;
	DJNZ	.L1				;エントリ名の文字数だけ繰り返す
	LD	A,(HL)				;A<-検索される側の属性値
	LD	C,A				;属性値を退避
	AND	00001110B			;=ボリューム+システム+隠し属性
	JR	NZ,.EXIT			;いずれかのビットが立っていれば終了
	LD	A,C				;属性値を復帰
	AND	00010000B			;ディレクトリ属性以外をマスクする
	LD	C,A				;C<-マスクされた属性値
	LD	A,(DE)				;A<-検索する側の属性値
	OR	A				;00Hなら属性チェックを省略
	JR	Z,.FOUND			;
	AND	00010000B			;ディレクトリ属性以外をマスクする
	CP	C				;ディレクトリ属性のみを比較
	JR	NZ,.EXIT			;一致しなければ終了
.FOUND:	POP	HL				;バッファポインタを復帰
	PUSH	HL				;バッファポインタを退避
	LD	DE,DIR_ENTRY			;一致したディレクトリエントリを(DIR_ENTRY)にコピーする
	LD	BC,DENT_SIZE			;
	LDIR					;
	POP	HL				;バッファポインタを復帰
	CALL	DENT_FOUND			;一致したことを知らせるフラグや値をセットする
	RET					;

.EXIT:	OR	A				;CY<-0
	POP	HL				;
	RET					;

;=================================================
;[DIR]GET_DENT_SUBでエントリが見つかったことを知らせるフラグや値をセットする
;IN  HL=バッファポインタ,DW0=セクタ＃
;OUT (DIR_ENTRY.BP),(DIR_ENTRY.SCTR),(FOUND),CY<-1
;=================================================
DENT_FOUND:
	LD	(DIR_ENTRY.BP),HL		;ディレクトリエントリ情報のバッファポインタ<-HL
	LD	HL,DW0				;
	LD	DE,DIR_ENTRY.SCTR		;
	CALL	DW_COPY				;ディレクトリエントリ情報のセクタ＃<-(DW0)
	LD	A,TRUE				;発見フラグを立てる
	LD	(FOUND),A			;
	SCF					;終了フラグを立てる
	RET					;

;=================================================
;[DIR]エントリ名出力 FILES命令用
;・DIR_WALK用サブルーチン
;IN  HL=バッファポインタ
;OUT CY:1=END OF DATA
;=================================================
PRT_DENT:
	CALL	IS_VALID_DENT			;
	PUSH	BC				;
	PUSH	HL				;
	PUSH	IX				;
	PUSH	HL				;IX<-バッファポインタ
	POP	IX				;
	CALL	PAUSE				;一時停止処理
	JR	NZ,.L6				;STOPキーで中断
	SCF					;強制終了フラグを立てる
	JR	.EXIT2				;

.L6:	LD	A,(IX+0BH)			;=属性値
	LD	E,A				;
	AND	00001110B			;隠しファイル、システム、ボリューム属性を排除する
	JR	NZ,.EXIT			;
	LD	A,E				;
	AND	00010000B			;=「ディレクトリ」属性
	JR	NZ,.DIR				;
	CALL	IPRINT				;
	DB	"      ",DQUOTE,EOL		;
	JR	.NAME				;ファイル・ディレクトリ名表示へ

.DIR:	CALL	IPRINT				;ディレクトリマーク表示
	DB	"<DIR> ",DQUOTE,EOL		;
.NAME	LD	B,DNAME_SIZE			;ファイル・ディレクトリ名表示
	LD	C,00H				;空白カウンタ
.L1:	LD	A,(HL)				;
	CP	SPC				;空白をピリオドに置き換える
	JR	Z,.L3				;
.L2:	RST	18H				;
	INC	HL				;
	DJNZ	.L1				;
.L5:	LD	A,DQUOTE			;二重引用符表示
	RST	18H				;

IF FALSE
	CALL	IPRINT				;FATエントリ表示
	DB	3AH,27H,EOL			;
	LD	L,(IX+1AH)			;
	LD	H,(IX+1BH)			;
	CALL	PRTHLHEX			;
ENDIF


	LD	A,C				;位置合わせ用の空白表示
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
	CALL	PRT_FDATE			;日付表示
	CALL	PUT_SPC				;
	LD	E,(IX+16H)			;
	LD	D,(IX+17H)			;
	CALL	PRT_FTIME			;時刻表示
ELSE
	CALL	PRT_FSIZE			;ファイルサイズ出力
ENDIF


	CALL	PUT_CR				;改行
.EXIT:	OR	A				;CY<-0
.EXIT2:	POP	IX				;
	POP	HL				;
	POP	BC				;
	RET					;

.L4:	LD	A,(HL)				;空白部をピリオドに置き換える
	CP	SPC				;
	JR	Z,.L3				;
	PUSH	AF				;
	LD	A,"."				;
	RST	18H				;
	POP	AF				;
	DEC	C				;
	JR	.L2				;
.L3:	INC	HL				;バッファポインタ++
	INC	C				;空白カウンタ++
	DJNZ	.L4				;
	JR	.L5				;

;=================================================
;[DIR]ディレクトリエントリバッファをクリアする
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

