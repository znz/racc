j
= 規則ファイル文法リファレンス

== 文法に関する前バージョンとの非互換

  * (1.2.5) ユーザーコードを連結する時、外部ファイルよりも
            埋めこんであるコードを先に連結します。
  * (1.1.6) 新しいディレクティブ options が追加されました。
  * (1.1.5) 予約語 token の意味が変更になりました。
  * (0.14) ルールの最後のセミコロンが省略可能になりました。
           また、token prechigh などが予約語でなくなりました。
  * (10.2) prepare が header に driver が footer になりました。
           今はそのままでも使えますが、2.0 からは対応しません。
  * (0.10) class に対応する end がなくなりました。
  * (0.9) ダサダサのピリオド方式をやめて { と } で囲むようにしました。

== 全体の構造

トップレベルは、規則部とユーザーコード部に分けられます。
ユーザーコード部はクラス定義の後に来なければいけません。

=== コメント

文法ファイルには、一部例外を除いて、ほとんどどこにでもコメントを
書くことができます。コメントは、Rubyの #.....(行末) スタイルと、
Cの /*......*/ スタイルを使うことができます。

=== 規則部

規則部は以下のような形をしています。
--
class クラス名 [< スーパークラス]
  [演算子順位]
  [トークン宣言]
  [オプション]
  [expect]
  [トークンシンボル値おきかえ]
  [スタート規則]
rule
  文法記述
--
"クラス名"はここで定義するパーサクラスの名前です。
これはそのままRubyのクラス名になります。

また M::C のように「::」を使った名前を使うと、クラス定義を
モジュール M の中にネストさせます。つまり class M::C ならば
--
module M
  class C < Racc::Parser
    いろいろ
  end
end
--
のように出力します。

さらに、Ruby と同じ構文でスーパークラスを指定できます。
ただしこの指定をするとパーサの動作に重大な影響を与えるので、
特に必要がない限り指定してはいけません。これは将来の拡張の
ために用意したもので、現在指定する必然性はあまりありません。

=== 文法の記述

racc で生成するパーサが理解できる文法を記述します。
文法は、予約語 rule と end の間に、以下のような書式で書きます。
--
トークン: トークンの並び アクション

トークン: トークンの並び アクション
        | トークンの並び アクション
        | トークンの並び アクション
             (必要なだけ同じようにつづける)
--
アクションは { } で囲みます。アクションでは Ruby の文はほとんど
使えますが、一部だけは非対応です。対応していないものは以下のとおり。

  * ヒアドキュメント
  * =begin ... =end 型コメント
  * スペースで始まる正規表現
  * ごくまれに % の演算。普通に演算子のまわりにスペースを入れていれば問題なし

このあたりに関しては完全な対応はまず無理です。あきらめてください。

左辺の値($$)は、オプションによって返し方がかわります。まずデフォルトでは
ローカル変数 result (そのデフォルト値は val[0])が 左辺値を表し、アクション
ブロックを抜けた時の result の値が左辺値になります。または明示的に return
で返した場合もこの値になります。一方、options で no_result_var を指定した
場合、左辺値はアクションブロックの最後の文の値になります (Ruby のメソッドと
同じ)。

どちらの場合でもアクションは省略でき、省略した場合の左辺値は常に val[0] です。

以下に文法記述の全体の例をしめします。
--
rule
  goal: def ruls source
        {
          result = val
        }

  def : /* none */
        {
          result = []
        }
      | def startdesig
        {
          result[0] = val[1]
        }
      | def
          precrule   # これは上の行の続き
        {
          result[1] = val[1]
        }
(略)
--
アクション内では特別な意味をもった変数がいくつか使えます。
そのような変数を以下に示します。括弧の中は yacc での表記です。

  * result ($$)

左辺の値。初期値は val[0] です。

  * val ($1,$2,$3…)

右辺の記号の値の配列。Ruby の配列なので当然インデックスはゼロから始まります。
この配列は毎回作られるので自由に変更したり捨てたりして構いません。

  * _values (...,$-2,$-1,$0)

値スタック。Racc コアが使っているオブジェクトがそのまま渡されます。
この変数の意味がわかる人以外は<em>絶対に</em>変更してはいけません。

