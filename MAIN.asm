
;=================================================
;PC-8001 SD-SYSTEM
;=================================================

;・要望、不具合報告はTwitter @chiqlappe宛にお願いします。


INCLUDE "LABELS.ASM"
INCLUDE	"N80.ASM"

DEBUG	EQU	FALSE				;

	ORG	06000H

	DB	"AB"				;自動起動用マーカー

if DEBUG
	CALL	INIT_DEBUG			;デバッグルーチン初期化
endif

	CALL	INIT_FAT16			;FAT16関連ワーク初期化
	CALL	INIT_DW				;ダブルワード用スタック初期化
	CALL	INIT_CMDHOOK			;コマンドフック書き換え
	CALL	INIT_FKEY			;ファンクションキー設定変更
	CALL	INIT_BASIC			;BASIC初期化
	CALL	CMD_ON				;インフォメーションスイッチ

	LD	HL,MSG_TITLE			;タイトル表示
	CALL	PRINT				;
	RET					;

;=================================================
;BASIC初期化
;=================================================
INIT_BASIC:
	LD	HL,0EF58H			;ストリングディスクリプタ初期化
	LD	(0EF56H),HL			;
	LD	HL,8021H			;
	LD	(BASBEGIN),HL			;BASIC先頭アドレス
	INC	HL				;
	INC	HL				;
	LD	(VARBEGIN),HL			;変数先頭アドレス
	INC	HL				;
	INC	HL				;
	LD	(ARRBEGIN),HL			;配列先頭アドレス
	INC	HL				;
	INC	HL				;
	LD	(FREBEGIN),HL			;フリーエリア先頭アドレス
	RET					;

;=================================================
;ファンクションキー登録
;=================================================
INIT_FKEY:
	LD	HL,FKEYDATA			;
	LD	DE,.DATA			;
	LD	C,03H				;
.L2:	LD	B,05H				;
.L1:	LD	A,(DE)				;
	LD	(HL),A				;
	INC	HL				;
	INC	DE				;
	DJNZ	.L1				;
	CALL	.L3				;
	DEC	C				;
	JR	NZ,.L2				;
	RET					;

.L3:	PUSH	BC				;
	XOR	A				;
	LD	B,11				;
.L4:	LD	(HL),A				;
	INC	HL				;
	DJNZ	.L4				;
	POP	BC				;
	RET					;

.DATA:	DB	"mount"				;F1
	DB	"load "				;F2
	DB	"files"				;F3

;=================================================
;コマンドフックの書き換え
;=================================================
INIT_CMDHOOK:
	LD	HL,FILES			;ファイル一覧を表示する
	LD	(ENT_FILES),HL			;
	LD	HL,LOAD				;ファイルをロードする
	LD	(ENT_LOAD),HL			;
	LD	HL,MOUNT			;SDCをマウントする
	LD	(ENT_MOUNT),HL			;
	LD	HL,SAVE				;ファイルをセーブする
	LD	(ENT_SAVE),HL			;
	LD	HL,CMD				;汎用コマンド
	LD	(ENT_CMD),HL			;
	LD	HL,KILL				;ファイルを削除する
	LD	(ENT_KILL),HL			;
	LD	HL,POLL				;ワーキングディレクトリを変更する
	LD	(ENT_POLL),HL			;
	LD	HL,MERGE			;CMTファイルにプログラムを追記する
	LD	(ENT_MERGE),HL			;
	LD	HL,NAME				;ファイル名を変更する
	LD	(ENT_NAME),HL			;

	LD	HL,RBYTE			;任意のファイルをロードする
	LD	(ENT_RBYTE),HL			;

	RET					;

;=================================================
;インクルードファイル
;=================================================

if DEBUG
INCLUDE "DEBUG.asm"				;デバッグ用ツール
endif

