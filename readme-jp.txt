この度は本商品をダウンロードいただき誠にありがとうございます。

<商品名>
  VRoidヘアプリセットマージツール(Ruby) v0.6(20210320)

<制作者の表示> 
  八雲 佐世(Twitter: @yakumo_sayo)

  本素材データの著作権及び著作者人格権等のその他一切の権利は、頭記製作者に帰属します。
  Copyright(C) 2019-2021  Yakumo Sayo, Susanoo Lab. All Right Reserved.

<ライセンス>
   GPLv3もしくは作者が個別に定めるライセンス

<開発レポジトリ>
   https://github.com/yakumo-proj/vroid_hair_preset_merger


<内容物>
・readme-jp.txt  
　　これ
・hair_merge.rb
　　プログラム本体

<使用方法>
※前のバージョンと引数設定などが変わってます

0. 前提
・お使いのPCにRuby 2.xがインストールされていること。

1. VRoidでのヘアスタイルプリセットデータに書き出します。

任意のVRoidデータをロードし、ヘアスタイルをプリセットに登録します。
presetXXXX（XXXXは番号）みたいなフォルダができます。

Windowsの場合
  C:\Users\<YourName>\AppData\LocalLow\pixiv\VRoidStudio\hair_presets
MacOSの場合
  /Users/<YourName>/Library/Application Support/com.Company.ProductName/hair_presets

合成したい２つのプリセットが保存された状態にします。
便宜上これをプリセットA、プリセットBとします。

2. 合成対象のプリセットを再作成
プリセットAがVRoidのモデルにロードされた状態で、合成したい対象のプリセットBをロードし、
プリセットを保存し直します。これを プリセットB' とします。
　なぜかこうするとマテリアルの参照が壊れないようにするおまじないです。

3. Rubyスクリプトを実行

コマンドラインからrubyを実行し、プリセットA と プリセットB' を統合したプリセットCを作成します。
プリセットAの通し番号が1000、 Bが1001、 B' が1002 であるとするならCは1003にしましょう。

% ruby hair_merge.rb preset1000 preset1002 preset1003

(カレントディレクトリがhair_presetフォルダの状態)
となります。

また第４引数として、プリセット一覧に表示されるプリセット名を指定することができます。
(Windowsの人は日本語を入れたい場合は後述の方法をお試しください)

% ruby hair_merge.rb preset1000 preset1002 preset1003 "1002 Shino Nekomimi" 
（このプリセット名には日本語も使えますが、preset.jsonとrubyの標準エンコーディングが
UTF-8である関係上、Windowsではちょっと工夫がいるかもしれません）

4. VRoid Studioを再度立ち上げる
プリセットが正常に読めているか確認してください。

※Windowsで日本語のプリセット名を使いたい方向け
コマンドプロンプトの文字コードをUTF-8に変更する必要があったりするかも。
   chcp 65001
とタイプしてから本コマンドを実行してください。

※こちらの記事を参照
https://qiita.com/user0/items/a9116acc7bd7b70ecfb0

あるいはRubyをSJIS(CP932)で動かすため、-Ksオプションで動くように改造する方法もあるかもしれません。
その場合文字コードの扱いがまためんどくさいことになるので面倒だから私はやりません。
