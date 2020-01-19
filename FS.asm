
;=================================================
;[FS]自動実行
;・"/HELLO.CMT"が存在すればロードしてBASICを実行する
;=================================================
AUTOEXEC:
	IN	A,(08H)				;
	AND	01000000B			;"SHIFT"キーが押されていたらキャンセルする
	RET	Z				;

	PUSH	HL
	LD	HL,.NAME			;
	CALL	STR2BUFF			;
	LD	HL,STR_BUFF			;
	CALL	IS_FILE				;
	POP	HL				;
	RET	Z				;

	PUSH	HL
	LD	HL,.NAME			;
	CALL	STR2BUFF			;
	LD	HL,STR_BUFF			;
	LD	(ARG0),HL			;
	POP	HL				;
	CALL	LOAD.E1				;
	POP	HL				;！重要！
	JP	RUN

.NAME:	DB	DQUOTE,"/HELLO.CMT",EOL		;

;=================================================
;[FS]ファイルが存在するかを調べる
;IN  HL=パス文字列の先頭アドレス
;OUT Z=1:存在しない
;=================================================
IS_FILE:
	LD	(ARG0),HL			;
	CALL	CHANGE_WDIR			;
	LD	C,ATRB_FILE			;
	CALL	GET_DENT			;
	CALL	RESTORE_WDIR			;
	RET					;

;=================================================
;[FS]文字列式を評価して文字列バッファに格納する
;=================================================
STR2BUFF:
	CALL	EVALEXP				;式を評価
	PUSH	HL				;TP退避
	CALL	549CH				;DE<-結果の文字列の先頭アドレス
	DEC	HL				;
	DEC	HL				;
	LD	B,(HL)				;B<-結果の文字列全体の長さ
	LD	C,STR_BUFF_SIZE-1		;C<-文字列バッファの長さ。終端識別コード用に１文字分減らす
	LD	HL,STR_BUFF			;HL<-文字列バッファの先頭アドレス
.L2:	LD	A,(DE)				;
	LD	(HL),A				;
	INC	HL				;
	INC	DE				;
	DEC	C				;
	JR	Z,.L3				;
	DJNZ	.L2				;
.L3:	LD	(HL),EOL			;終端コードをセットする
	POP	HL				;
	RET					;

;=================================================
;[FS]FAT16関連ワーク初期化
;=================================================
INIT_FAT16:
	LD	HL,ROOT				;
	LD	(WDIR_CLSTR),HL			;ワーキングディレクトリのクラスタ＃<-ルートディレクトリ
	LD	HL,MIN_CLSTR			;
	LD	(TGT_CLSTR),HL			;ターゲットクラスタ＃<-最小クラスタ＃
	CALL	INIT_BFFR			;バッファ関連ワーク初期化
	LD	HL,DNAME			;ディレクトリエントリ文字列の文字数
	LD	(HL),DNAME_SIZE			;
	LD	HL,ATRB				;ファイル属性文字列の文字数
	LD	(HL),ATRB_SIZE			;
	RET					;

;=================================================
;[FS]ボリューム名を表示する
;=================================================
PRT_VOLUME:
	LD	HL,ROOT_SCTR			;(DW0)<-ルートディレクトリの開始セクタ＃
	LD	DE,DW0				;
	CALL	DW_COPY				;
	LD	IX,FILE_BFFR_STRCT		;
	CALL	LOAD_BFFR			;ルートディレクトリの開始セクタをバッファIXに読み込む
	LD	L,(IX+IDX_BADR)			;HL<-データポインタ=バッファの先頭アドレス
	LD	H,(IX+IDX_BADR+1)		;
	CALL	IPRINT				;
	DB	"Vol:",EOL			;
	LD	B,DNAME_SIZE			;
.L1:	LD	A,(HL)				;
	INC	HL				;
	RST	18H				;
	DJNZ	.L1				;
	CALL	PUT_CR				;
	RET					;

;=================================================
;[FS]ファイルサイズを16進数で現在位置に出力する
;IN  IX=ディレクトリポインタ
;OUT -
;=================================================
PRT_FSIZE:
	PUSH	HL				;
	LD	A,(IX+1EH)			;
	OR	(IX+1FH)			;
	LD	A," "				;
	JR	Z,.L1				;
	LD	A,"+"				;FFFFHより大きい場合は"+"を付ける
.L1:	RST	18H				;
	LD	L,(IX+1CH)			;
	LD	H,(IX+1DH)			;
	CALL	PRTHLHEX			;
	POP	HL				;
	RET					;

