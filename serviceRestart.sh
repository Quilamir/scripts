#! /usr/bin/bash
colred='\033[0;31m' # Red
colgrn='\033[0;32m' # Green
colylw='\033[0;33m' # Yellow
colpur='\033[0;35m' # Purple
colrst='\033[0m'    # Text Reset

function llog() {
        datestring=`date +"%Y-%m-%d %H:%M:%S"`
        echo -e "$datestring - $@"
}

#initializing vars
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
        llog "${colred}[ERROR]${colrst} Threshold is required to be positive integer"
        exit 1
fi

if [[ -z "$serviceName" ]]
then
        llog "${colred}[ERROR]${colrst} Service Name is required"
        exit 1
fi

if systemctl --all --type service | grep -q "$serviceName"
then
    llog "${colgrn}[INFO]}${colrst} Service $serviceName found"
else
    llog "${colred}[ERROR]${colrst} Service $serviceName not found"
    exit 1
fi

if [[ -z "$API_TOKEN" || -z "$CHAT_ID" ]]
then
    llog "${colgrn}[INFO]}${colrst} Telegram alerts will be skipped"
fi
llog "${colgrn}[INFO]}${colrst} Monitoring $serviceName"

# starting service log listener
journalctl -f -u $serviceName -o cat -n 0 |
while read line
do
    # ouputting some lines of the service log to see this script is alive
    ((logAfterLinesCounter++))
    if [[ $logAfterLinesCounter -gt $logAfterLines ]]
    then
        llog "${colgrn}[INFO]}${colrst} $logAfterLines log lines processed ping"
        logAfterLinesCounter=0
    fi

    # checking for the potential problem in the log
    if [[ "$line" == *"$regexBody"* ]] || [[ "$line" == *"$regexHeader"* ]]
    then
        # get the block number
        blockNumber=${line#*$searchStr}
        llog "${colylw}[WARN]}${colrst} triggered on block $blockNumber"

        # check if this is a repeat on this block number
        if [[ "$blockNumber" == "$currentBlock" ]]
        then
                llog "${colylw}[WARN]}${colrst} Repeat $repeat of $threshold detected on block $blockNumber"
                ((repeat++))

                # if this repeats too many times we want to alert and restart the service
                if [[ $repeat -gt $threshold ]]
                then
                        llog "${colpur}[INFO]}${colrst} Restarting!!!"
                        # reseting variables
                        repeat=1

                        # restarting the service
                        sudo systemctl restart $serviceName

                        # alert using telegram if params were given
                        if [[ ! -z "$API_TOKEN" && ! -z "$CHAT_ID" ]]
                        then
                                llog "${colgrn}[INFO]}${colrst} Sending telegram notification"
                                curl -s -X POST https://api.telegram.org/bot$API_TOKEN/sendMessage -d chat_id=$CHAT_ID -d text="$MESSAGE $blockNumber"
                        else
                                llog "${colgrn}[INFO]}${colrst} Skipping telegram"
                        fi
                        llog "${colpur}[INFO]}${colrst} Service Restarted!!"
                fi
        else
                # first time for this block so we set new current block and reset repeat counter
                currentBlock=$blockNumber
                repeat=1
        fi
    fi
done
