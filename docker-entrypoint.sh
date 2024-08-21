#!/bin/sh
set -e

DOCKER_USER='dockeruser'
DOCKER_GROUP='dockergroup'

if ! id "$DOCKER_USER" >/dev/null 2>&1; then
    echo "First start of the docker container, start initialization process."

    USER_ID=${PUID:-9001}
    GROUP_ID=${PGID:-9001}
    echo "Starting with $USER_ID:$GROUP_ID (UID:GID)"

    # Check if the desired GROUP_ID is already in use
    if getent group $GROUP_ID >/dev/null 2>&1; then
        EXISTING_GROUP=$(getent group $GROUP_ID | cut -d: -f1)
        echo "GID $GROUP_ID is already in use by group $EXISTING_GROUP. Using this group."
    else
        addgroup --gid $GROUP_ID $DOCKER_GROUP
        echo "Created group $DOCKER_GROUP with GID $GROUP_ID."
    fi

    # Create user with the specified UID and existing or new group
    adduser --shell /bin/sh --uid $USER_ID --ingroup $DOCKER_GROUP --disabled-password --gecos "" $DOCKER_USER

    # Set ownership and permissions
    chown -vR $USER_ID:$GROUP_ID /opt/minecraft
    chmod -vR ug+rwx /opt/minecraft

    if [ "$SKIP_PERM_CHECK" != "true" ]; then
        chown -vR $USER_ID:$GROUP_ID /data
    fi
fi

export HOME=/home/$DOCKER_USER
exec gosu $DOCKER_USER:$DOCKER_GROUP java -jar -Xms$MEMORYSIZE -Xmx$MEMORYSIZE $JAVAFLAGS /opt/minecraft/paperspigot.jar $PAPERMC_FLAGS nogui