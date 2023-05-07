# Container image that runs your code
FROM alpine:3.13

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh
COPY list_files.sh /list_files.sh

#Make sure to make you entrypoint.sh file executable:
RUN chmod 777 entrypoint.sh
RUN chmod 777 list_files.sh

RUN apk update
RUN apk add --no-cache openssh


# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
