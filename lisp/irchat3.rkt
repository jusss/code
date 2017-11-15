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
;;;进入一个频道后先/name得到nick列表，接收到join或leave quit信息就添加或移除nick在列表里，
;;;在输入框text-field%里打完nick按tab会触发定义的tab事件，回调函数，得到当前输入框的字符串，然后把最后几个连续的字符提取出来，和nick列表里元素匹配
;;;匹配上一个就把这个字符串替换，再拼接这个字符串之前的字符串，然后显示在text-field%输入框里，再按tab，就匹配第二个，依次类推，匹配不到就什么也不执行
;;;(send e get-event-type) 只能得到'text-field或者'text-field-enter,这是control-event 并不能得到tab-key-event,如何在text-field%里检测tab键?
;;;在text-field%里每一次按键都会执行依次callback函数,通过get-value匹配tab字符来自动补全,但是在text-field%里按tab键竟然无输入？？？
;;;get-evevt-type only return 'text-field or 'text-field-enter in text-field%
;;;names #channel,返回的信息以353开始，366结尾, 因为现在是单窗口，所以执行/join之后自动清空nick列表然后得到当前频道的nick列表,还有设置channel为当前频道以便发送接收信息，但会接收上一个频道的信息但却不显示
;;; like this "john: joe: " or "hello, john: " multi-nicks auto complete, use space split, so when you press tab check the space if it's multi-nicks or not

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
(define channel "")
(define current-channel-nick-list '())
(define-values (read-port write-port) (values 0 0))

(define (delete atm lis)
 (cond
  ((null? lis) lis)
  ((eq? atm (car lis)) (delete atm (cdr lis)))
  ((list? (car lis)) (cons (delete atm (car lis)) (delete atm (cdr lis))))
  (else (cons (car lis) (delete atm (cdr lis))))))

(define-syntax pop (syntax-rules () ((pop atom alist) (set! alist (delete atom alist)))))
(define-syntax push (syntax-rules () ((push atom alist) (set! alist (cons atom alist)))))

;;;use exception to catch connecting failed
(with-handlers ((exn:fail:network?
		 (lambda (e)
		   (system "/home/john/lab2/notifier.rkt \" Fail to Connect Freenode, Restart after 3 minutes\" &")
		   ;;;if network is down, wait for 3 minutes then restart
		  (sleep 30)
		  (system "/bin/racket /home/john/lab2/irchat3.rkt &")
		  (exit))))
  
  (set!-values (read-port write-port)
	       ;;; freenode's 6697 and 7000 etc are not same protocol, sslv3 or tls stuff, so use 'auto
	       (ssl-connect server-address server-port))
  (write-string (merge-strings `("nick " ,nick  " \r\n"))
		write-port)
  (write-string (merge-strings `("user " ,nick " 8 * :" ,nick " \r\n"))
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

(define display-position 19)
(define display-string "")

(define read-from-server
  (lambda (read-port write-port got-string)
    ;;; if got-string is #f or eof then restart, it means reading timeout or server send disconnecting signal to client
    ;;; client send an exit signal to server, and server send eof to client
    ;;; another case, server send eof to client when client don't send exit signal, so don't detect eof as client's quit, detect the input keys of "/quit"
    (if (or (not got-string) (eof-object? got-string))
	(begin
	  (system "/bin/racket /home/john/lab2/irchat3.rkt &")
	  (system "/home/john/lab2/notifier.rkt \" Disconnect from Freenode, Restart\" &")
	  (exit))
	(begin 
	  ;;; it has three type messages, PING, PRIVMSG, others
	  (if (find-string " 353 " got-string)
	      (set! current-channel-nick-list (merge-list (split-string got-string " ") current-channel-nick-list))
	      '())
	  (if (find-string " JOIN #" got-string)
	      (push (rest-string ":" (front-string "!" got-string)) current-channel-nick-list)
	      '())
	  (if (find-string " QUIT :" got-string)
	      (pop (rest-string ":" (front-string "!" got-string)) current-channel-nick-list)
	      '())
	  (if (find-string " PART " got-string)
	      (pop (rest-string ":" (front-string "!" got-string)) current-channel-nick-list)
	      '())
	  (if (find-string "PING :" (n-to-m-string got-string 1 6))
	      (begin
		(write-string (merge-string "PONG :" (rest-string "PING :" got-string)) write-port)
		(flush-output write-port))
		  
	      (if (find-string (merge-strings `(" PRIVMSG " ,channel " :")) got-string)
		   ;;; import bugs, merge-strings's parameter is a list, but I misunderstand and write it as functions parameter, `(a b) into `(a return b)
		  (begin
		    (set! display-string (merge-string (merge-string (merge-string "<" (rest-string ":" (front-string "!" got-string))) "> ")
						       (rest-string (merge-string (merge-string " PRIVMSG " channel) " :") got-string)))
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

(define (compare-index-with-nick-list index-string nick-list)
  (if (empty? nick-list) #f
      (if (find-string index-string (n-to-m-string (car nick-list) 1 (string-length index-string)))
;      (if (find-string index-string (car nick-list))
	  (car nick-list)
	  (compare-index-with-nick-list index-string (cdr nick-list)))))

(define my-text-field%
  (class text-field%
    (inherit get-editor)
    (inherit get-value)
    (super-new)
    (define/override (on-subwindow-char receiver key-event)
      (cond [(and
              (eq? 'release (send key-event get-key-code))
              (equal? #\tab (send key-event get-key-release-code)))
             (displayln "TAB")
             (define ed (get-editor))
	     (define kbd-input (get-value))
	     (define compare-result #f)
	     (if (find-string " " kbd-input)
		 (begin 
		   (set! compare-result (compare-index-with-nick-list (car (reverse (split-string kbd-input " "))) current-channel-nick-list))
		   (if compare-result
		       (begin
			 (send ed begin-edit-sequence)
			 (send ed erase)
			 (send ed insert (merge-string (replace-string (car (reverse (split-string kbd-input " "))) compare-result kbd-input) ": "))
			 (send ed end-edit-sequence))
		       '()))
		 (begin 
		   (set! compare-result (compare-index-with-nick-list kbd-input current-channel-nick-list))
		   (if compare-result
		       (begin
			 (send ed begin-edit-sequence)
			 (send ed erase)
			 (send ed insert (merge-string compare-result ": "))
			 (send ed end-edit-sequence))
		       '())))]
            [else (super on-subwindow-char receiver key-event)]))))

(define read-from-kbd-send-to-server
  (let ((kbd-input "")
	(send-irc-msg "")
	(display-out-msg ""))
    (lambda (t e)
      (define t-editor (send t get-editor))
      (define event-type (send e get-event-type))
      (if (eq? event-type 'text-field-enter)
	  (begin
	    (set! kbd-input (send t get-value))
	    ;;; the input message have two type, commands and normal messages, command start with "/"
	    (if (find-string (n-to-m-string kbd-input 1 1)
			     "/")
		(begin
		 ;;; if the input keys is "/quit" kill the thread of read from server
		  (if (find-string "/quit" (n-to-m-string kbd-input 1 5))
		      (kill-thread read-from-server-thread)
		      '())
		  (if (find-string "/nick " (n-to-m-string kbd-input 1 6))
		      (set! nick (rest-string "/nick " kbd-input))
		      '())
		  (if (find-string "/join" (n-to-m-string kbd-input 1 5))
		      (begin 
			(set! channel (rest-string "/join " kbd-input))
			(set! current-channel-nick-list '()))
		      '())
		  (if (find-string "/part #" (n-to-m-string kbd-input 1 7))
		      (set! current-channel-nick-list '())
		      '())
		  (set! send-irc-msg (merge-string (rest-string "/" kbd-input) "\r\n"))
		  (set! display-out-msg (merge-string kbd-input "\n")))
		(begin 
		  (set! send-irc-msg (string-append (merge-strings `("PRIVMSG " ,channel " :")) kbd-input "\r\n"))
		  (set! display-out-msg (string-append (merge-strings `("<" ,nick "> ")) kbd-input "\n"))))
	    
    	    ;;; if you have already sent "/quit" then input something again, it will case an exception
	    (with-handlers ((exn:fail:network:errno?
			     (lambda (e)
			       (send print-receive-msg insert "\n disconneted, invalid input" display-position)
			       (set! display-position (+ display-position 42))
			       (send t-editor erase))))
			   (write-string send-irc-msg write-port)
			   (flush-output write-port)
			   (send print-receive-msg insert display-out-msg display-position 'same #t)
			   (set! display-position (+ display-position (string-length display-out-msg)))
			   (send t-editor erase)))
	  '()))))

; Create a frame
;(define frame (instantiate frame% ("Example")))
 
; Add a text field to the frame
(new my-text-field%
     [parent irchat]
     [label #f]
     [min-height 25]
     (callback (lambda (t e)
		 (read-from-kbd-send-to-server t e))))

;;;添加输入框，检测到回车就发送字符串到socket
;(new text-field%
;	      (parent irchat)
;	      (label #f)
;	      (min-height 25)
;	      (callback
;	       (lambda (t e)
;		 (read-from-kbd-send-to-server t e))))
;
;;;GUI编程时，如果有循环，貌似就只能把循环放到另一个线程里来解决了，因为GUI本身就是个循环,然后再有个函数循环就只能把函数循环放到另一个线程这样才能同时运行
;;;用多线程把这个循环读取socket的procedure放到另一个线程里，不阻塞当前线程
(define read-from-server-thread
  (thread (lambda ()
	    (read-from-server read-port write-port "irchat, 2016-04-13\n"))))

(send irchat show #t)