INCLUDE	"MMC.asm"				;MMCドライバ
INCLUDE	"FAT.asm"				;FAT
INCLUDE	"BUFFER.asm"				;バッファ
INCLUDE	"CD.asm"				;ディレクトリ変更
INCLUDE	"DIR.asm"				;ディレクトリエントリ
INCLUDE	"FS.asm"				;ファイルシステム
INCLUDE	"SUBS.asm"				;汎用サブルーチン
INCLUDE	"DWORD.asm"				;ダブルワード
INCLUDE	"FP.asm"				;ファイルポインタ
INCLUDE	"TP.asm"				;テキストポインタ
INCLUDE	"CMT.asm"				;CMTファイル関連
INCLUDE	"BIN.asm"				;BINファイル関連
INCLUDE	"BAS.asm"				;BASファイル関連
INCLUDE	"RAW.asm"				;任意ファイル関連
INCLUDE	"DATE.asm"				;日時
INCLUDE	"DUMP.asm"				;ダンプ表示
INCLUDE	"CMD.asm"				;コマンド
INCLUDE	"STR.asm"				;文字列処理
INCLUDE "MESSAGES.asm"				;メッセージ文字列
INCLUDE	"ERROR.asm"				;エラー処理

;=================================================
;固定データ
;=================================================

FAT_CODE:
	DB	"FAT16   "			;FAT識別コード

NG_CHR:
	DB	";" , "[" , "]" , ":" , DQUOTE	;エントリ名に使用できない文字
	DB	";" , "|" , "=" , "," , "\"	;
	DB	" " , "/"			;
NG_CHR_END	EQU	$			;


CMD_TABLE:
	DB	"F",EOL				;CMD F フリーエリア拡張
	DB	95H,EOL				;CMD ON インフォメーションスイッチ オン 95H="ON"の中間言語コード
	DB	"OFF",EOL			;CMD OFF インフォメーションスイッチ オフ
	DB	"P",EOL				;CMD P プロパティ表示
	DB	"R",EOL				;CMD R ファイル実行
	DB	"V",EOL				;CMD V チェックサム算出
	DB	"CP",EOL			;CMD CP ファイルコピー
	DB	"D",EOL				;CMD D セクタダンプ
	DB	"EX",EOL			;CMD EX サブディレクトリ拡張
	DB	"MD",EOL			;CMD MD サブディレクトリ作成
	DB	"S",EOL				;CMD S ディレクトリエントリ名でセクタダンプ
	DB	EOL				;END MARKER

JUMP_TABLE:
	DW	CMD_F				;
	DW	CMD_ON				;
	DW	CMD_OFF				;
	DW	CMD_P				;
	DW	CMD_R				;
	DW	CMD_V				;
JT_CP:	DW	DISKB_ERR			;
JT_D:	DW	DISKB_ERR			;
JT_EX:	DW	DISKB_ERR			;
JT_MD:	DW	DISKB_ERR			;
JT_S:	DW	DISKB_ERR			;

EXT_LOAD_TABLE:					;ファイル読み込み用サブルーチンテーブル
						;・拡張子 3BYTE,ジャンプ先アドレス 2BYTE
	DB	"CMT"				;
	DW	READ_CMT			;
	DB	"BIN"				;
	DW	READ_BIN			;
	DB	"BAS"				;
	DW	READ_BAS			;
	DB	EOL				;

EXT_SAVE_TABLE:					;ファイル書き込み用サブルーチンテーブル
						;・拡張子 3BYTE,ジャンプ先アドレス 2BYTE
	DB	"CMT"				;
	DW	WRITE_CMT			;
	DB	"BIN"				;
	DW	WRITE_BIN			;
	DB	"BAS"				;
	DW	WRITE_BAS			;
	DB	EOL				;

;DEFAULT_EXT:					;
;	DB	"CMT"				;

;=================================================
;ワークエリア
;=================================================

WORK_AREA:

FAT_BFFR:	DS	200H			;FATバッファ
FILE_BFFR:	DS	200H			;ファイルバッファ

ARG0:		DS	02H			;コマンドの入力パラメータ
ARG1:		DS	02H			;
ARG2:		DS	02H			;
ARG3:		DS	02H			;
ARGNUM:		DS	01H			;有効な入力パラメータの数 0~3

EXECFLG:	DS	01H			;ロード後実行フラグ
EXECADR:	DS	02H			;ロード後実行アドレス

FAT1_BFFR_STRCT:				;バッファ構造体（FAT用）
	.SCTR:	DS	04H			;+00 セクタ＃
	.BP:	DS	02H			;+04 バッファポインタ
	.FLG:	DS	01H			;+06 更新フラグ
FAT2_BFFR_STRCT:				;バッファ構造体（FAT2用）
	.SCTR:	DS	04H			;+00 セクタ＃
	.BP:	DS	02H			;+04 バッファポインタ
	.FLG:	DS	01H			;+06 更新フラグ
