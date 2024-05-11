#!/bin/bash
#
# 1. Create a file like:
# ~/.aws/credentials
#[email]
#aws_access_key_id=
#aws_secret_access_key=
#
#
# 2. Need to verify email address in AWS console *for that particular region*
#
EMAIL=$ADMIN_EMAIL
REGION=us-east-1
SUBJECT=$1
BODY=$2

aws --profile email ses send-email --from $EMAIL --to $EMAIL --region $REGION --text "$BODY" --subject "$SUBJECT" >>$HOME/.ses.log