またアクションの特別な形式に、埋めこみアクションというものがあります。
これはトークン列の途中の好きなところに記述することができます。
以下に埋めこみアクションの例を示します。
--
target: A B { puts 'test test' } C D { normal action }
--
このように記述すると A B を検出した時点で puts が実行されます。
また、埋めこみアクションはそれ自体が値を持ちます。つまり、以下の例において
--
target: A { result = 1 } B { p val[1] }
--
最後にある p val[1] は埋めこみアクションの値 1 を表示します。
B の値ではありません。

意味的には、埋めこみアクションは空の規則を持つ非終端記号を追加することと
全く同じ働きをします。つまり、上の例は次のコードと完全に同じ意味です。
--
target  : A nonterm B { p val[1] }
nonterm : /* 空の規則 */ { result = 1 }
--

=== 演算子優先順位

あるトークン上でシフト・還元衝突がおこったとき、そのトークンに
演算子優先順位が設定してあると衝突を解消できる場合があります。
そのようなものとして特に有名なのは数式の演算子と if...else 構文です。

優先順位で解決できる文法は、うまく文法をくみかえてやれば
優先順位なしでも同じ効果を得ることができます。しかしたいていの
場合は優先順位を設定して解決するほうが文法を簡単にできます。

シフト・還元衝突がおこったとき、Racc はまずその規則に順位が設定
されているか調べます。規則の順位は、その規則で一番うしろにある
終端トークンの優先順位です。たとえば
--
target: TERM_A nonterm_a TERM_B nonterm_b
--
のような規則の順位はTERM_Bの優先順位になります。もしTERM_Bに
優先順位が設定されていなかったら、優先順位で衝突を解決することは
できないと判断し、「Shift/Reduce conflict」を報告します。

演算子の優先順位はつぎのように書いて定義します。
--
prechigh
  nonassoc PLUSPLUS
  left     MULTI DEVIDE
  left     PLUS MINUS
  right    '='
preclow
--
prechigh に近い行にあるほど優先順位の高いトークンです。上下をまるごと
さかさまにして preclow...prechigh の順番に書くこともできます。left
などは必ず行の最初になければいけません。

left right nonassoc はそれぞれ「結合性」を表します。結合性によって、
同じ順位の演算子の規則が衝突した場合にシフト還元のどちらをとるかが
決まります。たとえば
--
a - b - c
--
が
--
(a - b) - c
--
になるのが左結合 (left) です。四則演算は普通これです。
一方
--
a - (b - c)
--
になるのが右結合 (right) です。代入のクオートは普通 right です。
またこのように演算子が重なるのはエラーである場合、非結合 (nonassoc) です。
C 言語の ++ や単項のマイナスなどがこれにあたります。

ところで、説明したとおり通常は還元する規則の最後のトークンが順位を
決めるのですが、ある規則に限ってそのトークンとは違う順位にしたいことも
あります。例えば符号反転のマイナスは引き算のマイナスより順位を高く
しないといけません。このような場合 yacc では %prec を使います。
racc ではイコール記号を使って同じことをできます。
--
prechigh
  nonassoc UMINUS
  left '*' '/'
  left '+' '-'
preclow
(略)
exp: exp '*' exp
   | exp '-' exp
   | '-' exp     = UMINUS    # ここだけ順位を上げる
--
このように記述すると、'-' exp の規則の順位が UMINUS の順位になります。
こうすることで符号反転の '-' は '*' よりも順位が高くなるので、
意図どおりになります。

=== トークン宣言

トークン(終端記号)のつづりを間違えるというのはよくあることですが、
発見するのはなかなか難しいものです。1.1.5 からはトークンを明示的に
宣言することで、宣言にないトークン / 宣言にだけあるトークンに対して
警告が出るようになりました。yacc の %token と似ていますが最大の違いは
racc では必須ではなく、しかもエラーにならず警告だけ、という点です。

トークン宣言は以下のように書きます。
--
token A B C D
        E F G H
--
トークンのリストを複数行にわたって書けることに注目してください。
racc では一般に「予約語」は行の先頭に来た時だけ予約語とみなされるので
prechigh などもシンボルとして使えます。ただし深淵な理由から end だけは
どうやっても予約語になってしまいます。

=== オプション