FILE_BFFR_STRCT:				;バッファ構造体（ファイル、ディレクトリ兼用）
	.SCTR:	DS	04H			;+00 セクタ＃
	.BP:	DS	02H			;+04 バッファポインタ
	.FLG:	DS	01H			;+06 更新フラグ

DNAME:		DS	01H			;DNAMEの文字数指定部 ！DIR_ENTRYの直前に置くこと！
DIR_ENTRY:	DS	20H			;+00 ディレクトリエントリ情報
DIR_ENTRY.SCTR:	DS	04H			;+32 収録先のセクタ＃
DIR_ENTRY.BP:	DS	02H			;+36 バッファポインタ

FOUND:		DS	01H			;指定されたディレクトリエントリが見つかったらTRUEになる
BPB:		DS	13H			;BPB保存エリア
PP_SCTR:	DS	04H			;プライマリパーティションの開始セクタ＃
ROOT_SCTR_SIZE:	DS	01H			;ルートディレクトリの総セクタ数
FAT_SCTR:	DS	04H			;FATの開始セクタ＃ BPB+3をコピーしてDWORD化する
ROOT_SCTR:	DS	04H			;ルートディレクトリの開始セクタ＃
DATA_SCTR:	DS	04H			;データエリアの開始セクタ＃

WDIR_CLSTR:	DS	02H			;ワーキングディレクトリの開始クラスタ＃
WDIR_ORG:	DS	02H			;ワーキングディレクトリの開始クラスタ＃退避用
TGT_CLSTR:	DS	02H			;ターゲット（ファイルまたはサブディレクトリ）の開始クラスタ＃

FP:		DS	04H			;ファイルポインタ
FP_CLSTR:	DS	02H			;FPと結びつくファイルのカレントクラスタ＃。FPと連動して変化する
FP_CLSTR_SN:	DS	02H			;FPが示すアドレスが、先頭から何番目のクラスタに含まれるかを示す！クラスタ＃ではない！
FP_SCTR_SN:	DS	01H			;FPが示すアドレスが、クラスタ内の何番目のセクタに含まれるかを示す！セクタ＃ではない！

ATRB:		DS	01H			;ファイル属性表示用文字列の文字数指定部
		DS	06H			;ファイル属性表示用文字列本体

FIREWALL:	DS	02H			;マシン語がこのアドレスより先に侵入しないようにする

TIMEOUT:	DS	01H			;MMCタイムアウトカウンタ
MMCADR0:	DS	01H			;MMCアドレス LSB
MMCADR1:	DS	01H			;
MMCADR2:	DS	01H			;
MMCADR3:	DS	01H			;MMCアドレス MSB

DWA:		DS	04H			;汎用ダブルワード変数
DW0:		DS	04H			;ダブルワード変数
DW1:		DS	04H			;ダブルワード変数
DW_SP_ORG:	DS	02H			;ダブルワード用スタックポインタの一時退避エリア
DW_SP:		DS	02H			;ダブルワード用スタックポインタ
		DS	10H			;ダブルワード用スタックエリア
DW_STACK	EQU	$			;

CP_SCTR:	DS	04H			;コピー先セクタ＃
CP_DENT:	DS	20H			;コピー先ディレクトリエントリ
CP_DENT.SCTR:	DS	04H			;コピー先ディレクトリエントリのセクタ＃
CP_DENT.BP:	DS	02H			;コピー先ディレクトリエントリのバッファポインタ

CHECKSUM:	DS	02H			;チェックサム用
INFO_SW:	DS	01H			;インフォメーション表示モード
IS_CALLBACK:	DS	01H			;コールバック実行フラグ
CALLBACK:	DS	02H			;コールバックアドレス

INFO_BUF:	DS	10H			;情報出力用文字列バッファ

FREE_AREA	EQU	$			;フリーエリア開始アドレス


;-----------------------------

;BPBから求められる値
SCTRS_PER_CLSTR	EQU	BPB+2			;１クラスタ当たりのセクタ数	  40H
FAT_START	EQU	BPB+3			;FAT開始セクタ＃		0008H
ROOT_SIZE	EQU	BPB+6			;総ルートディレクトリ数		0200H
FAT_SIZE	EQU	BPB+11			;FAT１面に必要なセクタ数	00F0H


;-----------------------------

INCLUDE	"EXT.asm"				;拡張命令群

