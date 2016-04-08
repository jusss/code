#!/usr/bin/env racket
#lang racket
;;;this file is ~/lab/irc-client.rkt
;;;(load "lab/irc-client.rkt") 当出现输入的字符串在print-area的位置不正确,是因为print-area可写，写完信息后lock锁定可以解决这个问题
;;;如果服务器主动断开连接，好像(read-line in)读不到空字符串不知道怎么回事，所以不在这写空字符串判断了
(require racket/tcp)
(require racket/gui)
(require (file "~/lab/string-library.rkt"))

(define irc-client
  (lambda ()

(define frame1
  (new frame%
       (label "frame1")
       (width 800)
       (height 600)))

(define print-area
  (new text-field%
       (parent frame1)
       (label #f)
       (style '(multiple))
       ;;;(enabled #f) will get no scrollbar
       (enabled #t)))

(define print-text
  (send print-area get-editor))

;;;(define read-data
;;;  (lambda (in out read-strings)
;;;    (if (eof-object? read-strings)
;;;	'()
;;;	(begin
;;;	  ;;;把从socket接收到的信息发送到显示区域
;;;	  (send (send print-area get-editor)
;;;		insert
;;;		read-strings)
;;;	  
;;;           ;;; string match PING
;;;	  (if (find-string-a-in-string-b "PING :"
;;;					 read-strings)
;;;	      (begin (write-string
;;;		      (string-a-merge-string-b
;;;		       "PONG :"
;;;		       (get-rest-string-from-string "PING :" read-strings))
;;;		      out)
;;;		     (flush-output out))
;;;	      '())
;;;	  
;;;          ;;; tail call for loop
;;;	  (read-data in out (read-line in))))))

(define read-data
  (lambda (in out read-strings)
    (if (eof-object? read-strings)
	'()
	(begin
	  (if (find-string "PING :"
			   (n-to-m-string read-strings 1 6))
	      '()
	      (if (find-string " PRIVMSG #ubuntu-cn :" read-strings)
		  (begin (send print-text lock #f)
			 (send print-text
			       insert
			       (merge-string
				(merge-string
				 (merge-string "<"
					       (rest-string ":"
							    (front-string "!~"
									  read-strings)))
				 "> ")
				(rest-string " PRIVMSG #ubuntu-cn :" read-strings)))
			 (send print-text lock #t))
		  
             	  ;;;把从socket接收到的信息发送到显示区域
		  (begin (send print-text lock #f)
			 (send print-text
			       insert
			       read-strings)
			 (send print-text lock #t))))
	  
           ;;; string match PING
	  (if (find-string "PING :"
			   read-strings)
	      (begin (write-string
		      (merge-string "PONG :"
				    (rest-string "PING :" read-strings))
		      out)
		     (flush-output out))
	      '())
	  
          ;;; tail call for loop
	  (read-data in out (read-line in))))))

(define (icbot)
  ;;; send user name and nick
  (write-string "nick all-l28 \r\n" out)
  (write-string "user all-l4 8 * :all-l4 \r\n" out)
  (write-string "join #ubuntu-cn \r\n" out)
  ;;; flush it for send
  (flush-output out)
  ;;; read data from server
  (read-data in out (read-line in)))

;;;(define send-msg
;;;  (let ((kbd-input "")
;;;	(send-irc-msg "")
;;;	(display-out-msg ""))
;;;    (lambda (t e)
;;;      (if (eq? (send e get-event-type)
;;;	       'text-field-enter)
;;;	  (begin
;;;	    (set! kbd-input (send t get-value))
;;;	    (if (find-string (n-to-m-string kbd-input 1 1)
;;;			     "/")
;;;		(begin
;;;		  (set! send-irc-msg
;;;		    (merge-string
;;;		     (rest-string "/" kbd-input)
;;;		     "\r\n"))
;;;		  (set! display-out-msg
;;;		    (merge-string kbd-input "\n")))
;;;		(begin 
;;;		  (set! send-irc-msg
;;;		    (string-append "PRIVMSG #ubuntu-cn :"
;;;				   kbd-input
;;;				   "\r\n"))
;;;		  (set! display-out-msg
;;;		    (string-append "PRIVMSG #ubuntu-cn :"
;;;				   kbd-input
;;;				   "\n"))))
;;;	    (write-string send-irc-msg out)
;;;	    (flush-output out)
;;;	    (send (send print-area get-editor)
;;;		  insert
;;;		  display-out-msg)
;;;	    (send (send t get-editor) erase))
;;;	  '()))))

(define send-msg
  (let ((kbd-input "")
	(send-irc-msg "")
	(display-out-msg ""))
    (lambda (t e)
      (if (eq? (send e get-event-type)
	       'text-field-enter)
	  (begin
	    (set! kbd-input (send t get-value))
	    (if (find-string (n-to-m-string kbd-input 1 1)
			     "/")
		(begin
		  (set! send-irc-msg
		    (merge-string
		     (rest-string "/" kbd-input)
		     "\r\n"))
		  (set! display-out-msg
		    (merge-string kbd-input "\n")))
		
		(begin 
		  (set! send-irc-msg
		    (string-append "PRIVMSG #ubuntu-cn :"
				   kbd-input
				   "\r\n"))
		  (set! display-out-msg
		    (string-append "<all-128> "
				   kbd-input
				   "\n"))))
	    (write-string send-irc-msg out)
	    (flush-output out)
	    (send print-text lock #f)
	    (send print-text
		  insert
		  display-out-msg)
	    (send print-text lock #t)
	    (send (send t get-editor) erase))
	  '()))))

;;;添加输入框，检测到回车就发送字符串到socket
(new text-field%
	      (parent frame1)
	      (label #f)
	      (min-height 25)
	      (callback
	       (lambda (t e)
		 (send-msg t e))))

(send frame1 show #t)

(define-values (in out) (tcp-connect "irc.freenode.net" 6665))

;;;GUI编程时，如果有循环，貌似就只能把循环放到另一个线程里来解决了，因为GUI本身就是个循环,然后再有个函数循环就只能把函数循环放到另一个线程这样才能同时运行
;;;用多线程把icbot这个循环读取socket的procedure放到另一个线程里，不阻塞当前线程
(define (parallel-execute . thunks)
  (for-each thread thunks))
(parallel-execute (lambda () (icbot)))

))

(irc-client)

