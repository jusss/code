(require `ido)
(ido-mode t)
;set c-, bind (ido-switch-buffer) , same as c-x b
(global-set-key (kbd "C-,") 'ido-switch-buffer)
