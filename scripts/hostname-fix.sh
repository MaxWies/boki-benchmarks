#!/bin/bash

# allows to manipulate the /etc/hosts file

ETC_HOSTS=/etc/hosts
MAIN_HOSTNAME=$(hostname)
# DEFAULT IP FOR HOSTNAME
IP="127.0.0.1"

function removehost() {
    if [ -n "$(grep $HOSTNAME $ETC_HOSTS)" ]
    then
        echo "$HOSTNAME Found in your $ETC_HOSTS, Removing now...";
        sudo sed -i".bak" "/$HOSTNAME/d" $ETC_HOSTS
    else
        echo "$HOSTNAME was not found in your $ETC_HOSTS";
    fi
}

function addhost() {
    HOSTNAME=$(hostname)
    HOSTS_LINE="$IP\t$HOSTNAME"
    if [ -n "$(grep $HOSTNAME $ETC_HOSTS)" ]
        then
            echo "$HOSTNAME already exists : $(grep $HOSTNAME $ETC_HOSTS)"
        else
            echo "Adding $HOSTNAME to your $ETC_HOSTS";
            sudo -- sh -c -e "echo '$HOSTS_LINE' >> $ETC_HOSTS";

            if [ -n "$(grep $HOSTNAME $ETC_HOSTS)" ]
                then
                    echo "$HOSTNAME was added succesfully \n $(grep $HOSTNAME $ETC_HOSTS)";
                else
                    echo "Failed to Add $HOSTNAME, Try again!";
            fi
    fi
}

addhost