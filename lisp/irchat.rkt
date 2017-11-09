#!/usr/bin/env racket
#lang racket

;;; tab 缩进 键盘事件, 多个channel 多个buffer 窗口, 高亮， 通知, quit时的eof 超时的eof 检测eof

;;;检测窗口是否最小化来决定是否开启通知窗口，或添加一按钮来控制，或检测当前窗口看有没有irc-client来控制
;;;用editor-canvas%来显示接受的信息，用text-field%来接受键盘输入的信息
;;;editor-canvas%的style选项里有no-focus拒绝接受键盘输入，不要使用(send print-receive-msg lock #t)这种形式阻止在显示区域的键盘输入
;;;而text-field%里是没有no-focus这种拒绝接受键盘输入的选项，所以用editor-canvas%取代text-field%显示信息
;;;信息显示总是会被鼠标光标干扰，在光标处显示，用insert加指定offset解决,计算每个接受的字符串大小，然后相加偏移显示后面的字符串
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
(define nick "thenwhat")
(define password "xxx")
(define channel "#linuxba")
(define-values (read-port write-port) (values 0 0))

;;;use exception to catch connecting failed
(with-handlers ((exn:fail:network?
		 (lambda (e)
		   (system "/home/john/lab2/notifier.rkt \" Fail to Connect Freenode, Restart after 3 minutes\" &")
		   ;;;if network is down, wait for 3 minutes then restart
		  (sleep 180)
		  (system "/home/john/lab2/irchat.rkt &")
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

(define print-receive-msg (new text% [auto-wrap #t]))   ;;; display one long line as multiple lines
(define editor-canvas (new editor-canvas% [parent irchat]
     		      [editor print-receive-msg]
		      [style '(auto-vscroll no-hscroll no-focus)]))  ;;;there is vertical bar, because of auto-wrap, no horizen bar, do not accept what keyboard input

(send print-receive-msg insert "welcome to irchat! ")
;;;(send print-receive-msg set-clickback 1 1 (lambda () 1) #f)
;;;(send irchat set-cursor #f)
;;;(send editor-canvas force-display-focus #f)
;;;(define mouse-event (new mouse-event% [event-type 'motion]))
;;;(send editor-canvas on-event mouse-event)
(define display-position 19)
(define display-string "")


(define read-from-server
  (lambda (read-port write-port got-string)
    ;;; if got-string is #f or eof then restart, it means reading timeout or server send disconnecting signal to client
    ;;; client send an exit signal to server, and server send eof to client
    ;;; another case, server send eof to client when client don't send exit signal, so don't detect eof as client's quit, detect the input keys of "/quit"
    (if (or (not got-string) (eof-object? got-string))
	(begin
	  (system "/home/john/lab2/irchat.rkt &")
	  (system "/home/john/lab2/notifier.rkt \" Disconnect from Freenode, Restart\" &")
	  (exit))
	(begin 
	  ;;; it has three type messages, PING, PRIVMSG, others
	  (if (find-string "PING :" (n-to-m-string got-string 1 6))
	      (begin
		(write-string (merge-string "PONG :" (rest-string "PING :" got-string)) write-port)
		(flush-output write-port))
		  
	      (if (find-string (merge-strings `(" PRIVMSG " ,channel " :")) got-string)
		   ;;; import bugs, merge-strings's parameter is a list, but I misunderstand and write it as functions parameter, `(a b) into `(a return b)
		  (begin
		    (set! display-string (merge-string (merge-string (merge-string "<"
										   (rest-string ":"
												(front-string "!~" got-string))) "> ")
						       (rest-string " PRIVMSG #linuxba :" got-string)))
		    (send print-receive-msg insert display-string display-position 'same #t)
		    (set! display-position (+ display-position (string-length display-string))))
               	      ;;;把others信息发送到显示区域
		  (begin 
		    (send print-receive-msg insert got-string display-position 'same #t)
		    (set! display-position (+ display-position (string-length got-string))))))))

              ;;;use sync/timeout to instead of multi-thread for reading timeout
    (read-from-server read-port
		      write-port
		      (sync/timeout 200
				    (read-line-evt read-port)))))


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
			       (send print-receive-msg
				     insert
				     "\n it's already disconneted, invalid input" display-position)
			       (set! display-position (+ display-position 42))
			       (send (send t get-editor) erase))))
	      (write-string send-irc-msg write-port)
	      (flush-output write-port)
	      (send print-receive-msg
		    insert
		    display-out-msg display-position 'same #t)
	      (set! display-position (+ display-position (string-length display-out-msg)))
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
	    (read-from-server read-port write-port "irchat, 2016-04-13\n"))))

(send irchat show #t)
