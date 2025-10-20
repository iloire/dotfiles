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

if [ -z "$EMAIL" ]; then
	echo "ERROR: ADMIN_EMAIL env variable not defined" >&2
	exit 1
fi

# Detect OS and set AWS CLI path
if [[ "$OSTYPE" == "darwin"* ]]; then
	# macOS (Homebrew)
	AWS_CMD="/opt/homebrew/bin/aws"
else
	# Linux
	AWS_CMD="/usr/local/bin/aws"
fi

# Verify command exists
if [ ! -x "$AWS_CMD" ]; then
	echo "ERROR: aws command not found or not executable: $AWS_CMD" >&2
	exit 1
fi

$AWS_CMD --profile email ses send-email --from $EMAIL --to $EMAIL --region $REGION --text "$BODY" --subject "$SUBJECT" >>$HOME/.ses.log