;=================================================
;[FS]FAT16のSDがマウントされているかをチェックする
;=================================================
IS_FAT16:
	PUSH	HL				;
	CALL	MMC_INIT			;MMCをSPIモードに初期化する。オンラインでなければタイムアウトになるはず？
	POP	HL				;
	LD	A,(SCTRS_PER_CLSTR)		;
	OR	A				;
	RET	NZ				;
	LD	HL,MSG_NOT_FAT16		;
	JP	ERR				;

;=================================================
;[FS]MBRの読み込み
;IN  
;OUT (PP_SCTR)
;=================================================
READ_MBR:
	LD	HL,MMCADR0			;MMCアドレスを00000000Hにセット
	CALL	DW_CLR				;
	LD	HL,PP_SCTR			;プライマリパーティションの開始セクタ＃を00000000Hにセット
	CALL	DW_CLR				;
	LD	HL,FILE_BFFR			;MBRをバッファに読み込む
	LD	B,01H				;
	PUSH	HL				;
	CALL	MMC_READ			;
	POP	HL				;セクタ＃0の最初のバイトが00Hならパーティションが切られているとする
	LD	A,(HL)				;
	OR	A				;
	RET	NZ				;
	LD	DE,IDX_PP_SCTR			;「プライマリパーティションの開始セクタ＃」をワークに保存する
	ADD	HL,DE				;
	LD	DE,PP_SCTR			;
	CALL	DW_COPY				;
	RET					;

;=================================================
;[FS]IPLの読み込み
;IN  
;OUT (BPB)
;=================================================
READ_IPL:
	LD	HL,BPB				;BPB用ワークをクリアする
	LD	DE,BPB+1			;
	LD	(HL),00H			;
	LD	BC,0013H-1			;
	LDIR					;
	CALL	DW0_CLR				;(DW0)<-00000000H
	LD	HL,FILE_BFFR			;
	PUSH	HL				;
	CALL	READ_SCTR			;IPL領域をバッファに読み込む
	POP	HL				;
	PUSH	HL				;バッファアドレス退避
	LD	DE,0036H			;HL<-「FATタイプ文字列」の先頭アドレス
	ADD	HL,DE				;
	LD	DE,FAT_CODE			;コードと照合する
	LD	BC,0008H			;=文字数
.L1:	LD	A,(DE)				;
	CPI					;HL++,BC--
	JR	Z,.L2				;
	LD	HL,MSG_NOT_FAT16		;
	JP	ERR				;
.L2:	INC	DE				;
	JP	PE,.L1				;
	POP	HL				;バッファアドレス復帰
	LD	DE,IDX_BPB			;HL<-BPB領域の先頭アドレス
	ADD	HL,DE				;
	LD	DE,BPB				;BPBをワークに保存する
	LD	BC,0013H			;
	LDIR					;
	RET					;

;=================================================
;[FS]BPBから必要な定数を求める
;・(ROOT_SCTR)<-FAT開始セクタ＃+FAT１面に必要なセクタ数*2
;・(DATA_SCTR)<-ルートディレクトリのセクタ＃+(総ルートディレクトリ数*ディレクトリサイズ)/セクタサイズ
;=================================================
READ_BPB:
	LD	HL,FAT_SCTR			;(FAT_SCTR)<-FAT開始セクタ＃
	CALL	DW_CLR				;
	LD	DE,(FAT_START)			;
	LD	(HL),E				;
	INC	HL				;
	LD	(HL),D				;
	LD	HL,DW0				;HL<-DW0
	PUSH	HL				;
	CALL	DW0_CLR				;(DW0)<-00000000H
	EX	DE,HL				;DE=DW0
	LD	HL,(FAT_SIZE)			;HL<-(BPB+11)=FAT１面に必要なセクタ数
	ADD	HL,HL				;HL<-(BPB+11)*2
	EX	DE,HL				;DE=(BPB+11)*2,HL=DW0
	LD	(HL),E				;(DW0)<-(BPB+11)*2
	INC	HL				;HL++
	LD	(HL),D				;
	POP	HL				;HL=DW0
	LD	DE,FAT_SCTR			;DE<-FAT_SCTR
	CALL	DW_ADD				;(DW0)<-(FAT_SCTR)+(BPB+11)*2
	LD	DE,ROOT_SCTR			;
	CALL	DW_COPY				;(ROOT_SCTR)<-(DW0)=(FAT_SCTR)+(BPB+11)*2
	LD	HL,(ROOT_SIZE)			;=総ルートディレクトリ数
	ADD	HL,HL				;=X*2
	ADD	HL,HL				;=X*4
	ADD	HL,HL				;=X*8
	ADD	HL,HL				;=X*16
	ADD	HL,HL				;=X*32=総ルートディレクトリ数*ディレクトリのサイズ
	OR	A				;CY<-0
	LD	C,00H				;ルートディレクトリの総セクタ数を求める
	LD	DE,SCTR_SIZE			;=200H