racc のコマンドラインオプションの一部をファイル中にデフォルト値
として記述することができます。
--
options オプション オプション …
--
現在ここで使えるのは

  * omit_action_call

空のアクション呼び出しを省略する

  * result_var

変数 result を使う

です。
それぞれ no_ を頭につけることで意味を反転できます。

=== expect

実用になるパーサはたいてい無害な shift/reduce conflict を含みます。
しかし文法ファイルを書いた本人はそれを知っているからいいですが、
ユーザが文法ファイルを処理した時に「conflict」と表示されたら
不安に思うでしょう。そのような場合、以下のように書いておくと
shift/reduce conflict のメッセージを抑制できます。
--
expect 3
--
この場合 shift/reduce conflict はぴったり三つでなければいけません。
三つでない場合はやはり表示が出ます (ゼロでも出ます)。
また reduce/reduce conflict の表示は抑制できません。

=== トークンシンボル値の変更

トークンシンボルを表す値は、デフォルトでは

  * 文法中、引用符でかこまれていないもの (RULEとかXENDとか)
    →その名前の文字列を intern して得られるシンボル (1.4 では Fixnum)
  * 引用符でかこまれているもの(':'とか'.'とか)
    →その文字列そのまま

となっていますが、たとえば他の形式のスキャナがすでに存在する場合などは、
これにあわせなければならず、このままでは不便です。このような場合には、
convert 節を加えることで、トークンシンボルを表す値を変えることができます。
以下がその例です。
--
convert
  PLUS 'PlusClass'      #→ PlusClass
  MIN  'MinusClass'     #→ MinusClass
end
--
デフォルトではトークンシンボル PLUS に対してはトークンシンボル値は
:PLUS ですが、上のような記述がある場合は PlusClass になります。
変換後の値は false・nil 以外ならなんでも使えます。

変換後の値として文字列を使うときは、次のように引用符を重ねる必要があります。
--
convert
  PLUS '"plus"'       #→ "plus"
end
--
また、「'」を使っても生成された Ruby のコード上では「"」になるので
注意してください。バックスラッシュによるクオートは有効ですが、バック
スラッシュは消えずにそのまま残ります。
--
PLUS '"plus\n"'          #→ "plus\n"
MIN  "\"minus#{val}\""   #→ \"minus#{val}\"
--

=== スタート規則

パーサをつくるためには、どの規則が「最初の」規則か、ということを Racc におしえて
やらなければいけません。それを明示的に書くのがスタート規則です。スタート規則は
次のように書きます。
--
start real_target
--
start は行の最初にこなければいけません。このように書くと、ファイルで
一番最初に出てくる real_target の規則をスタート規則として使います。
省略した場合は、ファイルの最初の規則がスタート規則になります。普通は
最初の規則を一番上にかくほうが書きやすく、わかりやすくなりますから、
この記法はあまりつかう必要はないでしょう。

=== ユーザーコード部

ユーザーコードは、パーサクラスが書きこまれるファイルに、
アクションの他にもコードを含めたい時に使います。このようなものは
書きこまれる場所に応じて三つ存在し、パーサクラスの定義の前が
header、クラスの定義中(の冒頭)が inner、定義の後が footer です。
ユーザコードとして書いたものは全く手を加えずにそのまま連結されます。

ユーザーコード部の書式は以下の通りです。
--
---- 識別子
  ruby の文
  ruby の文
  ruby の文

---- 識別子
  ruby の文
     :
--
行の先頭から四つ以上連続した「-」(マイナス)があるとユーザーコードと
みなされます。識別子は一つの単語で、そのあとには「=」以外なら何を
書いてもかまいません。
e
= Racc Grammar File Reference

== Global Structure

== Class Block and User Code Block

There's two block on toplevel.
one is 'class' block, another is 'user code' block. 'user code' block MUST
places after 'class' block.

== Comment

