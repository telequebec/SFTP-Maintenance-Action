#!/bin/sh -l

#set -e at the top of your script will make the script exit with an error whenever an error occurs (and is not explicitly handled)
set -eu

TEMP_SSH_PRIVATE_KEY_FILE='../private_key.pem'
TEMP_SFTP_FILE='../sftp'

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

# Function to recursively delete files and folders
function delete_recursive() {
    local path="$1"

    # List of files
    printf "%s\n" "ls -1 $path" > $TEMP_SFTP_FILE
    FILES=$(SSHPASS=$SSHPASS sshpass -e sftp -oBatchMode=no -b $TEMP_SFTP_FILE -P $PORT -o StrictHostKeyChecking=no $USER@$HOST)

    # Deleting files
    for file in $FILES; do
        printf "%s\n" "rm $path/$file" >> $TEMP_SFTP_FILE
    done

    # List of files
    printf "%s\n" "ls -1 -d $path/*/" >> $TEMP_SFTP_FILE
    DIRS=$(SSHPASS=$SSHPASS sshpass -e sftp -oBatchMode=no -b $TEMP_SFTP_FILE -P $PORT -o StrictHostKeyChecking=no $USER@$HOST)

    # Recursive deletion of folder contents
    for dir in $DIRS; do
        delete_recursive "$dir"
    done

    # Deleting folders
    for dir in $DIRS; do
        printf "%s\n" "rmdir $path/$dir" >> $TEMP_SFTP_FILE
    done
}

# use password
if [ -z != ${10} ]; then
  echo 'use sshpass'
  apk add sshpass

  if test $9 == "true"; then
    echo 'Start delete remote files'

    # create a temporary file containing sftp commands
    #printf "%s" "rm $REMOTE_PATH/Algolia.Search.dll" >$TEMP_SFTP_FILE
    #-o StrictHostKeyChecking=no avoid Host key verification failed.
    #SSHPASS=${10} sshpass -e sftp -oBatchMode=no -b $TEMP_SFTP_FILE -P $3 $8 -o StrictHostKeyChecking=no $1@$2

    delete_recursive "$REMOTE_PATH"
    sshpass -p ${10} ssh -o StrictHostKeyChecking=no -p $3 $1@$2 rm -rf $REMOTE_PATH
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
