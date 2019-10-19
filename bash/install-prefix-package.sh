for i in $(pacman -Ss haskell|grep 'community/haskell-'|grep -v 'installed'); do sudo pacman -S $i --noconfirm; done;
