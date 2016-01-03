;;;我也是写完parse后才发现从"(+ n 1)"变成(+ n 1)，第一不能处理字符串里面的字符串，
;;;第二不能处理处理数字字符串，因为不知道当时数字字符串是做符号symbol还是在做数字number
;;;然后发现这些缺点在norvig.com的lispy里都早写了，可惜我没仔细看白忙了一场
;;;本来还想用call-cc重新写parse-a的，想想还是算了，反正怎么写还是个半成品

;;;http://norvig.com/lispy.html   http://blog.jobbole.com/47659/
;;;*完备：相比起Scheme标准来说，Lispy不是非常完备。主要的缺陷有：
;;;(1) 语法：缺少注释、引用 (quote) / 反引用 (quasiquote) 标记 (即'和`——译者注)、#字面值 (例如#\a——译者注)、衍生表达式类型 (例如从if衍生而来的cond，或者从lambda衍生而来的let)，以及点列表 (dotted list)。
;;;(2) 语义：缺少call/cc以及尾递归。
;;;(3) 数据类型：缺少字符串、字符、布尔值、端口 (ports)、向量、精确/非精确数字。事实上，相比起Scheme的pairs和列表，Python的列表更加类似于Scheme的向量。
;;;(4) 过程：缺少100多个基本过程：与缺失数据类型相关的所有过程，以及一些其它的过程 (如set-car!和set-cdr!，因为使用Python的列表，我们无法完整实现set-cdr!)。
;;;(5) 错误恢复：Lispy没有尝试检测错误、合理地报告错误以及从错误中恢复。Lispy希望程序员是完美的。



;;; 遇到( 就生成一个空列表， 把( 后面的元素一次投入到空列表，直至遇到)结束
;;; (+ (+ 1 3) 3) 如何把+投入到一个列表的列表里? car出来投入进去在

;;;遇到(就投个'()，一直遇到第一个) 才停止操作最里面的那个()
;;; 弹出最后一个元素和追加元素到末尾
(define append-element-into-list
  (lambda (element list-a)
    (reverse (cons element (reverse list-a)))))

(define remove-last-element
  (lambda (list-a)
    (reverse (cdr (reverse list-a)))))

(if (eq? var '#\(')
    (set! f '())
    (if (eq? var '#\)')
	(set! f1 '())
	(append-element-into-list var f2))))

;;; (+ 3 (+ 1 3) 3 (+ 2 3))
;;; "(+ 1 1)" => "( + 1 1 )"

;;;遇见( 创建一个空列表， 把当前列表赋值给上级列表,再设置当前列表为空列表，
;;;遇见)就把当前这个列表cons进上个列表里做当前列表,并把上个列表设为空列表
;;;非( )字符塞进当前列表
;;;字串递归完了，返回当前列表
;;; (eval (list '+ '1 '1)) => 2
;;; ('+ '1 '1) -> '(+ 1 1)
;;;(cons '1 (cons '1 (cons '+ '()))) => '(1 1 +)

;;; "(+ 1 1)" 先变成 ("(" "+" "1" "1" ")") 接着变成('( '+ '1 '1 '))
;;;(eval (list '+ '1 '1)) => 2
;;;racket@> (car (cons (string->symbol "(") '())) => '(|(|)
;;;racket@> (car (cons (string->symbol "(") '())) => '|(|
;;;racket@> (eq? '|(| (car (cons (string->symbol "(") '()))) => #t
;;;racket@> (parse-eval '('|(| '+ '1 '1 '|)|) '() '()) => '('|(| '+ '1 '1 '|)|)
;;;(list? (car '('|(| '+ '1 '1 '|)|))) => #t
;;;(eqv? (car '(|(| + 1 1 |)|)) '|(|)
;;;(string->symbol "(") => '|(| 这是个symbol,但是我错把它以为成了list, 它应该返回|(|, 但racket返回'|(|，guile会返回|(|
;;;racket@> (parse-eval '(|(| + |(| + 1 1 |)| 2 |)|) '() '()) => '(+ (+ 1 1) 2)
;;;racket@> (eval (parse-eval '(|(| + |(| + 1 1 |)| 2 |)|) '() '())) => 4
;;;(symbol? (car '(define a 10))) => #t
;;;(define parse-eval
;;;      (lambda (list-a up-level-list current-list)
;;;	(if (eq? list-a '())
;;;	    (reverse current-list)
;;;	    (if (eq? (car list-a) '|(|)
;;;		(parse-eval (cdr list-a)
;;;			    current-list
;;;			    '())
;;;		(if (eq? (car list-a) '|)|)
;;;		    (parse-eval (cdr list-a)
;;;				'()
;;;				(cons (reverse current-list) up-level-list))
;;;		    (parse-eval (cdr list-a)
;;;				up-level-list
;;;				(cons (car list-a) current-list)))))))
;;;
;;;
;;;
;;;(define string-parse-eval
;;;  (lambda (string-a)
;;;    (define list-a (string->list string-a))
;;;    (parse-eval list-a '() '())))
;;;

;;; ( + 2 ( + ( + 1 3) 3))
;;;因为要保存上下文信息，不能用尾递归
;;;parse-I遇到( 传递调用parse-II parse-II遇到( 调用parse-I 谁先遇到)谁先返回 遇到list-a为空也返回, 2个参数 list-a和current-list传递， 返回list-a 和 current-list
;;;1个参数把list-a传进去返回一个list-a和一个列表 把返回的列表cons进当前的列表
;;;  (
;;;    (
;;;      (
;;;        ....)
;;;              )
;;; 一开始最外面的()为current-list,每遇到一个( 就调用(parse-a '())去生成那个()并返回那个()，并且把返回的() cons进current-list
;;; 当遇到(调用(parse-a '())时， 一进递归里,current-list为'() 生成()后返回current-list
;;;每个递归里都有一个current-list, 外面永远等着把里面返回的current-list cons进外面这个current-list里, 当最终list-a为空列表时，返回最外面的current-list
;;;list-a就没啥好说的，就是一个依次car cdr不断减少的列表，最终减少为空列表

;;;racket@> (define list-a '(|(| + |(| + 1 1 |)| 2 |)| |(| + |(| + 1 1 |)| 2 |)|))
;;;racket@> (parse-a '()) => '((+ (+ 1 1) 2))
;;;racket@> (define list-a '(( + 1 1 ( - 3 2) ) ( + ( + 1 1 ) 9 )))
;;;racket@> (parse-a '()) => '((+ 1 1 (- 3 2)) (+ (+ 1 1) 9))

;;;"(+ 1 1)" 用string-replace变成" ( + 1 1 ) "再用string-split变成("(" "+" "1" "1" ")") 再用string-list->symbol-list变成(( + 1 1 )) 再用parse-a变成 ((+ 1 1)) 再用eval求值

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
(define list-a '(( + 1 1 )))

(define parse-a
  (lambda (current-list)
    (define store-car 0)
    (if (eq? list-a '())
	(reverse current-list)
	(if (eq? (car list-a) '|)|)
	    (begin
	      (set! list-a (cdr list-a))
	      (reverse current-list))
	    (if (eq? (car list-a) '|(|)
		(begin
		  (set! list-a (cdr list-a))
		  (parse-a (cons (parse-a '()) current-list)))
		(begin
		  (set! store-car (car list-a))
		  (set! list-a (cdr list-a))
		  (parse-a (cons store-car current-list))))))))



(define list-a
  (string-list->symbol-list
   (split-string 
    (replace-string ")" 
		    " )" 
		    (replace-string "(" 
				    "( " 
				    "(+ 1 1)"))
    " ")))
(eval (car (parse-a '())))



;;;(define parse-I
;;;  (let ((current-list '()))
;;;    (lambda (list-a-and-current)
;;;      (define list-a (car list-a-and-current))
;;;      (define upper-list (car (cdr list-a-and-current)))
;;;      (if (eq? list-a '())
;;;	  upper-list
;;;	  (if (eq? (car list-a) '|)|)
;;;		(list (cdr list-a) (cons (reverse current-list) upper-list))
;;;		(if (eq? (car list-a) '|(|)
;;;		    (parse-I (parse-II (list (cdr list-a) current-list)))
;;;		    (parse-I (list (cdr list-a) (cons (car list-a) current-list)))))))))
;;;
;;;(define parse-II
;;;  (let ((current-list '()))
;;;    (lambda (list-a-and-current)
;;;      (define list-a (car list-a-and-current))
;;;      (define upper-list (car (cdr list-a-and-current)))
;;;      (if (eq? list-a '())
;;;	  upper-list
;;;	  (if (eq? (car list-a) '|)|)
;;;		(list (cdr list-a) (cons (reverse current-list) upper-list))
;;;		(if (eq? (car list-a) '|(|)
;;;		    (parse-II (parse-I (list (cdr list-a) current-list)))
;;;		    (parse-II (list (cdr list-a) (cons (car list-a) current-list)))))))))
;;;
;;;(define parse-II
;;;  (lambda (list-a-and-current)
;;;    (define list-a (car list-a-and-current))
;;;    (define upper-list (car (cdr list-a-and-current)))
;;;    (define current-list '())
;;;    (if (eq? list-a '())
;;;	upper-list
;;;	(if (eq? (car list-a) '|)|)
;;;	    (list (cdr list-a) (reverse (cons (reverse current-list) upper-list)))
;;;	    (if (eq? (car list-a) '|(|)
;;;		(parse-II (parse-I (list (cdr list-a) current-list)))
;;;		(parse-II (list (cdr list-a) (cons (car list-a) current-list))))))))
;;;


;;;parse FAIL string->symbol时如果是16进制字符串，怎么判断是它是字符串还是16进制数
;;;如果是16进制数需要把它转换成数字，如果是字符串需要把它转成symbol，所以无法判断
;;;把"(+ n 1)"变成(+ n 1)还有个的问题，如果字符串中出现了字符串怎么办?
;;; "(display "hello world")" 这怎么解析 string->symbol是解析不了这种的 split-string和merge-string对于这种字符串中的字符串貌似也不行
;;;如果真的是个字符串"12"，""12""就是错的，更别提解析了
;;;把字符串变成symbol去求值貌似是不行的
;;;把字符串变成在字符去求值 ???
;;;(eval (read-from-string "(+ 1 1)")) 这种是怎么实现的 ???
;;; "12" 是个字符串，但对人来说也是个数字，但机器识别不了它是数字，怎么让机器去知道它是个数字 ???

<jusss> hi there, (string->symbol "12") => a symbol 12, and how I can get a
	integer 12?  [22:54]
<jusss> I mean how to know a string is a integer or not 
<jusss> is there a procedure can decide a string is integer or not ?  [23:06]
<jusss> like "12"
<pierpa> (integer? (string->number  [23:09]
<jusss> pierpa: what if to decide a string is number or not ?  [23:13]
<wasamasa> jusss: you'd ideally not get into that situation in the first place
<wasamasa> jusss: string->integer returns #f in case it cannot decode a number
	   though
<pierpa> string->number  [23:16]
<wasamasa> jusss: also, a string is not a number, otherwise it wouldn't be a
	   string
<wasamasa> jusss: a string can contain a sequence of characters that can be
	   interpreted as a number though
<wasamasa> jusss: the #f string->number returns informs you that this is not
	   the case
<jusss> wasamasa: I know what string is, like this "12" it's a string, ok, but
	human can know it's integer 12, but machine can't, I'd like to make
	machine know it's a number  [23:19]
<jusss> like "abc" it's a string, and it's not a number
<jusss> "12.13" is a string, but it also means a number to human  [23:20]
<pierpa> these are called "numerals"
<jusss> how to decide a string it means number to human ?
<pierpa> you check it against a grammar for numerals
* wasamasa waits for jusss to realize the answer has already been given
<pjb> jusss: \12 (or |12|) and 12 are two different things ;-)
<pjb> jusss: is "twelve" an integer? How can a _string_ "be" an integer???
<pjb> jusss: what about "deadbeef"? Is it an integer?  [23:28]
<pjb> jusss: what about "\"12\""?
<pjb> jusss: what about "(+ 2 3)"? Why or why not?  [23:29]
<pjb> jusss: what about "π"?
<jusss> pjb: I'm doing this "(+ 2 3)" right now ...
<pjb> jusss: Seriously, try to answer those questions.
<jusss> pjb: turn "(+ 2 3)" to (+ 2 3)
<jusss> it sounds I'm on a wrong way
<pjb> Yep.  [23:30]
<pjb> You are confusing objects, such as an integer, with a representation of
      those objects.
<pjb> What integer does "12" represent?  It could be 42; it could be 3.
<pjb> The question is what representation system it is?
<jusss> pjb: I think I find a way to do that, like numbers in lisp are like
	0-9 1.2 3/4 , I can turn a string to characters, and compare them with
	0 1 - . / this characters, if there's one not match, I can know it
	can't mean number to me   [23:47]
<jusss> all the symbols of numbers , compare them with characters of strings
<wasamasa> you should learn to read the backlog, the solution was mentioned
	   four times  [23:49]
<pjb> jusss: what about "#xdeadbeef" or "#b010101101110" ?  [23:50]
<jusss> pjb: the first parameter of define, how define to detective it's
	number or not ?  [23:54]

;;;AST 构造一门语言出来 
		
;;;以空格分离字串，返回一个包含字串的列表,然后把列表里的字串转成symbol
;;;不要用string->list, 先空格分离string,把分离的string 转化成symbol cons进列表
;;;(string->symbol "(")

;;;(symbol-function 'car) =>  #<FUNCTION CAR>  cl有这种函数 scheme ?  一
;;;<oGMo> jusss: (eval (read-from-string "(+ 1 1)"))                二
;;;racket@> (car ''1)                                            三
'quote
racket@> '1
1
racket@> (car (cdr ''1))
1
<ggole> '1 is (quote 1), which you can get the second element of easily enough
<ggole> I don't think there's a standard facility to read a sexp from a string
	though


<pjb> jusss: you need to use mapcar to remove the quotes:
(mapcar (lambda
	    (quoted-form) (second quoted-form)) '('+ '1 '1)) #| --> (+ 1 1) |#

<jusss> ggole: do repl work like this ? read a string and eval  [00:10]
<profan_> ggole: read from string port?  [00:14]
<pjb> jusss: you need to use map to remove the quoted form: (map (lambda
      (quoted-form) (cadr quoted-form)) '('+ '1 '2)) #| --> (+ 1 2) |#  [00:22]
<pjb> jusss: but it's idiotic to turn a string like "(+ 1 2)" into a list ('+
      '1 '2). It would be saner to turn it into a list (+ 1 2) directly.
								        [00:24]
<jusss> pjb: how ?
<pjb> read from string port.
<pjb> in CL, just use read-from-string.  [00:25]
<jusss> pjb: and scheme ?
<pjb> in scheme read from string port.
<pjb> jusss: now, of course, string ports are not standard r5rs, so you would
      first save the string to a file then reopen the file and read from it.
								        [00:26]
<jusss> pjb: how repl works ?  [00:27]
<pjb> you launch a scheme implementation and type stuff

scheme@(guile-user)> (string->symbol "a")
$2 = a
scheme@(guile-user)> (car (cdr ''a))
$3 = a
scheme@(guile-user)> ;a
scheme@(guile-user)> 'a
$4 = a
scheme@(guile-user)> (symbol? 'a)
$5 = #t
scheme@(guile-user)> (symbol? a)
;;; <stdin>:36:0: warning: possibly unbound variable `a'
<unnamed port>:36:0: In procedure #<procedure 2c66be0 at <current input>:36:0 ()>:
<unnamed port>:36:0: In procedure module-lookup: Unbound variable: a

Entering a new prompt.  Type `,bt' for a backtrace or `,q' to continue.
scheme@(guile-user) [1]> ,q
scheme@(guile-user)> (define a 10)
scheme@(guile-user)> (symbol? a)
$6 = #f
scheme@(guile-user)>

user1> (inspect (read))
'a
[0]     'a
[1]     Type: cons
[2]     Class: #<built-in-class cons>
        Normal List
[3]     Length: 2
[4]     0: quote
[5]     1: a
Inspect> :q

'a
user1>

<jusss> hi there, if there's a list like ('+ 1 2) and how I can eval it like
	(+ 1 2) ?
<ggole> (apply (car list) (cdr list))  [23:39]
<ggole> Or possibly eval, depending on what this form might look like  [23:40]
<jusss> ggole: get error mesg, '+ is not a procedure  [23:56]
<jusss> ggole: I turn a string like "(+ 1 1)" to a list ('+ '1 '1), now I'd
	like to eval it like eval (+ 1 1)  [23:57]
<ggole> O_o  [23:58]
<ggole> Well, remove the quotes first
<jusss> but I don't know how to transform
<jusss> ggole: how  [23:59]

[Thu Dec 31 2015]
<ggole> jusss: figure out how to turn '1 into 1. Then, figure out how to do
	that for each element of the list.  [00:01]
<jusss> ggole: "(+ 1 1)", I can split it turn to ("+" "1" "1") then
	string->symbol can turn to ('+ '1 '1)  [00:03]
<jusss> turn '1 into 1, is there symbol->number or what ? and it sounds not
	good  [00:04]
<jusss> my thought is really bad  [00:05]
<jusss> so how to turn "(+ 1 1)" to '(+ 1 1) ?
<ggole> '1 is (quote 1), which you can get the second element of easily enough
								        [00:06]
<ggole> I don't think there's a standard facility to read a sexp from a string
	though
<jusss> ggole: do repl work like this ? read a string and eval  [00:10]
<profan_> ggole: read from string port?  [00:14]
<pjb> jusss: you need to use map to remove the quoted form: (map (lambda
      (quoted-form) (cadr quoted-form)) '('+ '1 '2)) #| --> (+ 1 2) |#  [00:22]
<pjb> jusss: but it's idiotic to turn a string like "(+ 1 2)" into a list ('+
      '1 '2). It would be saner to turn it into a list (+ 1 2) directly.
<jusss> pjb: how ?
<pjb> read from string port.
<pjb> in CL, just use read-from-string.  [00:25]
<jusss> pjb: and scheme ?
<pjb> in scheme read from string port.
<pjb> jusss: now, of course, string ports are not standard r5rs, so you would
      first save the string to a file then reopen the file and read from it.
								        [00:26]
<jusss> pjb: how repl works ?  [00:27]
<pjb> you launch a scheme implementation and type stuff
<jusss> pjb: so repl don't receive your input stuff as strings ?  [00:28]
<pjb> No, it uses read directly. REPL = (loop (print (eval (read)))).  [00:29]
<pjb> jusss: you may find string ports in your implementation extensions.
<jusss> pjb: now I'm using racket
<pjb> jusss: but it would be an impair to read lines as strings, to read them
      again with a string port, because this would prevent to write sexps over
      multiple lines (or make it exponentially more difficult for you to deal
      with).  [00:31]
<pjb> Then read racket doc.
<jusss> pjb: I have a little confused about symbol type, like (define a 10) so
	a is symbol type ?
<pjb> a is a symbol, naming a variable, bound to a lisp object. That lisp
      object is of type integer, and of value 10.  [00:32]
<jusss> I don't remember there's symbol type in other languages like c or
	python
<wasamasa> it is there in ruby though  [00:33]
<pjb> in MIT scheme, you can write a REPL as: (let ((env
      (make-top-level-environment))) (let loop () (display (eval (read) env))
      (newline) (loop)))  [00:37]
<jusss> pjb: can I turn 'a to a ?
<pjb> (cadr ''a) #| --> a |#  [00:38]
<pjb> (list 'quote 'a) #| --> 'a |#
<pjb> (cadr (list 'quote 'a)) #| --> a |#
<jusss> pjb: no, it's still 'a  [00:39]
<pjb> Again, you should not have 'a. You should have a.
<pjb> It is much more complex to have 'a.
<pjb> 'a is a form: it's a data list representing some code.  To obtain it,
      you have to write a program to build this data representing code. Such
      as (list 'quote 'a).
<pjb> Instead just use a.  [00:40]
<jusss> pjb: so where string->symbol is expected to use ?
<pjb> (string->symbol "a") #| --> a |#
<pjb> (list 'quote (string->symbol "a")) #| --> 'a |# ;see, much more complex.
								        [00:41]
<jusss> pjb: if a don't exist, so what's the meaning of (string->symbol "a")
<pjb> (string->symbol "a") returns a symbol named "a".
<pjb> (string->symbol "a") #| --> a |#
<pjb> scheme is really too limited.  in CL: (type-of (intern "A")) #| -->
      symbol |#  [00:42]
<jusss> so here's the stuff to make me confused, 'a is a symbol, also it's a
	variable name 
<pjb> No. 'a is a list: (list? ''a) #| --> #t |#  [00:43]
<pjb> a is a symbol: (symbol? 'a) #| --> #t |#
<jusss> pjb: and 'a is a procedure ?
<pjb> No, 'a is a list: (list? ''a) #| --> #t |#
<pjb> (car ''a) #| --> quote |#  (cadr ''a) #| --> a |#  (length ''a) #| --> 2
      |#  [00:44]
<pjb> (cdr ''a) #| --> (a) |#
<jusss> ok then, now 'a is a symbol, a variable name, (quote a), and list you
	said
<ggole> 'a is not a symbol
<pjb> (list 'quotex 'a) #| --> (quotex a) |#  (list 'quote 'a) #| --> 'a |#
<pjb> don't let the lisp printer confuse you. It prints lists such as (quote
      a) as 'a:  '(quote a) #| --> a |# But it's still a list containing the
      two symbols quote and a.  [00:45]
<jusss> ggole: if it's not a symbol, so what's it ?
<pjb> a list
<pjb> Type: (list? (read)) RET 'a RET  [00:46]
<pjb> Type: (symbol? (read)) RET 'a RET
<pjb> what do you get for each?
<ggole> Yep, it's shorthand for the form (quote a)
<jusss> now what's symbol really
<pjb> a is a symbol.  quote is a symbol.  foo is a symbol.
<jusss> that's why lisp called symbol-expression ?  [00:47]
<pjb> + is a symbol. * is a symbol.  --*-- is a symbol.
<jusss> because everything is symbol in lisp ?
<pjb> 42<35 is a symbol.
<pjb> jusss: nope.
<jusss> and I found the concept is not easy to understand   [00:48]
<pjb> #t is not a symbol. 42 is not a symbol. #(1 2 3) is not a symbol.  (a b
      c) is not a symbol. 'a is not a symbol.
<jusss> pjb: and symbol is easy to understand in cl ?  [00:50]
<jusss> it's not between scheme and cl ?
<pjb> jusss:
      http://www.schemers.org/Documents/Standards/R5RS/HTML/r5rs-Z-H-9.html#%_sec_6.3.3
      says that: "The rules for writing a symbol are exactly the same as the
      rules for writing an identifier; see sections 2.1 and 7.1.1." and
      http://www.schemers.org/Documents/Standards/R5RS/HTML/r5rs-Z-H-5.html#%_sec_2.1
      gives the rules.
<rudybot> http://teensy.info/0MwuZhjr2C
<rudybot> http://teensy.info/d7ZYtcV4AF
<pjb> jusss: r5rs is fucking 50 pages only.  You can read 50 pages can't you?
<jusss> pjb: ok then, so 'a is not a symbol, and why (string->symbol "a")
	return 'a ?  [00:52]
<pjb> CL is easier because you have more standardized tools, including
      introspection tools such as inspect, type-of, etc.  REPL can be written
      conformingly as (loop (print (eval (read)))) instead of (let ((env
      (make-top-level-environment))) (let loop () (display (eval (read) env))
      (newline) (loop)))  which is not standard because
      interaction-environment is not mandatory by r5rs.
<pjb> jusss: it does not.
<pjb> (string->symbol "a")  returns a.
<pjb> You may be using a deficient implementation that prints 'a instead of a,
      but it's a.
<pierpa> he uses an implementation whose output format can be taylored in
	 several ways
<pjb> racket contains a lot of deficient languages, supposedly pedagogical,
      but they confuse things more than anything.
<ggole> There are several implementations which do that.  [00:54]
<pierpa> some of which looks really obnoxious :)
<pjb> and dumb.
<jusss> pjb: (symbol? 'foo)                  ===>  #t
<ggole> I don't think the decision was made without thought, but I really
	don't care for it myself.
<pjb> jusss: here, the object tested is foo.
<pjb> ggole: deficient thought.  [00:55]
<pjb> It ignores the modularity of the lisp reader.
<jusss> pjb: I will try this (string->symbol "a") in guile  [00:56]
<pjb> What did you get for  [00:58]
<pjb> Type: (list? (read)) RET 'a RET
<pjb> Type: (symbol? (read)) RET 'a RET
<pjb>  
<pjb> >
<jusss> pjb: in guile, (define a 10) (symbol? a) => #f
<jusss> pjb: in guile, 'a => a, (string->symbol "a") => a, (car (cdr ''a)) =>
	a  [01:00]
<pjb> yes, 10 is not a symbol
<pjb> (define sym 'a) (symbol? sym) -> #f
<pjb> 10 is an integer.
<pjb> have you read 2.1?  [01:01]
<pjb> Notice that by 2.1 42<35 is not a standard identifier, but
      implementation dependant. It could be something else than a symbol in a
      different implementation. DUH.  In CL it's a symbol by standard.  [01:02]
<jusss> now I'm totally confused about identifer and symbol  [01:07]
<pjb> Yes, scheme is confusing.  Assume they're the same.
<ggole> Most of the difference is that you can create symbols from arbitrary
	strings with string->symbol: identifiers are the subset that read will
	create for you from scheme source.  [01:08]
<ggole> (That's probably a bit of a simplification.)
<jusss> (define a 10) (+ 1 (car (cdr ''a)))  [01:10]
<jusss> get error
<pjb> Yes, you cannot add symbols to numbers.  [01:11]
<pjb> or numbers to symbols.
<pjb> Also, (define a 10) defines the variable named a in an environment. To
      get access to its value from the symbol a, you would have to use eval
      (there's no symbol-value in scheme), and therefore you would have to
      find a way to obtain the environment where (define a 10) has defined the
      variable.  Most of the time it will be an implementation dependant way
      to find this environment.
<jusss> completely confused now :-(  [01:14]
<jusss> pjb: (define a 10) a is not a symbol  [01:15]
<jusss> and now you say it's
<pjb> jusss: but instead, you can define your own way to map symbols to
      values. For example, you could use an a-list.  (let ((vars '((a . 10) (b
      . 20))))  (+ (cdr (assoc 'a vars)) (cdr (assoc 'b vars)))) #| --> 30 |#
<pjb> jusss: in (define a 10), define is a symbol. a is a symbol, 10 is an
      integer. (define a 10) is a form, which when evaluated in an
      environment, will define a variable, named by the symbol a, bound to the
      integer 10.  [01:16]
<pjb> Now, if you do that at the REPL, and if your implementation provide the
      semi-standard interaction-environment procedure, then you could use
      (eval 'a (interaction-environment)) to get the value bound to the
      variable named a.  But it's only semi-standard, and not all
      implementations provide it.  [01:17]
<pjb> And then, if you use this define in other environments, such as in a
      procedure: (lambda () (define a 10) …) then there are no standard way
      to get the environment allowing you to retrieve the variable named a in
      that procedure.  [01:18]
<pjb> So instead, you can program your own kind of environment, for example,
      an a-list, where you map symbols to values and can do whatever you
      want. Of course, then you don't use define to put associations in your
      a-list, you would define your own procedures or macros.  [01:19]
<jusss> pjb: so a is a symbol before (define a 10) and after that a is not a
	symbol ?  [01:20]
<pjb> a is always a symbol.
<pjb> The question is whether there is a way to find the variable named by
      this symbol or not.  [01:21]
<pjb> Notice that when you compile a program, the variable names (the symbol
      identifying those variables, aka the identifiers) are usually throw
      out. They're forgotten. Only remains native code.
<jusss> pjb: 'a is (quote a) or a symbol ?  [01:22]
<pjb> In such an environment (a compiled program), there's no way to go from a
      symbol to a variable, because the compiler may have even optimize out
      the variable, or duplicated it; in any case, it has forgotten the naming
      of the bytes in memory.
<pjb> 'a is (quote a)
<pjb> Try: (read) RET 'a RET
<pjb> Try: (read) RET (quote a) RET
<pjb> Try: (let ((x (read)) (y (read))) (equal? x y)) RET 'a RET (quote a) RET
<pjb> jusss: see: http://paste.lisp.org/display/304200  [01:26]
<jusss> pjb: I really need a time to think about it, thanks very much  [01:29]
<jusss> I have to go  [01:30]
<pjb> Good night!
<jusss> good night

