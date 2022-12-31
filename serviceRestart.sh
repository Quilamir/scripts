#! /usr/bin/bash

repeat=1

regexBody="No block bodies to write in this log period block number"
regexHeader="No block headers to write in this log period block number"

currentBlock=""

searchStr="="
serviceName=$2

threshold=$1

logAfterLines=100
logAfterLinesCounter=0
# Set the API token and chat ID
API_TOKEN=$3
CHAT_ID=$4

# Set the message text
MESSAGE="Restarting $serviceName on block"

# check params
re='^[0-9]+$'
if ! [[ $1 =~ $re ]]
then
        echo "error: Threshold Not a number" >&2; exit 1
fi

if [[ -z "$serviceName" ]]
then
        echo "Service Name is required"
        exit 1
fi

if systemctl --all --type service | grep -q "$serviceName"
then
    echo "$serviceName exists."
else
    echo "$serviceName does NOT exist."
    exit 1
fi

if [[ -z "$API_TOKEN" || -z "$CHAT_ID" ]]
then
    echo "Telegram alerts will be skipped"
fi
echo "starting to monitor $serviceName"

# starting service log listener
journalctl -f -u $serviceName -o cat -n 0 |
while read line
do
    # ouputting some lines of the service log to see this script is alive
    ((logAfterLinesCounter++))
    if [[ $logAfterLinesCounter -gt $logAfterLines ]]
    then
        echo "$logAfterLines line: $line"
        logAfterLinesCounter=0
    fi

    # checking for the potential problem in the log
    if [[ "$line" == *"$regexBody"* ]] || [[ "$line" == *"$regexHeader"* ]]
    then
        # get the block number
        blockNumber=${line#*$searchStr}
        echo "grep triggered on block $blockNumber"

        # check if this is a repeat on this block number
        if [[ "$blockNumber" == "$currentBlock" ]]
        then
                echo "repeat $repeat of $threshold detected on block $blockNumber"
                ((repeat++))

                # if this repeats too many times we want to alert and restart the service
                if [[ $repeat -gt $threshold ]]
                then
                        echo "Restarting!!!"
                        # reseting variables
                        repeat=1

                        # restarting the service
                        sudo systemctl restart $serviceName

                        # alert using telegram if params were given
                        if [[ ! -z "$API_TOKEN" && ! -z "$CHAT_ID" ]]
                        then
                                echo "Sending telegram notification"
                                curl -s -X POST https://api.telegram.org/bot$API_TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$MESSAGE $blockNumber"
                        else
                                echo "Skipping telegram"
                        fi
                        echo "Service Restarted!!"
                fi
        else
                # first time for this block so we set new current block
                currentBlock=$blockNumber
                repeat=1
        fi
    fi
done
