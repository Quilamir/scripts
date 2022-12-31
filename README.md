# serviceRestarter
run with 4 possible parameters:

./serviceRestarter.sh 5 service.service "telegram apitoken" "telegram chat id"

the first 2 parameters are required

first parameter is the repeat threshold, if the line in the code repeats more that that the service name in the second parameter will be restarted automatically and a message will be sent to the telegram chat if provided.

