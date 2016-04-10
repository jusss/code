#!/usr/bin/env racket
#lang racket
(require openssl)
(require "string-library.rkt")

(define server-address "xxx")
(define server-port 993)
(define protocol 'sslv3)
(define user "xxx")
(define password "xxx")

(define-values (read-port write-port)
  (ssl-connect server-address server-port protocol))

(write-string (merge-strings `("a_tag login " ,user " " ,password "\r\n"))
	      write-port)
(write-string "a_tag select inbox\r\n" write-port)
(write-string "a_tag idle\r\n" write-port)

(flush-output write-port)

(define read-data
  (lambda (a-port a-string)
    (write-string a-string)
    (newline)
    (if (find-string "RECENT" a-string)
	(if (find-string "* 0 RECENT" a-string)
	    '()
	    (system "/home/xxx/lab/notifier.rkt new_mail &"))
	'())
    (if (eof-object? a-port)
	"network disconnect..."
	(read-data a-port (read-line a-port)))))

(read-data read-port " ")



	
	


	
