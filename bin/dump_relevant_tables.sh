#!/bin/zsh

# First, establish the relevant SSH tunnel via something like:

# ssh -L3307:internal.database.host:3306 -C external.ssh.server

# Then run:

mysqldump --add-drop-table --skip-lock-tables -h 127.0.0.1 -P 3307 -u chill_ro -p chill_prod\
  tNotice tNoticePriv tCat tNotImage tNews rQueNot tQuestion rSubmit\
  | mysql -u chill_user -pchill_pass chill_prod

# Fixing relevant parts of the mysql connection above.
