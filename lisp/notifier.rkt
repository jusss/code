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
       (width 220)
       (height 100)))

(define print-message
  (new text-field%
       (parent notify-window)
       (label #f)
       (style '(multiple))))
       

(define click-button
  (new button%
       (parent notify-window)
       (label "ok")
       ;;;callback捕捉按钮事件
       (callback
	(lambda (button event)
	  (send notify-window show #f)))))

(define send-message
  (lambda (message)
    (define print-message-editor
      (send print-message get-editor))
    (send print-message-editor
	  insert
	  message)
    (send print-message-editor lock #t)
    (send notify-window show #t)))

(send-message (car cmd-line-parameter-list))


