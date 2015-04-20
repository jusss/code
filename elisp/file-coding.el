; set locale
(set-language-environment 'UTF-8)
; write file with utf-8
(set-buffer-file-coding-system 'utf-8)
(setq default-buffer-file-coding-system 'utf-8)
;terminal's coding with utf-8,eg M-x shell
(set-terminal-coding-system 'utf-8)
;keyboard input's coding
(set-keyboard-coding-system 'utf-8)
;file name's coding
(setq file-name-coding-system 'cp936)
;read file with utf-8
(prefer-coding-system 'utf-8)
;M-x describe-coding-system can view current coding
