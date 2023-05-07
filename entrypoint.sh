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

# Function to recursively delete files and folders
function delete_recursive() {
    local path="$1"

    # List of files and folders
    printf "%s\n" "ls -1 $path" > $TEMP_SFTP_FILE
    ITEMS=$(SSHPASS=$SSHPASS sshpass -e sftp -oBatchMode=no -b $TEMP_SFTP_FILE -P $PORT -o StrictHostKeyChecking=no $USER@$HOST)

    # Deleting files and processing folders
    for item in $ITEMS; do
        if [[ "${item}" != */ && "${item}" != .* ]]; then
            printf "%s\n" "rm $path/$item" >> $TEMP_SFTP_FILE
        elif [[ "${item}" == */ ]]; then
            delete_recursive "$path/$item"
            printf "%s\n" "rmdir $path/$item" >> $TEMP_SFTP_FILE
        fi
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

    #delete_recursive "$REMOTE_PATH"

    # Execution of sftp commands stored in the temporary file
    #SSHPASS=$SSHPASS sshpass -e sftp -oBatchMode=no -b $TEMP_SFTP_FILE -P $PORT -o StrictHostKeyChecking=no $USER@$HOST

    #sshpass -p ${10} ssh -o StrictHostKeyChecking=no -p $3 $1@$2 rm -rf $REMOTE_PATH
    #rm $TEMP_SFTP_FILE

    #chmod +x /list_files.sh

    # Download the list_files.sh script on the remote server
    #printf "%s\n" "put /list_files.sh $REMOTE_PATH/list_files.sh" > $TEMP_SFTP_FILE
    #SSHPASS=$SSHPASS sshpass -e sftp -oBatchMode=no -b $TEMP_SFTP_FILE -P $PORT -o StrictHostKeyChecking=no $USER@$HOST

    # Run the list_files.sh script on the remote server and get the results
    #ITEMS=$(SSHPASS=$SSHPASS sshpass -e ssh -p $PORT -o StrictHostKeyChecking=no $USER@$HOST "sh $REMOTE_PATH/list_files.sh $REMOTE_PATH")

    #echo "Items to be deleted :"
    #echo "$ITEMS"

    # Deleting files and folders
    #for item in $ITEMS; do
    #    if [[ "$item" != "$REMOTE_PATH" ]]; then
    #        printf "%s\n" "rm $item" >> $TEMP_SFTP_FILE
    #    fi
    #done

    #for item in $ITEMS; do
    #    if [[ "$item" != "$REMOTE_PATH" ]]; then
    #        printf "%s\n" "rmdir $item" >> $TEMP_SFTP_FILE
    #    fi
    #done

    # Execution of sftp commands stored in the temporary file
    #SSHPASS=$SSHPASS sshpass -e sftp -oBatchMode=no -b $TEMP_SFTP_FILE -P $PORT -o StrictHostKeyChecking=no $USER@$HOST

    # Deleting the temporary file
    #rm $TEMP_SFTP_FILE

    # Create a temporary file to store lftp commands
    TEMP_LFTP_FILE=$(mktemp)

    # Commandes lftp pour supprimer les fichiers
    echo "open -u $USER,$PASSWORD -p $PORT sftp://$HOST" > $TEMP_LFTP_FILE
    echo "cd $REMOTE_PATH" >> $TEMP_LFTP_FILE
    echo "find . -type f -exec rm {} +" >> $TEMP_LFTP_FILE
    echo "find . -type d -not -path . -exec rmdir {} +" >> $TEMP_LFTP_FILE
    echo "bye" >> $TEMP_LFTP_FILE

    # Execution of lftp commands stored in the temporary file
    lftp -f $TEMP_LFTP_FILE

    # Deleting the temporary file
    rm $TEMP_LFTP_FILE
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
