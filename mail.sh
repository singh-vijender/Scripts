#!/bin/bash
#This is a test mail
TO=vijender.saggu@outlook.com

/usr/sbin/sendmail -i -v -Am -- $TO <<END
Subject: Testing gmail relay
To: $TO

Testing gmail relay

END
