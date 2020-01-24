# ArmorFirewallAPI
A script to allow you to mass update the Armor firewall automatically.

This first iteration has been tested to work with my API Keys and all the Datacenters my user has access to.

To use this script, you must have jq installed, which is available from both debian and RHEL repos. I have written this in Bash, so it is not currently useable on Windows, without the WSL also installed.

First, you must have access to the Armor Firewall, then you need to edit the script in the following places:
- Line 5: This will be the name of the IP group on the firewall
- Line 7: At the end, the account context, change from xxxx
- Line 17: Your own API ID
- Line 18: Your own API Secret 

The 2 files included are the script, and an example IP address file.
The script reads the file into the firewall group, and prints out the response from Armor's API

You can place the IP addresses in the file out.json, one IP address(range/subnet) per line.

TODO:  
Add a piece of the script that will test to see if there is a block rule in place, and add it to rule 1 if its not.  
Add a validator for comments.  
Add a validator for mal-formed IP addresses.  
Add a separator for different deliniators on out.json to future-proof, or to allow for pre-existing json files.  