.L1:	SBC	HL,DE				;HL<-HL-200H
	INC	C				;
	JR	NC,.L1				;
	DEC	C				;
	LD	HL,ROOT_SCTR_SIZE		;ルートディレクトリの総セクタ数<-C
	LD	(HL),C				;
	LD	HL,ROOT_SCTR			;
	LD	DE,DATA_SCTR			;
	PUSH	DE				;
	CALL	DW_COPY				;(DATA_SCTR)<-(ROOT_SCTR)
	POP	HL				;HL<-DATA_SCTR
	LD	A,(HL)				;(DATA_SCTR)<-(ROOT_SCTR)+C
	ADD	A,C				;
	LD	(HL),A				;
	INC	HL				;
	LD	A,(HL)				;
	ADC	A,0				;
	LD	(HL),A				;
	RET					;

;=================================================
;[FS]セクタ＃から物理アドレスを求める
;IN  (DW0)=セクタ＃
;OUT (MMCADR0)=物理アドレス
;=================================================
GET_PHYSICAL_ADRS:
	PUSH	DE				;
	PUSH	HL				;
	CALL	DW0_PUSH			;(DW0)を退避
	LD	HL,PP_SCTR			;(DW0)<-セクタ＃+プライマリパーティションの開始セクタ＃
	LD	DE,DW1				;
	CALL	DW_COPY				;
	CALL	DW0_ADD				;
	CALL	DW_X512				;(MMCADR0)<-セクタ＃*セクタサイズ=物理アドレス
	LD	HL,DW0				;
	LD	DE,MMCADR0			;
	CALL	DW_COPY				;
	CALL	DW0_POP				;(DW0)を復旧
	POP	HL				;
	POP	DE				;
	RET					;

;=================================================
;[FS]セクタを指定領域に読み込む
;IN  (DW0)=読み込みたいセクタ＃,HL=メモリ領域の先頭アドレス
;OUT (MMCADR0~3)
;=================================================
READ_SCTR:
	CALL	GET_PHYSICAL_ADRS		;(MMCADR0)<-セクタ＃(DW0)の物理アドレス
	LD	B,01H				;=MMCブロック数
	CALL	MMC_READ			;メモリ<-セクタデータ200Hバイト
	RET					;

;=================================================
;[FS]指定領域をセクタに書き込む
;IN  (DW0)=書き込みたいセクタ＃,HL=メモリ領域の先頭アドレス
;OUT (MMCADR0~3)
;=================================================
WRITE_SCTR:
	CALL	GET_PHYSICAL_ADRS		;(MMCADR0)<-セクタ＃(DW0)の物理アドレス
	LD	B,01H				;=MMCブロック数
	CALL	MMC_WRITE			;セクタ<-メモリデータ200Hバイト
	RET					;

;=================================================
;[FS]クラスタの開始セクタ＃を求める
;IN  HL=クラスタ＃
;OUT (DW0)=セクタ＃
;=================================================
GET_FIRST_SCTR:
	PUSH	BC				;
	PUSH	DE				;
	PUSH	HL				;
	LD	A,H				;HL=0000H ?
	OR	L				;
	JR	NZ,.L1				;
	LD	HL,ROOT_SCTR			;(DW0)<-ルートディレクトリの開始セクタ＃
	LD	DE,DW0				;
	CALL	DW_COPY				;
	JR	.EXIT				;
.L1:	DEC	HL				;HL<-HL-2
	DEC	HL				;
	LD	A,(SCTRS_PER_CLSTR)		;=１クラスタ当たりのセクタ数
	LD	E,A				;
	LD	D,00H				;
	CALL	HLXDE				;(DW0)<-HL*DE
	LD	HL,DW0				;
	LD	DE,DATA_SCTR			;
	CALL	DW_ADD				;(DW0)<-セクタ＃
.EXIT:	POP	HL				;
	POP	DE				;
	POP	BC				;
	RET					;

;=================================================
;[FS]ワーキングディレクトリ内からファイルを探して、そのクラスタ＃を求める
;IN  HL=ファイル名の先頭アドレス
;OUT (TGT_CLSTR)=一致したファイルのクラスタ＃
;=================================================
DNAME2CLSTR:
	LD	C,ATRB_FILE			;
	CALL	GET_DENT			;
	JP	Z,ERR_NOT_FOUND			;
	LD	HL,(DIR_ENTRY+IDX_FAT)		;=一致したファイルのクラスタ＃
	LD	A,H				;クラスタ＃が0000Hなら空ファイルなのでエラーへ
	OR	L				;
	JP	Z,ERR_EMPTY_FILE		;
	LD	(TGT_CLSTR),HL			;一致したファイルのクラスタ＃をターゲットクラスタにセットする
	RET					;

