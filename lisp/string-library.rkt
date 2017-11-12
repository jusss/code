#lang racket
(provide (all-defined-out))

;;;        写函数的第一件事就是判断参数类型！判断参数类型！判断参数类型！

;;;provide所有函数的定义，当然也可单独(provide find-string)只provide find-string这一个函数
;;;然后在其它文件里用(require (file "~/lab/string-library.rkt"))然后就能调用这个文件里所有的函数了,这种方式比(load ...)更好
;;;(load "lab/string-library.rkt")  文件位置是 ~/lab/string-library.rkt

;;;(find-string string-a string-b) 在string-b中找string-a并返回string-a的首字符在string-b中的位置，第一个元素的位置是1,如果没找到返回#f,如果2个参数中有一个是#f,直接返回#f
;;;(find-list list-a list-b) 在list-b中寻找list-a的所有元素并返回list-a的第一个元素在list-b中的位置,第一个元素的位置是1,如果没找到返回#f
;;;(rest-string string-a string-b) 返回string-b中string-a后面的所有字符串 如果没在string-b中找到string-a返回 #f
;;;(rest-list list-a list-b) 返回list-b中list-a的所有元素之后的所有元素 如果没在list-b中找到list-a的所有元素返回 #f
;;;(front-n-list n list-a) 返回list-a中前n个元素, 如果n大于list-a的长度 返回 #f
;;;(front-string string-a string-b) 返回string-b中string-a之前的字符串 如果没在string-b中找到string-a 返回 #f
;;;(front-list list-a list-b) 返回list-b中list-a的前面元素，如果没在list-b中找到list-a就返回 #f
;;;(n-to-m-list list-a n m) 返回list-a中第n个到第m个中间的元素,n小于等于m且m小于等于list-a的长度，若n>m或m>list-a的长度则返回 #f
;;;(n-to-m-string string-a n m)返回string-a中第n个字符到第m个字符这一段的字符串,若n>m或m>string-a的长度则返回 #f 如果string-a不是字符串返回#f, n m不是数字返回#f
;;;(nth-element nth list-a) 返回list-a中第n个元素，如果n大于list-a的长度返回 #f
;;;(merge-list list-a list-b) 返回合并的list-a和list-b, list-a在list-b之前
;;;(merge-string string-a string-b) 返回合并的string-a和string-b, string-a在string-b之前
;;;(merge-strings string-list) 将列表中的字符串依次合并，返回合并后的字符串
;;;(replace-string string-a string-b string-c) 把string-c中的string-a替换为string-b并返回, 如果在string-c中没找到string-a,则string-c原封不动返回
;;;(split-string string-a string-b) 用string-b分割string-a，返回分割之后的字符串列表 如果在string-b中没找到string-a,就返回包含原封不动的string-b的列表
;;;(string-list->symbol-list string-list) 把字符串列表变成符号列表返回
;;;(list-eq? list-a list-b) 比较list-a和list-b是否相同，是 返回#t, 否 返回#f 如果想比较列表长短用length 比较list-a是否包含在list-b里用find-list
;;;(find-index-string index-string string-list) 在字符串列表里寻找包含index-string的字符串元素，并返回第一个匹配的，否则返回#f


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
    (if (and string-a string-b)
	(find-all-elements-of-list-a-in-list-b (string->list string-a)
					       (string->list string-b))
	#f)))

(define find-string find-string-a-in-string-b)
;;;(find-string string-a string-b) 在string-b中找string-a并返回string-a的首字符在string-b中的位置，第一个元素的位置是1,如果没找到返回#f
(define find-list find-all-elements-of-list-a-in-list-b)
;;;(find-list list-a list-b) 在list-b中寻找list-a的所有元素并返回list-a的第一个元素在list-b中的位置,第一个元素的位置是1,如果没找到返回#f

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

(define rest-string get-rest-string-from-string)
;;;(rest-string string-a string-b) 返回string-b中string-a后面的所有字符串 如果没在string-b中找到string-a返回 #f
(define rest-list get-rest-list-from-list)
;;;(rest-list list-a list-b) 返回list-b中list-a的所有元素之后的所有元素 如果没在list-b中找到list-a的所有元素返回 #f

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;得到匹配字符串之前的所有字符串,返回#f如果不匹配,如果字串1比字串2长，返回#f
;;; get strings before string-b in string-a

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

(define front-n-list get-front-n-elements-from-list)
;;;(front-n-list n list-a) 返回list-a中前n个元素, 如果n大于list-a的长度 返回 #f
(define front-string get-front-string-from-string)
;;;(front-string string-a string-b) 返回string-b中string-a之前的字符串 如果没在string-b中找到string-a 返回 #f
(define front-list get-front-elements-from-list)
;;;(front-list list-a list-b) 返回list-b中list-a的前面元素，如果没在list-b中找到list-a就返回 #f

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    

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
      (if (and (string? string-a) (number? n) (number? m))
	  (if (> n m)
	      #f
	      (if (> m (length (string->list string-a)))
		  #f
		  (list->string (get-n-to-m-from-list (string->list string-a) n m))))
	  #f)))

(define n-to-m-list get-n-to-m-from-list)
;;;(n-to-m-list list-a n m) 返回list-a中第n个到第m个中间的元素,n小于等于m且m小于等于list-a的长度，若n>m或m>list-a的长度则返回 #f
(define n-to-m-string get-n-to-m-from-string)
;;;(n-to-m-string string-a n m)返回string-a中第n个字符到第m个字符这一段的字符串,若n>m或m>string-a的长度则返回 #f


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;得到第n个元素从列表，如果n大于列表长度返回#f    
;;;(define get-nth-element-from-list
;;;  (lambda (n a-list)
;;;    (define continuation 0)
;;;    (reset ((lambda (x)
;;;	      (if (> x 1) (begin (set! x (- x 1))
;;;				 (set! a-list (cdr a-list))
;;;				 (continuation x))
;;;		  (car a-list)))
;;;	    (shift k (begin (set! continuation k)
;;;			    (k n)))))))
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

(define nth-element get-nth-element-from-list)
;;;(nth-element nth list-a) 返回list-a中第n个元素，如果n大于list-a的长度返回 #f

;;;(define get-nth-char-from-string) 可以用n-to-m-string搞定，只要让n=m即可
;;;(define get-n-char-behind-string) 可以用find-string找到位置，然后n-to-m-string搞定 也可以rest-string之后再n-to-m-string搞定

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

(define merge-list list-a-merge-list-b)
;;;(merge-list list-a list-b) 返回合并的list-a和list-b, list-a在list-b之前
(define merge-string string-a-merge-string-b)
;;;(merge-string string-a string-b) 返回合并的string-a和string-b, string-a在string-b之前

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;字符串替换和字符串分割，可以用get-front-string-from-string和get-rest-string-from-string来搞,如替换"abc"为"def"在"aseabcseabc"中则先把第一个abc前边的ase搞出去然后剩下的再把前边的高出去，没高出去一个merge一个要替换的，最后在剩下的再找不到abc就merge剩下的返回
;;;分割和替换一样，不过替换是分割玩merge要替换的最后总的merge成一个字串返回
;;;而分割是分割成单个字串cons进列表里，最后返回一个列表
;;;最后将列表里的所有字串转换成符号然后求值
;;;列表比较函数，先把2个列表变成字符串，然后用find-string-a-in-string-b即可

(define replace-string-a-with-string-b-in-string-c
  (lambda (string-a string-b string-c)
    (define replace-in-string-c
      (lambda (store-string string-c)
	(if (not (get-front-string-from-string string-a string-c))
	    (string-a-merge-string-b store-string string-c)
	    (replace-in-string-c
	     (string-a-merge-string-b
	      (string-a-merge-string-b store-string
				       (get-front-string-from-string string-a
								     string-c))
	      string-b)
	     (get-rest-string-from-string string-a string-c)))))
    (replace-in-string-c "" string-c)))

(define replace-string replace-string-a-with-string-b-in-string-c)
;;;(replace-string string-a string-b string-c) 把string-c中的string-a替换为string-b并返回, 如果在string-c中没找到string-a,则string-c原封不动返回

(define split-string-a-with-string-b
  (lambda (string-a string-b)
    (define split-string-a
      (lambda (store-list string-a)
	(if (not (get-front-string-from-string string-b string-a))
	    (reverse (cons string-a store-list))
	    (split-string-a
	     (cons (get-front-string-from-string string-b string-a) store-list)
	     (get-rest-string-from-string string-b string-a)))))
    (split-string-a '() string-a)))

(define split-string split-string-a-with-string-b)
;;;(split-string string-a string-b) 用string-b分割string-a，返回分割之后的字符串列表 如果在string-b中没找到string-a,就返回包含原封不动的string-b的列表

;;;数字应该是1.2 4/3 这样的，也就是0到9 . / -这13个字符,把字符串转成字符列表去匹配这13个字符, 但还是无法判断16进制字符串表示字符串还是表示16进制数, 如果真的是个字符串"12"，""12""就是错的，更别提解析了

(define string-list->symbol-list
  (lambda (string-list)
;;;    0 1 2... and booleans
    
    (map string->symbol string-list)))

;;;(string-list->symbol-list string-list) 把字符串列表变成符号列表返回

(define list-eq?
  (lambda (list-a list-b)
    (if (eq? (length list-a)
	     (length list-b))
	(if (eq? (find-all-elements-of-list-a-in-list-b list-a list-b) 1)
	    #t
	    #f)
	#f)))
;;;(list-eq? list-a list-b) 比较list-a和list-b是否相同，是 返回#t, 否 返回#f 如果想比较列表长短用length 比较list-a是否包含在list-b里用find-list


(define merge-str
  (lambda (string-list expect-string)
    (if (eq? string-list '())
	expect-string
	(merge-str (cdr string-list)
		   (merge-string expect-string
				 (car string-list))))))

(define merge-strings
  (lambda (a-string-list)
    (merge-str a-string-list "")))


(define (find-index-string index-string string-list)
    (if (empty? string-list) #f
      (if (find-string index-string (car string-list))
	  (car string-list)
	  (find-index-string index-string (cdr string-list)))))
;;;(find-index-string index-string string-list) 在字符串列表里寻找包含index-string的字符串元素，并返回第一个匹配的，否则返回#f
