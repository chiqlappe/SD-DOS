# PC-8001 SD-DOS

## このプログラムについて
* 初代PC-8001の拡張ポートに接続されたmicroSDドライブと拡張RAM(8KBバッテリバックアップRAMまたは64KB RAM)を使って、SDメモリカードの読み書きを行います
* FAT16とCMTファイルに対応
* 詳しくはMANUAL.txtを御覧ください

## ソースをアセンブルする方法
 * PC-8001エミュレータj80付属のtools80でアセンブル可能です

`java -jar tools80.jar -tgt:z80 main.asm`

## リンク
* [PC-8001用 8KB拡張RAMボード](https://github.com/chiqlappe/ram8k)
* [PC-8001用 micorSDドライブ](https://github.com/chiqlappe/sdd)
