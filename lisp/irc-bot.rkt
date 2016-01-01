(require racket/control)
(require racket/tcp)
;;; string-prefix-ci? is in srfi/13 library
(require srfi/13)

;;; read data from server
(define read-data
  (lambda (in out read-strings)
    ;;; read data and print 
    (write-string read-strings)
    (newline)
    ;;; string match PING
    (if (find-string-a-in-string-b "PING :" read-strings)
	(begin 
	  (write-string
	   (string-a-merge-string-b "PONG :"
				    (get-rest-string-from-string "PING :"
								 read-strings))
	   out)
	  (flush-output out))
	'())
    ;;; tail call for loop
    (read-data in out (read-line in))))

(define (icbot)
  ;;; make a socket
  (define-values (in out) (tcp-connect "irc.freenode.net" 6665))
  ;;; send user name and nick
  (write-string "nick all-l26 \r\n" out)
  (write-string "user all-l4 8 * :all-l4 \r\n" out)
  (write-string "join #ubuntu-cn \r\n" out)
  ;;; flush it for send
  (flush-output out)
  ;;; read data from server
  (read-data in out "connect..."))

(icbot)


;;;列表的第一个元素在列表的位置是1, oh god,正常一回吧，像c的数组那种从0开始实在是不符合人类计数习惯，第0个元素，怎么听怎么别扭，所以完全匹配时返回的list-a的第一个元素在list-b
;;;的位置，那个数是在list-b第一个元素的位置是1开始数的
;;;比较list-a的首个字符和list-b,直到首个字符匹配才比较list-a的第二个字符和剩下的list-b
;;;如果接着匹配成功，然后带着剩下的list-a和剩下的list-b接着匹配，循环n回后,如果完全匹配,list-a最终为空列表
;;;如果匹配不成功，就接着从原始的list-a的首字符和剩下的list-b匹配,最后list-b的长度小于list-a时就能证明不匹配
;;;比较car list-a和car list-b,不匹配, 原始的list-a 和 cdr list-b递归
;;;car list-a和car list-b匹配时 cdr list-a和cdr list-b递归
;;;第一个就是比较car list-a和car list-b
;;;有三种情况，1. list-a在list-b最后一个字符前匹配上了，
;;;2. list-a在list-b在最后一个字符才完全匹配,
;;;3. list-a和list-b不匹配
;;;list-a为空列表时返回计数器-a的长度,对应1和2
;;;当list-b长度小于list-a时返回 #f,对应3 因为一直在递归而list-b的长度一直在减小
;;;(可有可无list-b为空列表时切list-a不为空列表返回#f)
;;;来个计数器，每cdr list-b递归一次，计数器加1,当car list-a为空列表时返回 计数器-a的长度,这个就是list-a的首个字符在list-b中的位置

;;;(define find-string-a-in-string-b
;;;  (lambda (string-a string-b)
;;;    (let ((list-a (string->list string-a))
;;;	  (origin-list-a (string->list string-a))
;;;	  (list-b (string->list string-b))
;;;	  (offset-count 1))
;;;      (define find-list-a-in-list-b
;;;	(lambda (list-a list-b offset-count)
;;;	  (if (eq? list-a '())
;;;	      (- offset-count (length origin-list-a))
;;;	      (if (> (length list-a) (length list-b))
;;;		  #f
;;;		  (if (eq? (car list-a) (car list-b))
;;;		      (find-list-a-in-list-b (cdr list-a)
;;;					     (cdr list-b)
;;;					     (+ 1 offset-count))
;;;		      (find-list-a-in-list-b origin-list-a
;;;					     (cdr list-b)
;;;					     (+ 1 offset-count)))))))
;;;      (find-list-a-in-list-b list-a list-b offset-count))))


;;;(define find-string-a-in-string-b
;;;  (lambda (string-a string-b)
;;;    (define list-a (string->list string-a))
;;;    (define origin-list-a (string->list string-a))
;;;    (define list-b (string->list string-b))
;;;    (define offset-count 1)
;;;    (define find-list-a-in-list-b
;;;      (lambda (list-a list-b offset-count)
;;;	(if (eq? list-a '())
;;;	    (- offset-count (length origin-list-a))
;;;	    (if (> (length list-a) (length list-b))
;;;		#f
;;;		(if (eq? (car list-a) (car list-b))
;;;		    (find-list-a-in-list-b (cdr list-a)
;;;					   (cdr list-b)
;;;					   (+ 1 offset-count))
;;;		    (find-list-a-in-list-b origin-list-a
;;;					   (cdr list-b)
;;;					   (+ 1 offset-count)))))))
;;;    (find-list-a-in-list-b list-a list-b offset-count)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;在string-b中寻找string-a,找到就返回string-a的首字符在string-b中的位置,找不到就返回#f,不论是string或list,第一个的元素的位置都是1,而不是0

(define find-all-elements-of-list-a-in-list-b
  (lambda (list-a list-b)
    (define list-b-offset-count 1)
    (define origin-list-a list-a)
    
    (define match-all-elements-of-list-a-in-list-b
      (lambda (list-a list-b list-b-offset-count)
	(if (eq? list-a '())
	    (- list-b-offset-count (length origin-list-a))
	    (if (> (length list-a) (length list-b))
		#f
		(if (eq? (car list-a) (car list-b))
		    (match-all-elements-of-list-a-in-list-b (cdr list-a)
							    (cdr list-b)
							    (+ 1 list-b-offset-count))
		    (match-all-elements-of-list-a-in-list-b origin-list-a
							    (cdr list-b)
							    (+ 1 list-b-offset-count)))))))
    
    (match-all-elements-of-list-a-in-list-b list-a list-b list-b-offset-count)))

(define find-string-a-in-string-b
  (lambda (string-a string-b)
    (find-all-elements-of-list-a-in-list-b (string->list string-a)
					   (string->list string-b))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; 得到匹配字符串之后的所有字符串,返回#f如果不匹配,如果字串1比字串2长，返回#f

(define get-rest-list-from-list
  (lambda (list-a list-b)
    (define list-b-offset-count 1)
    (define origin-list-a list-a)
    
    (define match-all-elements-of-list-a-in-list-b
      (lambda (list-a list-b list-b-offset-count)
	(if (eq? list-a '())
	    list-b
	    (if (> (length list-a) (length list-b))
		#f
		(if (eq? (car list-a) (car list-b))
		    (match-all-elements-of-list-a-in-list-b (cdr list-a)
							    (cdr list-b)
							    (+ 1 list-b-offset-count))
		    (match-all-elements-of-list-a-in-list-b origin-list-a
							    (cdr list-b)
							    (+ 1 list-b-offset-count)))))))
    
    (match-all-elements-of-list-a-in-list-b list-a list-b list-b-offset-count)))

(define get-rest-string-from-string
  (lambda (string-a string-b)
    (define return-value (get-rest-list-from-list (string->list string-a)
						  (string->list string-b)))
    (if return-value
	(list->string return-value)
	#f)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;得到匹配字符串之前的所有字符串,返回#f如果不匹配,如果字串1比字串2长，返回#f

(define get-front-elements-from-list
  (lambda (list-a list-b)
    (define list-b-offset-count 1)
    (define origin-list-a list-a)
    
    (define match-all-elements-of-list-a-in-list-b
      (lambda (list-a list-b list-b-offset-count store-car-list-b)
	(if (eq? list-a '())
	    (get-front-n-elements-from-list
	     (- (length store-car-list-b) (length origin-list-a))
	     (reverse store-car-list-b))
	    (if (> (length list-a) (length list-b))
		#f
		(if (eq? (car list-a) (car list-b))
		    (match-all-elements-of-list-a-in-list-b (cdr list-a)
							    (cdr list-b)
							    (+ 1 list-b-offset-count) (cons (car list-b) store-car-list-b))
		    (match-all-elements-of-list-a-in-list-b origin-list-a
							    (cdr list-b)
							    (+ 1 list-b-offset-count) (cons (car list-b) store-car-list-b)))))))
    
    (match-all-elements-of-list-a-in-list-b list-a
					    list-b
					    list-b-offset-count
					    '())))


(define get-front-string-from-string
  (lambda (string-a string-b)
    (define return-value (get-front-elements-from-list (string->list string-a)
						       (string->list string-b)))
    (if return-value
	(list->string return-value)
	#f)))

;;;得到前面n个元素从一个列表,如果n比列表长度大，返回#f
(define get-front-n-elements-from-list
  (lambda (n list-a)
    
    (define get-elements-from-list
      (lambda (n list-a store-car-list)
	(if (< n 1)
	    (reverse store-car-list)
	    (get-elements-from-list (- n 1) (cdr list-a) (cons (car list-a) store-car-list)))))
    
    (if (> n (length list-a))
	#f
	(get-elements-from-list n list-a '()))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
;;;6个函数，列表3个，字符串3个
;;;1. 得到从匹配的地方开始到b的结尾
;;;2. 得到匹配后剩下的到b的结尾
;;;3. 得到nth到mth的这一段的b

;;;2种写法，第一种写法,用get-nth-element-from-list, 从beginning开始，每car list-b一个放到list-a, beginning加1,当begnning等于ending时返回list-a
;;;第二种写法, 从n到m取出一个列表, 3种情况 1,offset<n 2.n<offset<m 3. m<offset
;;;1.计数器从1开始，当计数器<n 每递归一次 list-a变成 cdr list-a, store-car-list不变, 计数器加1
;;;2.当计数器大于n且小于m,每次递归list-a变成cdr list-a,并把car list-a出来的元素存储进store-car-list,计数器加1,
;;;3.当计数器大于m时，返回store-car-list
;;;实际上判断条件应该是 3 2 1
;;; offset-count 大于等于n 可以写作 offset-count不小于n 也就是 offset-count小于n的逻辑取反
;;; n小于等于m小于等于list-a的长度，否则返回#f
;;;racket@> (get-n-to-m-from-string "abcdefg" 3 5) => "cde"
;;;racket@> (get-n-to-m-from-list '(1 2 3 4 5) 1 3) => '(1 2 3)
(define get-n-to-m-from-list
  (lambda (list-a n m)
    (define offset-count 1)
    (define store-car-list '())
    
    (define n-to-m
      (lambda (n m list-a store-car-list offset-count)
	(if (> offset-count m)
	    (reverse store-car-list)
	    (if (< offset-count n)
		(n-to-m n m (cdr list-a) store-car-list (+ 1 offset-count))
		(n-to-m n m (cdr list-a) (cons (car list-a) store-car-list) (+ 1 offset-count))))))
		
    
    (if (> n m)
	#f
	(if (> m (length list-a))
	    #f
	    (n-to-m n m list-a store-car-list offset-count)))))


(define get-n-to-m-from-string
  (lambda (string-a n m)
    (define list-a (string->list string-a))
    (if (> n m)
	#f
	(if (> m (length list-a))
	    #f
	    (list->string (get-n-to-m-from-list list-a n m))))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;得到第n个元素从列表，如果n大于列表长度返回#f    
(define get-nth-element-from-list
  (lambda (n a-list)
    (define continuation 0)
    (reset ((lambda (x)
	      (if (> x 1) (begin (set! x (- x 1))
				 (set! a-list (cdr a-list))
				 (continuation x))
		  (car a-list)))
	    (shift k (begin (set! continuation k)
			    (k n)))))))
;;;n小于等于list-a的长度，就是n不大于list-a的长度，n大于list-a的长度取反
;;; if把后面的2个参数换下位置就能把not去掉
;;; (if (not (> a b)) (+ 1 1) (+ 1 2)) 等同 (if (> a b) (+ 1 2) (+ 1 1))
;;;因为从1开始所以n减到1就结束了，所以n=1时,n<2
;;;racket@> (get-nth-element-from-list 9 '(1 2 3 4 5 6)) => 5
;;;racket@> (get-nth-element-from-list 9 '(1 2 3 4 5 6)) => #f

(define get-nth-element-from-list
  (lambda (n list-a)
    (if (> n (length list-a))
	#f
	(if (< n 2)
	    (car list-a)
	    (get-nth-element-from-list (- n 1) (cdr list-a))))))


(define get-nth-char-from-string)
(define get-n-char-behind-string) 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;列表合并和字符串合并 '(1 2 3) '(4 5 6) 合并成 '(1 2 3 4 5 6)
;;;先reverse '(1 2 3) 然后car '(4 5 6) 加进 '(3 2 1) 最后再reverse
;;;racket@> (string-a-merge-string-b "abc " "def s") => "abc def s"
;;;racket@> (list-a-merge-list-b '(1 2 3) '(4 5 6)) => '(1 2 3 4 5 6)
(define list-a-merge-list-b
  (lambda (list-a list-b)
    (define reverse-list-a (reverse list-a))
    
    (define merge-with-car-cons
      (lambda (reverse-list-a list-b)
	(if (eq? list-b '())
	    (reverse reverse-list-a)
	    (merge-with-car-cons (cons (car list-b) reverse-list-a)
				 (cdr list-b)))))
    
    (merge-with-car-cons reverse-list-a list-b)))

(define string-a-merge-string-b
  (lambda (string-a string-b)
    (list->string
     (list-a-merge-list-b (string->list string-a)
			  (string->list string-b)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	    
	
(define string-replace)

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

(define list-a " ")

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
;;;字符串替换和字符串分割，可以用get-front-string-from-string和get-rest-string-from-string来搞,如替换"abc"为"def"在"aseabcseabc"中则先把第一个abc前边的ase搞出去然后剩下的再把前边的高出去，没高出去一个merge一个要替换的，最后在剩下的再找不到abc就merge剩下的返回
;;;分割和替换一样，不过替换是分割玩merge要替换的最后总的merge成一个字串返回
;;;而分割是分割成单个字串cons进列表里，最后返回一个列表
;;;最后将列表里的所有字串转换成符号然后求值
;;;列表比较函数，先把2个列表变成字符串，然后用find-string-a-in-string-b即可
		
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
*** nilg` (~user@92.247.176.166) has joined channel #scheme  [00:20]
<pjb> jusss: you need to use map to remove the quoted form: (map (lambda
      (quoted-form) (cadr quoted-form)) '('+ '1 '2)) #| --> (+ 1 2) |#  [00:22]
*** nilg (~user@92.247.176.166) has quit: Ping timeout: 255 seconds  [00:23]
<pjb> jusss: but it's idiotic to turn a string like "(+ 1 2)" into a list ('+
      '1 '2). It would be saner to turn it into a list (+ 1 2) directly.
								        [00:24]
<jusss> pjb: how ?
<pjb> read from string port.
*** nilg``` (~user@92.247.176.166) has joined channel #scheme
<pjb> in CL, just use read-from-string.  [00:25]
<jusss> pjb: and scheme ?
<pjb> in scheme read from string port.
*** nilg` (~user@92.247.176.166) has quit: Ping timeout: 245 seconds
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
*** Riastradh (~riastradh@netbsd/developer/riastradh) has joined channel
    #scheme  [23:38]
<ggole> (apply (car list) (cdr list))  [23:39]
<ggole> Or possibly eval, depending on what this form might look like  [23:40]
*** jyc (~jonathan@2600:3c00:e000:a5::) has quit: Ping timeout: 240 seconds
								        [23:46]
*** nilg (~user@92.247.176.166) has joined channel #scheme
<jusss> ggole: get error mesg, '+ is not a procedure  [23:56]
<jusss> ggole: I turn a string like "(+ 1 1)" to a list ('+ '1 '1), now I'd
	like to eval it like eval (+ 1 1)  [23:57]
<ggole> O_o  [23:58]
<ggole> Well, remove the quotes first
<jusss> but I don't know how to transform
*** Riastradh (~riastradh@netbsd/developer/riastradh) has quit: Ping timeout:
    246 seconds
<jusss> ggole: how  [23:59]

[Thu Dec 31 2015]
<ggole> jusss: figure out how to turn '1 into 1. Then, figure out how to do
	that for each element of the list.  [00:01]
*** jcowan (~jcowan@static-108-30-103-116.nycmny.fios.verizon.net) has joined
    channel #scheme
*** jcowan_ (~jcowan@static-108-30-103-116.nycmny.fios.verizon.net) has joined
    channel #scheme
*** jcowan_ (~jcowan@static-108-30-103-116.nycmny.fios.verizon.net) has quit:
    Read error: Connection reset by peer
*** GGMethos (methos@2600:3c00::f03c:91ff:fea8:426e) has joined channel
    #scheme  [00:02]
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
*** nilg` (~user@92.247.176.166) has joined channel #scheme  [00:20]
<pjb> jusss: you need to use map to remove the quoted form: (map (lambda
      (quoted-form) (cadr quoted-form)) '('+ '1 '2)) #| --> (+ 1 2) |#  [00:22]
*** nilg (~user@92.247.176.166) has quit: Ping timeout: 255 seconds  [00:23]
<pjb> jusss: but it's idiotic to turn a string like "(+ 1 2)" into a list ('+
      '1 '2). It would be saner to turn it into a list (+ 1 2) directly.
								        [00:24]
<jusss> pjb: how ?
<pjb> read from string port.
*** nilg``` (~user@92.247.176.166) has joined channel #scheme
<pjb> in CL, just use read-from-string.  [00:25]
<jusss> pjb: and scheme ?
<pjb> in scheme read from string port.
*** nilg` (~user@92.247.176.166) has quit: Ping timeout: 245 seconds
<pjb> jusss: now, of course, string ports are not standard r5rs, so you would
      first save the string to a file then reopen the file and read from it.
								        [00:26]
<jusss> pjb: how repl works ?  [00:27]
<pjb> you launch a scheme implementation and type stuff
<jusss> pjb: so repl don't receive your input stuff as strings ?  [00:28]
<pjb> No, it uses read directly. REPL = (loop (print (eval (read)))).  [00:29]
<pjb> jusss: you may find string ports in your implementation extensions.
								        [00:30]
*** cemerick (~cemerick@c-24-34-140-98.hsd1.ma.comcast.net) has joined channel
    #scheme
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
*** _sjs (~steven.sp@108-228-29-235.lightspeed.sntcca.sbcglobal.net) has quit:
    Ping timeout: 272 seconds
<wasamasa> it is there in ruby though  [00:33]
*** jyc (~jonathan@2600:3c00:e000:a5::) has joined channel #scheme
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
*** Beluki (~HexChat@39.46.165.83.dynamic.reverse-mundo-r.com) has quit: Quit:
    Beluki  [00:49]
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
*** O7_ (~d@185.57.82.25) has joined channel #scheme  [00:51]
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
*** O7 (~d@185.57.82.25) has quit: Ping timeout: 272 seconds  [00:53]
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
*** O7_ (~d@185.57.82.25) is now known as O7
<pjb> It ignores the modularity of the lisp reader.
<jusss> pjb: I will try this (string->symbol "a") in guile  [00:56]
<pjb> What did you get for  [00:58]
<pjb> Type: (list? (read)) RET 'a RET
<pjb> Type: (symbol? (read)) RET 'a RET
<pjb>  
<pjb> >
*** nilg``` (~user@92.247.176.166) has quit: Remote host closed the connection
								        [00:59]
<jusss> pjb: in guile, (define a 10) (symbol? a) => #f
<jusss> pjb: in guile, 'a => a, (string->symbol "a") => a, (car (cdr ''a)) =>
	a  [01:00]
<pjb> yes, 10 is not a symbol
<pjb> (define sym 'a) (symbol? sym) -> #f
<pjb> 10 is an integer.
<pjb> have you read 2.1?  [01:01]
*** jcowan_ (~jcowan@static-108-30-103-116.nycmny.fios.verizon.net) has joined
    channel #scheme
<pjb> Notice that by 2.1 42<35 is not a standard identifier, but
      implementation dependant. It could be something else than a symbol in a
      different implementation. DUH.  In CL it's a symbol by standard.  [01:02]
*** jcowan__ (~jcowan@static-108-30-103-116.nycmny.fios.verizon.net) has
    joined channel #scheme  [01:03]
*** jcowan (~jcowan@static-108-30-103-116.nycmny.fios.verizon.net) has quit:
    Ping timeout: 240 seconds  [01:04]
*** _sjs (~steven.sp@173.226.103.101) has joined channel #scheme  [01:05]
<jusss> now I'm totally confused about identifer and symbol  [01:07]
<pjb> Yes, scheme is confusing.  Assume they're the same.
*** jcowan_ (~jcowan@static-108-30-103-116.nycmny.fios.verizon.net) has quit:
    Ping timeout: 276 seconds
*** tmtwd (~tmtwd@CPE0c473da71813-CM0c473da71810.cpe.net.cable.rogers.com) has
    joined channel #scheme
<ggole> Most of the difference is that you can create symbols from arbitrary
	strings with string->symbol: identifiers are the subset that read will
	create for you from scheme source.  [01:08]
<ggole> (That's probably a bit of a simplification.)
<jusss> (define a 10) (+ 1 (car (cdr ''a)))  [01:10]
<jusss> get error
<pjb> Yes, you cannot add symbols to numbers.  [01:11]
<pjb> or numbers to symbols.
*** cemerick (~cemerick@c-24-34-140-98.hsd1.ma.comcast.net) has quit: Ping
    timeout: 245 seconds  [01:12]
*** bb010g (uid21050@gateway/web/irccloud.com/x-cremdfzsscurawzn) has joined
    channel #scheme  [01:13]
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
*** badkins (~badkins@cpe-107-15-212-104.nc.res.rr.com) has quit: Ping
    timeout: 246 seconds
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
*** lambda-11235 (~lambda-11@75-111-50-39.erkacmtk01.res.dyn.suddenlink.net)
    has joined channel #scheme
<pjb> Try: (read) RET 'a RET
<pjb> Try: (read) RET (quote a) RET
<pjb> Try: (let ((x (read)) (y (read))) (equal? x y)) RET 'a RET (quote a) RET
								        [01:23]
*** jcowan_ (~jcowan@static-108-30-103-116.nycmny.fios.verizon.net) has joined
    channel #scheme  [01:24]
<pjb> jusss: see: http://paste.lisp.org/display/304200  [01:26]
*** jcowan__ (~jcowan@static-108-30-103-116.nycmny.fios.verizon.net) has quit:
    Ping timeout: 255 seconds  [01:28]
<jusss> pjb: I really need a time to think about it, thanks very much  [01:29]
<jusss> I have to go  [01:30]
<pjb> Good night!
<jusss> good night

