#!/usr/bin/env racket
#lang racket

;;; tab 缩进 键盘事件, 多个channel 多个buffer 窗口, 高亮， 通知, quit时的eof 超时的eof 检测eof

;;;检测窗口是否最小化来决定是否开启通知窗口，或添加一按钮来控制，或检测当前窗口看有没有irc-client来控制
;;;当出现输入的字符串在print-area的位置不正确,是因为print-area可写，写完信息后lock锁定可以解决这个问题
;;;use exception to catch connecting failed
;;;use sync/timeout to instead of multi-thread for reading timeout
;;;client send quit signal to server, and server send client eof-object

(require racket/tcp)
(require racket/gui)
(require openssl)
;;;(require (file "~/lab/string-library.rkt"))
(require "string-library.rkt")

(define server-address "irc.freenode.net")
(define server-port 7000)
(define protocol 'auto)
(define nick "sdhwef")
(define password "xxx")
(define channel "#ubuntu-cn")
(define-values (read-port write-port) (values 0 0))

;;;use exception to catch connecting failed
(with-handlers ((exn:fail:network?
		 (lambda (e)
		   (system "/home/jusss/lab/notifier.rkt \" Fail to Connect Freenode, Restart after 3 minutes\" &")
		   ;;;if network is down, wait for 3 minutes then restart
		  (sleep 180)
		  (system "/home/jusss/lab/irc-client.rkt &")
		  (exit))))
  
  (set!-values (read-port write-port)
	       ;;; freenode's 6697 and 7000 etc are not same protocol, sslv3 or tls stuff, so use 'auto
	       (ssl-connect server-address server-port))
  (write-string (merge-strings `("nick " ,nick  " \r\n"))
		write-port)
  (write-string (merge-strings `("user " ,nick " 8 * :" ,nick " \r\n"))
		write-port)
  (write-string (merge-strings `("join " ,channel " \r\n"))
		write-port)
  (flush-output write-port))

(define irchat
  (new frame%
       (label "irchat")
       (width 800)
       (height 600)))

(define print-area
  (new text-field%
       (parent irchat)
       (label #f)
       (style '(multiple))
       ;;;(enabled #f) will get no scrollbar
       (enabled #t)))

(define print-text
  (send print-area get-editor))

(define read-from-server
  (lambda (read-port write-port text-field-editor got-string)
    ;;; if got-string is #f or eof then restart, it means reading timeout or server send disconnecting signal to client
    ;;; client send an exit signal to server, and server send eof to client
    ;;; another case, server send eof to client when client don't send exit signal, so don't detect eof as client's quit, detect the input keys of "/quit"
    (if (or (not got-string) (eof-object? got-string))
	(begin
	  (system "/home/jusss/lab/irc-client.rkt &")
	  (system "/home/jusss/lab/notifier.rkt \" Disconnect from Freenode, Restart\" &")
	  (exit))
	(begin 
	  ;;; it has three type messages, PING, PRIVMSG, others
	  (if (find-string "PING :"
			   (n-to-m-string got-string 1 6))
	      (begin
		(write-string (merge-string "PONG :"
					    (rest-string "PING :" got-string))
			      write-port)
		(flush-output write-port))
		  
	      (if (find-string (merge-strings `(" PRIVMSG " ,channel " :")) got-string)
		  (begin
		    (send text-field-editor lock #f)
		        ;;; import bugs, merge-strings's parameter is a list, but I misunderstand and write it as functions parameter, `(a b) into `(a return b)
		    (send print-text
			  insert
			  (merge-string
			   (merge-string
			    (merge-string "<"
					  (rest-string ":"
						       (front-string "!~"
								     got-string)))
			    "> ")
			   (rest-string " PRIVMSG #ubuntu-cn :" got-string)))
		    (send text-field-editor lock #t))
               	      ;;;把others信息发送到显示区域
		  (begin (send text-field-editor lock #f)
			 (send text-field-editor
			       insert
			       got-string)
			 (send text-field-editor lock #t))))
              ;;;use sync/timeout to instead of multi-thread for reading timeout
	  (read-from-server read-port
			    write-port
			    text-field-editor
			    (sync/timeout 200
					  (read-line-evt read-port)))))))


(define read-from-kbd-send-to-server
  (let ((kbd-input "")
	(send-irc-msg "")
	(display-out-msg ""))
    (lambda (t e)
      (if (eq? (send e get-event-type)
	       'text-field-enter)
	  (begin
	    (set! kbd-input (send t get-value))
	    ;;; the input message have two type, commands and normal messages, command start with "/"
	    (if (find-string (n-to-m-string kbd-input 1 1)
			     "/")
		(begin
		 ;;; if the input keys is "/quit" kill the thread of read from server
		  (if (find-string "/quit"
				   (n-to-m-string kbd-input 1 5))
		      (kill-thread read-from-server-thread)
		      '())
		  (if (find-string "/nick "
				   (n-to-m-string kbd-input 1 6))
		      (set! nick (rest-string "/nick " kbd-input))
		      '())
		  (set! send-irc-msg
		    (merge-string
		     (rest-string "/" kbd-input)
		     "\r\n"))
		  (set! display-out-msg
		    (merge-string kbd-input "\n")))
		(begin 
		  (set! send-irc-msg
		    (string-append (merge-strings `("PRIVMSG " ,channel " :"))
				   kbd-input
				   "\r\n"))
		  (set! display-out-msg
		    (string-append (merge-strings `("<" ,nick "> "))
				   kbd-input
				   "\n"))))
	    ;;; if you have already sent "/quit" then input something again, it will case an exception
	    (with-handlers ((exn:fail:network:errno?
			     (lambda (e)
			       (send print-text lock #f)
			       (send print-text
				     insert
				     "\n it's already disconneted, invalid input")
			       (send print-text lock #t)
			       (send (send t get-editor) erase))))
	      (write-string send-irc-msg write-port)
	      (flush-output write-port)
	      (send print-text lock #f)
	      (send print-text
		    insert
		    display-out-msg)
	      (send print-text lock #t)
	      (send (send t get-editor) erase)))
	  '()))))

;;;添加输入框，检测到回车就发送字符串到socket
(new text-field%
	      (parent irchat)
	      (label #f)
	      (min-height 25)
	      (callback
	       (lambda (t e)
		 (read-from-kbd-send-to-server t e))))

;;;GUI编程时，如果有循环，貌似就只能把循环放到另一个线程里来解决了，因为GUI本身就是个循环,然后再有个函数循环就只能把函数循环放到另一个线程这样才能同时运行
;;;用多线程把这个循环读取socket的procedure放到另一个线程里，不阻塞当前线程
(define read-from-server-thread
  (thread (lambda ()
	    (read-from-server read-port write-port print-text "irchat, 2016-04-13\n"))))

(send irchat show #t)

