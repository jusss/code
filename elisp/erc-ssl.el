;set erc
(require 'erc)
(require 'tls)
(global-set-key (kbd "C-.")
(lambda ()
" server 195.148.124.79 ,variable cannot write this type"
(interactive)
(erc-ssl :server "irc.freenode.net" :port 6697 :nick "jusss" :full-name "xxxxxxx" :password "xxx")
(setq erc-autojoin-channels-alist '(("freenode.net" "#scheme" "#lisp" "#emacs"
"#ubuntu-cn")))
(setq erc-autojoin-timing 'ident)))