You can insert comment about all places. Two style comment can be used,
Ruby style (#.....) and C style (/*......*/) .

== Class Block

The class block is formed like this:
--
class CLASS_NAME
  [precedance table]
  [token declearations]
  [expected number of S/R conflict]
  [options]
  [semantic value convertion]
  [start rule]
rule
  GRAMMARS
--
CLASS_NAME is a name of parser class.
This is the name of generating parser class.

If CLASS_NAME includes '::', Racc outputs module clause.
For example, writing "class M::C" causes creating the code bellow:
--
module M
  class C
    :
    :
  end
end
--

== Grammar Block

The grammar block discripts grammar which is able
to be understood by parser.  Syntax is:
--
(token): (token) (token) (token).... (action)

(token): (token) (token) (token).... (action)
       | (token) (token) (token).... (action)
       | (token) (token) (token).... (action)
--
(action) is an action which is executed when its (token)s are found.
(action) is a ruby code block, which is surrounded by braces:
--
{ print val[0]
  puts val[1] }
--
Note that you cannot use '%' string, here document, '%r' regexp in action.

Actions can be omitted.
When it is omitted, '' (empty string) is used.

A return value of action is a value of left side value ($$).
It is value of result, or returned value by "return" statement.

Here is an example of whole grammar block.
--
rule
  goal: definition ruls source { result = val }

  definition: /* none */   { result = [] }
    | definition startdesig  { result[0] = val[1] }
    | definition
             precrule   # this line continue from upper line
      {
        result[1] = val[1]
      }

  startdesig: START TOKEN
--
You can use following special local variables in action.

  * result ($$)

The value of left-hand side (lhs). A default value is val[0].

  * val ($1,$2,$3...)

An array of value of right-hand side (rhs).

  * _values (...$-2,$-1,$0)

A stack of values.
DO NOT MODIFY this stack unless you know what you are doing.

== Operator Precedance

This function is equal to '%prec' in yacc.
To designate this block:
--
prechigh
  nonassoc '++'
  left     '*' '/'
  left     '+' '-'
  right    '='
preclow
--
`right' is yacc's %right, `left' is yacc's %left.

`=' + (symbol) means yacc's %prec:
--
prechigh
  nonassoc UMINUS
  left '*' '/'
  left '+' '-'
preclow

rule
  exp: exp '*' exp
     | exp '-' exp
     | '-' exp       =UMINUS   # equals to "%prec UMINUS"
         :
         :
--

== expect

Racc has bison's "expect" directive.
--
# Example

class MyParser
rule
  expect 3
    :
    :
--
This directive declears "expected" number of shift/reduce conflict.
If "expected" number is equal to real number of conflicts,
racc does not print confliction warning message.

== Declaring Tokens

By declaring tokens, you can avoid many meanless bugs.
If decleared token does not exist/existing token does not decleared,
Racc output warnings.  Declearation syntax is:
--
token TOKEN_NAME AND_IS_THIS
      ALSO_THIS_IS AGAIN_AND_AGAIN THIS_IS_LAST
--

== Options

You can write options for racc command in your racc file.
--
options OPTION OPTION ...
--
Options are:

  * omit_action_call

omit empty action call or not.

  * result_var

use/does not use local variable "result"

You can use 'no_' prefix to invert its meanings.

== Converting Token Symbol

Token symbols are, as default,

  * naked token string in racc file (TOK, XFILE, this_is_token, ...)
    --&gt; symbol (:TOK, :XFILE, :this_is_token, ...)
  * quoted string (':', '.', '(', ...)
    --&gt; same string (':', '.', '(', ...)

You can change this default by "convert" block.
Here is an example:
--
convert
  PLUS 'PlusClass'      # We use PlusClass for symbol of `PLUS'
  MIN  'MinusClass'     # We use MinusClass for symbol of `MIN'
end
--
We can use almost all ruby value can be used by token symbol,
except 'false' and 'nil'.  These are causes unexpected parse error.

If you want to use String as token symbol, special care is required.
For example:
--
convert
  class '"cls"'            # in code, "cls"
  PLUS '"plus\n"'          # in code, "plus\n"
  MIN  "\"minus#{val}\""   # in code, \"minus#{val}\"
end
--

== Start Rule

'%start' in yacc. This changes start rule.
--
start real_target
--
This statement will not be used forever, I think.

== User Code Block

"User Code Block" is a Ruby source code which is copied to output.
There are three user code block, "header" "inner" and "footer".

Format of user code is like this:
--
---- header
  ruby statement
  ruby statement
  ruby statement

---- inner
  ruby statement
     :
     :
--
If four '-' exist on line head,
racc treat it as beginning of user code block.
A name of user code must be one word.
.
