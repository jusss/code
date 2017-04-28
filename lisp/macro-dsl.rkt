(define-syntax wait
  (syntax-rules (for)
		((wait n unit)
		(let ((time-table
			(letrec ((s 1)
				 (m (* 60 s))
			 	 (h (* 60 m))
			 	 (d (* 24 h))
			 	 (month (* 30 d))
			 	 (y (* 12 month)))
			 `((s . ,s) (m . ,m) (h . ,h) (d . ,d) (month . ,month) (y . ,y)))))
		  (sleep (* n (cdr (assq 'unit time-table))))))
		  ((wait n unit for function ...)
		   (begin (wait n unit)
		   	  function ...))))
(define-syntax myloop
  (syntax-rules ()
		((myloop n function)
		 (let ((alist (call/cc (lambda (k) (cons k n)))))   ;;;返回一个improper list里面存储continuation和控制条件循环的变量
		   (if (< (cdr alist) 2)
		       function
		     (begin function
			    ((car alist) (cons (car alist) (- (cdr alist) 1)))))))))
(define-syntax inc!
    (syntax-rules ()
        ((_ var)                 
         (set! var (+ var 1)))))  

(define-syntax push!
    (syntax-rules ()
        ((_ atom alist)
         (begin (set! alist (cons atom alist))
                alist))))

(define-syntax swap!
    (syntax-rules ()
      ((_ a b)
       (let ((c a))
     (set! a b)
     (set! b c)))))

(define-syntax nil!
    (syntax-rules () 
      ((nil! var)        ;此处的nil!可以用_替代
       (set! var '()))))
(define-syntax run
    (syntax-rules (you clever boy and remember)
        ((run you clever boy and remember) (exit))))
