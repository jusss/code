
f::Int->Int
f(0)=0
f(1)=1
f(n)=f(n-1)+f(n-2)

(let ((f (lambda (n) (cond ((eq? n 0) 0) ((eq? n 1) 1) (else (+ (f (- n 1)) (f (- n 2)))))))) (f 42))

(define (f n) (cond ((eq? n 0) 0) ((eq? n 1) 1) (else (+ (f (- n 1)) (f (- n 2))))))
