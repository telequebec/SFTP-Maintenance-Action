#!/bin/sh -l

#set -e at the top of your script will make the script exit with an error whenever an error occurs (and is not explicitly handled)
set -eu

TEMP_SSH_PRIVATE_KEY_FILE='../private_key.pem'
TEMP_SFTP_FILE='../sftp'
# TEMP_SFTP_FILE=$(mktemp)

# make sure remote path is not empty
if [ -z "$6" ]; then
  echo 'remote_path is empty'
  exit 1
fi

USER=$1
HOST=$2
REMOTE_PATH=$(echo "$6" | sed 's/\/*$//g')
PORT=$3
SSHPASS=${10}
PASSWORD=${10}

# use password
if [ -z != $SSHPASS ]; then
  echo 'use sshpass'
  apk add sshpass

  if test $9 == "true"; then
    echo 'Start delete remote files'

    sshpass -p ${10} ssh -o StrictHostKeyChecking=no -p $3 $1@$2 rm -rf $REMOTE_PATH

    # Create a temporary file to store lftp commands
    # TEMP_LFTP_FILE=$(mktemp)

    # lftp commands to delete files
    # delete_recursively "$REMOTE_PATH"

    # Use lftp to delete files and folders in parallel
    # SSHPASS=$SSHPASS sshpass -e lftp -u $USER -p $PORT -e "set sftp:connect-program \"ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -a -x\"; cd \"$REMOTE_PATH\"; glob -d --parallel=10 -- rm -r *; bye" sftp://$HOST

    # create a temporary file containing sftp commands
    #printf "%s" "rm $REMOTE_PATH/App_Offline.htm" >$TEMP_SFTP_FILE
    #-o StrictHostKeyChecking=no avoid Host key verification failed.
    #SSHPASS=${10} sshpass -e sftp -oBatchMode=no -b $TEMP_SFTP_FILE -P $3 $8 -o StrictHostKeyChecking=no $1@$2

    # Deleting the temporary file
    # rm $TEMP_LFTP_FILE
  fi
  if test $7 = "true"; then
    echo "Connection via sftp protocol only, skip the command to create a directory"
  else
    echo 'Create directory if needed'
    sshpass -p ${10} ssh -o StrictHostKeyChecking=no -p $3 $1@$2 mkdir -p $REMOTE_PATH
  fi

  echo 'SFTP Start'
  # create a temporary file containing sftp commands
  printf "%s" "put -r $5 $REMOTE_PATH" >$TEMP_SFTP_FILE
  #-o StrictHostKeyChecking=no avoid Host key verification failed.
  SSHPASS=${10} sshpass -e sftp -oBatchMode=no -b $TEMP_SFTP_FILE -P $3 $8 -o StrictHostKeyChecking=no $1@$2

  echo 'Deploy Success'

  exit 0
fi

# keep string format
printf "%s" "$4" >$TEMP_SSH_PRIVATE_KEY_FILE
# avoid Permissions too open
chmod 600 $TEMP_SSH_PRIVATE_KEY_FILE

# delete remote files if needed
if test $9 == "true"; then
  echo 'Start delete remote files'
  ssh -o StrictHostKeyChecking=no -p $3 -i $TEMP_SSH_PRIVATE_KEY_FILE $1@$2 rm -rf $REMOTE_PATH/*

  # create a temporary file containing sftp commands
  printf "%s" "rm -rf $REMOTE_PATH/*" >$TEMP_SFTP_FILE
  #-o StrictHostKeyChecking=no avoid Host key verification failed.
  sftp -b $TEMP_SFTP_FILE -P $3 $8 -o StrictHostKeyChecking=no -i $TEMP_SSH_PRIVATE_KEY_FILE $1@$2

  ssh -o StrictHostKeyChecking=no -p $3 -i $TEMP_SSH_PRIVATE_KEY_FILE $1@$2 rm -rf $REMOTE_PATH
fi

if test $7 = "true"; then
  echo "Connection via sftp protocol only, skip the command to create a directory"
else
  echo 'Create directory if needed'
  ssh -o StrictHostKeyChecking=no -p $3 -i $TEMP_SSH_PRIVATE_KEY_FILE $1@$2 mkdir -p $REMOTE_PATH
fi

echo 'SFTP Start'
# create a temporary file containing sftp commands
printf "%s" "put -r $5 $REMOTE_PATH" >$TEMP_SFTP_FILE
#-o StrictHostKeyChecking=no avoid Host key verification failed.
sftp -b $TEMP_SFTP_FILE -P $3 $8 -o StrictHostKeyChecking=no -i $TEMP_SSH_PRIVATE_KEY_FILE $1@$2

echo 'Deploy Success'
exit 0
