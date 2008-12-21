j
= パーサのデバッグ

ここでは、Racc を使っていくうえで遭遇しそうな問題について書きます。

== 文法ファイルがパースエラーになる

エラーメッセージに出ている行番号のあたりを見て間違いを
探してください。ブロックを閉じる行でエラーになる場合は、
どこかで開き括弧などを増やしてしまっている可能性が高いです。

== なんたら conflict って言われた

一番ありがちで一番面倒な問題は衝突 (conflict) でしょう。
文法中に衝突があると、racc はコンパイル後に
「5 shift/reduce conflict」のようなメッセージを表示します。
-v をつけると出力される .output ファイルからはさらに詳しい情報が得られます。
それをどう使うか、とかそういうことに関しては、それなりの本を読んでください。
とてもここに書けるような単純な話ではありません。
当然ながら『Ruby を 256 倍使うための本 無道編』(青木峰郎著)がお勧めです。

== パーサは問題なく生成できたけど予想どおりに動かない

racc に -g オプションをつけてパーサを出力すると、デバッグ用のコードが
付加されます。ここで、パーサクラスのインスタンス変数 @yydebug を true に
しておいてから do_parse/yyparse を呼ぶと、デバッグ用メッセージが出力
されます。パーサが動作する様子が直接見えますので、完全に現在の状態を
把握できます。これを見てどこがおかしいのかわかったらあとは直すだけ。

== next_token に関して

いまだ自分でも忘れることが多いのが
「送るトークンが尽きたら [false,なにか] を送る」ということです。
ちなみに Racc 0.10.2 以降では一度 [false,なにか] を受け取ったら
それ以上 next_token は呼ばないことが保証されています。

追記： 最近は [false,なにか] ではなく nil でもよいことになった。
e
= Debugging

== Racc reported syntax error.

Isn't there too many "end"?
grammar of racc file is changed in v0.10.

Racc does not use '%' mark, while yacc uses huge number of '%' marks..

== Racc reported "XXXX conflicts".

Try "racc -v xxxx.y".
It causes producing racc's internal log file, xxxx.output.

== Generated parsers does not work correctly

Try "racc -g xxxx.y".
This command let racc generate "debugging parser".
Then set @yydebug=true in your parser.
It produces a working log of your parser.
