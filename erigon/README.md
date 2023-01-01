# Erigon Scripts
## serviceRestart.sh
### Use at your own risk!
At the time of this commit Erigon suffers from issues when downloading headers and block bodies, sometimes it gets stuck on an "empty" block causing the server to stop syncing.

This script listens to the erigon service logs and detects if such a block is causing the server to hang, and then restarts the erigon service which usually allows the server to sync correctly.

To use this script simply clone the repo and then install the attached service unit file erigonRestarter.service
Make sure to update the execPath and the cli parameters in the service file before you run it.

The first parameter is the repeat threshold - required integer
The second parameter is the service name to monitor - required string
The third parameter is the telegram token - optional string
The fourth parameter is the telegram chat id - optional string

```
sudo cp erigonRestarter.service /etc/systemd/system
sudo systemctl daemon-reload
sudo systemctl enable erigonRestarter.service
sudo systemctl start erigonRestarter.service
```

I do not think this is the best solution to the current problem however this is better than manually restarting the service when the problem happens.
