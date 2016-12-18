#!/usr/bin/env python3
import os, subprocess, time, sys
### use offlineimap download mail, and store as maildir type not mbox
### check $MAIL/INBOX/new/, if it's empty directory then it means no new mail
### */30 * * * * ~/lab/check-for-new-mail.py    write this into crontab with crontab -e
### another way to check new mail, is thought imaple idle or compare uid or recent message
mail_stored_path = "/home/jusss/Mail/qq/INBOX/new/"
notifier_path = "/home/jusss/lab/notifier.py"
a_list = os.listdir(mail_stored_path)
if a_list == []:
    sys.exit()
else:
    subprocess.Popen([notifier_path, "Mail", "New Mail"], shell=False)
    ### prevent this script is too fast to end that make Popen have not done yet
    time.sleep(3)

    


