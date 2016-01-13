(require racket/gui)
;;;创造一个窗口
(define frame (new frame% (label "Example")
		   (width 300)
		   (height 300)))
    
;;;显示这个窗口
(send frame show #t)
;;;关闭这个窗口
(send frame show #f)

;;;在这个窗口上显示信息
; Make a static text message in the frame
(define msg (new message% (parent frame)
		 (label "No events so far...")))

;;;制造个按钮在这个窗口上
; Make a button in the frame
(new button% (parent frame)
     ;;;如果要在面板是制造按钮就parent panel
             (label "Click Me")
	     ;Callback procedure for a button click:
	     ;;;点击按钮后执行显示新的信息
	     (callback (lambda (button event)
                         (send msg set-label "Button click"))))

 
;;;鼠标键盘事件处理
(define my-canvas%
  (class canvas% ; The base class is canvas%
    ; Define overriding method to handle mouse events
    (define/override (on-event event)
      (send msg set-label "Canvas mouse"))
    ; Define overriding method to handle keyboard events
    (define/override (on-char event)
      (send msg set-label "Canvas keyboard"))
    ; Call the superclass init, passing on all init args
    (super-new)))
 
; Make a canvas that handles events in the frame
(new my-canvas% (parent frame))

;;;在窗口上制造个水平面板
(define panel (new horizontal-panel% (parent frame)))

; 创建对话框
(define dialog (instantiate dialog% ("Example")))
 
;对话框上显示信息并创造个可输入框
(new text-field% [parent dialog] [label "Your name"])
 
; 在对话框上添加水平面板
(define panel (new horizontal-panel% [parent dialog]
                                     [alignment '(center center)]))
 
; 面板上添加2个按钮
(new button% [parent panel] [label "Cancel"])
(new button% [parent panel] [label "Ok"])
(when (system-position-ok-before-cancel?)
  (send panel change-children reverse))
 
; 显示对话框
(send dialog show #t)

;;;聊天时有2个框，一个显示框，一个输入框，输入框用text-field
(define field (new text-field% (label "input") (parent frame)))

;;;得到输入框输入的字符串
(send field get-value)

;;;得到text-field%的editor
(send field1 get-editor)

;;;擦除输入的字符串
(send (send field1 get-editor) erase)

;;;另一种得到输入框输入的字符串
(send (send field1 get-editor) get-text)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require racket/gui)
;;;创造一个frame
(define frame1
  (new frame%
       (label "frame")
       (width 300)
       (height 300)))

;;;frame上显示一些信息
(define msg1
  (new message%
       (parent frame1)
       (label "start")))

;;;frame上添加一个输入框
(define field1
  (new text-field%
       (parent frame1)
       (label "input:")))

;;;frame上添加一个按钮，按了按钮就会把输入框输入的信息显示出来
(new button%
     (parent frame1)
     (label "send")
     ;;;callback捕捉按钮事件
     (callback
      (lambda (button event)
	;;;把输入框的字符串发送给msg1显示
	(send msg1
	      set-label
	      ;;;得到输入框的字符串
	      (send field1 get-value))
	;;;擦除输入框的字符串
	(send (send field1 get-editor)
	      erase))))

;;;显示这个frame
(send frame1 show #t)

;;;<izwyt> asumu: if I use (callback (lambda (text-field event) (send msg
;;;	set-label (send a-text-field get-value)))) then I don't press enter
;;;	and the string echo
;;;<asumu> izwyt: you need to check the event type of the event and only take the
;;;	action when it's a 'text-field-enter event.  [00:01]
;;;<asumu> Because control events trigger for a variety of reasons.  [00:02]
;;;<asumu> So you want to check that it's the one you want.
;;;<asumu> See http://docs.racket-lang.org/gui/control-event_.html for the event
;;;	types
;;;<izwyt> asumu: I have a little confused about callback procedure  [00:03]
;;;<izwyt> asumu: waht's the two parameters of lambda in callback
;;;<asumu> The first is the text-field widget itself. That lets the callback
;;;	access the widget's data. The second is the event that triggered the
;;;	callback, which contains data about how it was triggered for example.
;;;<izwyt> asumu: and I try ...(callback (lambda (text-field text-field-enter)
;;;	(send msg set-label (send a-text-field get-value)))) and it still
;;;	doesn't wait for Enter key   [00:07]
;;;<izwyt> am I wrong ?
;;;<asumu> izwyt: as I said before, look into checking the event-type field of
;;;	the control event. Something like (when (eq? (send event
;;;	get-event-type) 'text-field-enter) (send msg ...)) instead of what you
;;;	have.  [00:56]
;;;<izwyt> asumu: what's event in (send event get-event-type) ?  [01:05]
;;;<asumu> izwyt: the callback argument  [01:09]

(define field1
  (new text-field%
       (parent frame1)
       (label "input:")
       (callback (lambda (t e)
		   ;;;t就是text-field自己, e就是field1的control-event
		  (if (eq? (send e get-event-type)
			   'text-field-enter)
		      (send msg1 set-label
			    (send field1 get-value))
		      '())))))

;;; (callback (lambda (a b) ...))  a代表对象自身 b代表对象的事件 是对象自己把值赋予a b 让你可以操作a b去操作对象，而不是需要你去赋值给a b来操作对象

(new text-field%
     (parent frame1)
     (label "input3:")
     (callback (lambda (t e)
		 (if (eq? (send e get-event-type)
			  'text-field-enter)
		     (begin (send msg1 set-label
				  (send t get-value))
			    (send (send t get-editor) erase))
		     '()))))



;;;message%的label只能显示少量的字，要显示更多的字用text-field%或canvas%
;;;但canvas%常常显示circles/squares/images not text

;;;<hyunh> hi there, how to get a event from a object ? like get control-event
;;;from text-field object ?
;;;<endobson> hyunh: I think you want to use the callback argument when calling
;;;new text-field%
;;;<hyunh> endobson: send texts to canvas'dc, and texts overwrite on canvas, how
;;;	to solve ?  [13:45]
;;;<endobson> hyunh: I'm not sure what you mean.  [13:46]
;;;<endobson> You are sending multiple texts and only seeing the most recent one,
;;;	   but you want to see all of them?  [13:47]
;;;<endobson> Or you are seeing all of them overlapping
;;;<hyunh> endobson: http://paste.ubuntu.com/14475659/
;;;<hyunh> endobson: input string into text-field, and display it  [13:48]
;;;<hyunh> endobson: I want to see all of them, not just recent one
;;;<endobson> I see all of them, but they are in the same spot  [13:49]
;;;<hyunh> so how to set the spot? 
;;;<endobson> try with a short bit of text, "a" and then with a large amount of
;;;	   text "AAAAAA"
;;;<endobson> that is what the two 0s that you are providing are
;;;<hyunh> like newline I mean  [13:50]
;;;<endobson> make the second 0 increase after every new bit of text
;;;<hyunh> endobson: set the spot in ?
;;;<hyunh> where to set the spot  [13:51]
;;;<endobson> You have (send (send canvas1 get-dc) draw-text (send t get-value) 0
;;;	   0)  [13:52]
;;;<hyunh> oh yes, I get it
;;;<endobson> change the second 0
;;;<hyunh> the 0 0
;;;<endobson> yep that means the upper left
;;;<hyunh> endobson: so I should set two global variable to do that ?  [13:53]
;;;<endobson> that will work
;;;<hyunh> one auto add 1, another auto add the length of letters
;;;<hyunh> actually, just one will be ok  [13:54]
;;;<hyunh> auto add 1
;;;<endobson> You may need to figure out the exact numbers, I think 1 will be too
;;;	   small
;;;<endobson> I'm not sure what you are trying to do, but canvas% is usually for
;;;	   drawings like circles/squares/images not text  [13:55]
;;;<endobson> you may find things like text-field with the multiple line style
;;;	   option easier to use  [13:56]
;;;<hyunh> endobson: use what to draw text ? or display text
;;;<vraid> from what i recall, the text render controls are quite basic, so if
;;;	you want to do anything advanced you have to implement it yourself
;;;<hyunh> endobson: message% ?
;;;<endobson> hyunh: I don't know what your end goal is, but if you want multiple
;;;	   lines of text I think you want a text-field%  [13:57]
;;;<hyunh> I'd like to write something into text-field% and display them   [13:58]
;;;<hyunh> and text-filed% can do display ?  [13:59]
;;;<endobson> Right so you have one text-field% where you write into, and another
;;;	   where you display
;;;<hyunh> and another text-field% to display ？  [14:00]
;;;<pasterack> endobson pasted: http://pasterack.org/pastes/85191  [14:02]
;;;<endobson> hyunh: Take a look at that
;;;<hyunh> endobson: yes, that's what I want  [14:08]
;;;<hyunh> endobson: but when I input lots of words, and it can't display any
;;;	more, does it need a scroll ? or there's another way
;;;<endobson> Yep you can add a scroll
;;;<endobson> it should have a scroll by default  [14:15]
;;;<hyunh> endobson: string-append them to dispaly, that's a common way ? like
;;;	chatroom msn or other chat program  [14:16]
;;;<endobson> can you try scrolling to the bottom after you have put in a lot of
;;;	   words
;;;<hyunh> endobson: there's no scroll 
;;;<endobson> hyunh: If that is what you are going for, I think you will want to
;;;	   do something different like a bunch of messages. But I think the
;;;	   text field is probably the simplest to start out with  [14:17]
;;;<endobson> hyunh: for me there is no scroll until I type a lot and then there
;;;	   is  [14:18]
;;;<endobson> The docs also say that that is the behavior
;;;<endobson> hyunh: you can also use "insert" instead of "set-value"  [14:19]
;;;<endobson> that would eliminate the need to do string-append
;;;<hyunh> endobson: ok I'll try "insert"  [14:22]
;;;<hyunh> "insert" is better than string-append I think  [14:31]
;;;<hyunh> but there's still no scroll  [14:32]
;;;<hyunh> endobson: how I can add a scrollbar into text-field ?  [14:37]
;;;<endobson> hyunh: It should just work, If it doesn't I would try posting to
;;;	   the mailing list: users@racket-lang.org  [14:38]
;;;<hyunh> endobson: does the scrollbar depend window manager ?  [14:39]
;;;<endobson> hyunh: I don't know the details
;;;<hyunh> endobson: I know why there's no scrollbar, because you use (enable #f)
;;;	in text-field
;;;<hyunh> and I wonder if you use (enable #f) and how you can get scrollbar

(require racket/gui)
;;;创造一个frame
(define frame1
  (new frame%
       (label "frame")
       (width 800)
       (height 600)))
(define canvas1
	   (new canvas%
		(parent frame1)))
(new text-field%
	      (parent frame1)
	      (label #f)
	      (callback (lambda (t e)
			  (if (eq? (send e get-event-type)
				   'text-field-enter)
			      (begin 
				(send (send canvas1 get-dc)
				      draw-text
				      (send t get-value)
				      0
				      0)
				(send (send t get-editor) erase))
			      '()))))
(send frame1 show #t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(new text-field%
	      (parent frame1)
	      (label #f)
	      (callback (lambda (t e)
			  (if (eq? (send e get-event-type)
				   'text-field-enter)
			      (begin 
				(send (send canvas1 get-dc)
				      draw-text
				      (send t get-value)
				      0
				      0)
				(send (send t get-editor) erase))
			      '()))))

(new text-field%
	      (parent frame1)
	      (label #f)
	      (callback (lambda (t e)
			  (if (eq? (send e get-event-type)
				   'text-field-enter)
			      (begin
                                (send text1 set-value (string-append (send text1 get-value) "\n" (send t get-value)))
				(send (send t get-editor) erase))
			      '()))))

;;;在text-field%里set-value不如在text%里insert

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


#lang racket
(require racket/gui)
;;;创造一个frame
(define frame1
  (new frame%
       (label "frame")
       (width 800)
       (height 600)))

;;;显示信息
(define text1
  (new text-field%
       (parent frame1)
       (label #f)
       (style '(multiple))
       ;;;(enabled #f) will get no scrollbar
       (enabled #t)))

;;;输入信息
(new text-field%
	      (parent frame1)
	      (label #f)
	      (min-height 25)
	      (callback (lambda (t e)
			  (if (eq? (send e get-event-type)
				   'text-field-enter)
			      (begin
                                (send (send text1 get-editor)
				      insert
				      (string-append
				       (send t get-value)
				       "\n"))
				(send (send t get-editor) erase))
			      '()))))

(send frame1 show #t)

