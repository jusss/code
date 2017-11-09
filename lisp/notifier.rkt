#!/usr/bin/env racket
#lang racket/base

;;; $./notifier.rkt "hello" &

(require racket/gui)

(define cmd-line-parameter-list
  (vector->list (current-command-line-arguments)))

(define notify-window
  (new frame%
       (label "Notifier")
       (x 1136)
       (y 10)
       (width 300)
       (height 200)))

(define receive-string (new text% (auto-wrap #t)))
(define print-message
    (new editor-canvas% (parent notify-window) (style '(auto-vscroll auto-hscroll)) (editor receive-string)))

(define click-button
  (new button%
       (parent notify-window)
       (label "ok")
       ;;;callback捕捉按钮事件
       (callback
	(lambda (button event)
	  (send notify-window show #f)))))

(define send-message
  (lambda (editor message)
    (send editor
	  insert
	  message)
    (send notify-window show #t)))

(send-message receive-string (car cmd-line-parameter-list))


