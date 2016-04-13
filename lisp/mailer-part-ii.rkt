#!/usr/bin/env racket
#lang racket
(require openssl)
(require "string-library.rkt")

(define server-address "xxx")
(define server-port 993)
(define protocol 'sslv3)
(define user "xxx")
(define password "xxx")

(define counter 0)

(define-values (read-port write-port) (values 0 0))

;;;If a connection cannot be established by tcp-connect, the exn:fail:network exception is raised.

(with-handlers ((exn:fail:network?
		 (lambda (e)
		   (system "/home/xxx/lab/notifier \" Fail to Connect Mail Server, Restart after 3 minutes\" &")
		  ;;; if network is down, wait for 3 minutes then restart
		  (sleep 180)
		  (system "/home/xxx/lab/mailer-part-ii.rkt &")
		  (exit))))
  
  (set!-values (read-port write-port)
    (ssl-connect server-address server-port protocol))
  (write-string (merge-strings `("a_tag login " ,user " " ,password "\r\n"))
		write-port)
  (write-string "a_tag select inbox\r\n" write-port)
  (write-string "a_tag idle\r\n" write-port)
  
  (flush-output write-port))
  
		 
;;;(define connect-thread
;;;  (thread (lambda ()
;;;	    (set!-values (read-port write-port)
;;;	      (ssl-connect server-address server-port protocol))
;;;	    (set! counter (+ 1 counter)))))

;;;(define connect-detect-thread
;;;  (thread (lambda ()
;;;	    (sleep 4)
;;;	    (if (eq? 0 counter)
;;;		(begin
;;;		  (system "/home/xxx/lab/notifier \" Fail to Connect Mail Server, It will restart after 3 minutes\" &")
;;;		  ;;; if network is down, wait for 3 minutes then restart
;;;		  (sleep 180)
;;;		  (system "/home/xxx/lab/mailer-part-ii.rkt &")
;;;		  (exit))
;;;		'()))))

;;;(thread-wait connect-thread)

;;;use multi-thread to detect reading timeout, and use continuation make a loop inside threads

(define got-string " ")

(define read-thread
  (thread (lambda ()
	    (define thread-loop (call/cc (lambda (k) k)))
	    (set! got-string (read-line read-port))
	    (write-string got-string)
	    (newline)
	    (if (find-string "RECENT" got-string)
		(if (find-string "* 0 RECENT" got-string)
		    '()
	            ;;; escape the inner quotes with \
		    (system "/home/xxx/lab/notifier.rkt \" New Mail\" &"))
		'())
	    ;;; if it reads string, then counter add one
	    (set! counter (+ 1 counter))
	    (thread-loop thread-loop))))

(define upper-counter counter)

(define detect-read-thread
  (thread (lambda ()
	    (define thread-loop (call/cc (lambda (k) k)))
	    (set! upper-counter counter)
	    ;;; read nothing over 3 minutes, then restart
	    (sleep 180)
	    ;;; compare counter with counter that is 3 minutes ago, if it's same,
	    ;;; it means it reads nothing
	    (if (eq? upper-counter counter)
		(begin
		  (system "/home/xxx/lab/mailer-part-ii.rkt &")
		  (system "/home/xxx/lab/notifier.rkt \" Disconnect from Mail Server, Restart\" &")
		  (exit))
		(thread-loop thread-loop)))))

(thread-wait read-thread)
(thread-wait detect-read-thread)
	    


