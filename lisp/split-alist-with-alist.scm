(define split-with-N (lambda (alist a before)
                             (if (eq? alist '()) '()
                                 (if (eq? (car alist) a)
                                 (cons (reverse before) (cons (cdr alist) '()))
                                 (split-with-N (cdr alist) a (cons (car alist) before))))))
;;; (split-with-N (list 1 2 3) 2 '())

;;; http://matt.might.net/articles/cps-conversion/
(define (split-on a xs k)
  (cond ((null? xs) (k '() '()))
        ((eqv? a (car xs))
         (k '() (cdr xs)))
        (else
         (split-on a (cdr xs) (lambda (bs as)
                                (k (cons (car xs) bs) as))))))
;;; (split-on 3 (list 1 2 3 4 5) list)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define split-with-list
  (lambda (alist blist before n)
    (if (eq? alist '()) '()
        (if (eq? blist '()) (cons (reverse (remove-n before n)) (cons alist '()))
            (if (not (eq? (car alist) (car blist)))
                (split-with-list (cdr alist) blist (cons (car alist) before) n)
                (split-with-list (cdr alist) (cdr blist) (cons (car alist) before) n))))))

(define remove-n
  (lambda (alist n)
    (if (eq? n 0)
        alist
        (remove-n (cdr alist) (- n 1)))))

(define (split-list-with-list alist blist) (split-with-list alist blist '() (length blist)))

;;; > (split-list-with-list '(1 2 3 4 5 6) '(3 4))
;;; '((1 2) (5 6))
;;; > (split-list-with-list '(1 2 3 4 5 6) '(5 6))
;;; '()
;;; > (split-list-with-list '(1 2 3 4 5 6) '(4 5))
;;; '((1 2 3) (6))
;;; > (split-list-with-list '(1 2 3 4 5 6) '(9))
;;; '()
;;; > (split-list-with-list '(1 2 3 4 5 6) '(3))
;;; '((1 2) (4 5 6))
