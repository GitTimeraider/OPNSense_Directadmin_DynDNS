# Directadmin_DynDNS

Dynamic DNS setup for OPNSense - Allows for setting up Dynamic DNS based on Direct Admin API within OPNSense Cron UI
<br />
!!! This simple script is mostly combined together for myself and thus might not be fully suited for others. It lacks features and might have additions that are undesired for some. The script ofcourse can be adjusted accordingly with a little bit of Bash knowledge.
<br /><br />
actions_daddns.conf is to be placed in /usr/local/opnsense/service/conf/actions.d
<br />
directadmin_ddns.sh can be placed anywhere as long as the location in changed within actions_daddns.conf
<br />
<br />
actions_daddns.conf determines how it all visually looks within OPNSense -> System -> Settings -> Cron. 
<br />
Message, description and scriptlocation can be adjusted. Parameters might also need to be adjusted as it requires the amount of "%s"s to be higher than the amount of subdomains you will enter
<br />
<br />
directadmin_ddns.sh will need to be updated with: Domain name in DOMAIN, Direct admin portal url in DIRECTADMIN, username in DIRCT_USER and password in DIRECT_PW. It is also best to find the CONFIGURED_IP= rule and adjust the dns url located there to whatever your domainhoster uses for faster checks
<br />
The idea is that when you set up the cron job, the parameters box in the UI will be filled with the subdomains you want to have automatically updated ... for example:
<br />
Parameters: sub1 sub2 sub3
<br />
All it needs is only the subdomain names without the domain with spaces in between them
<br /><br />
What does the script do:
<br />
Checks current IP of the device based on an IP check
<br />
Checks IP of DNS names based on DNS server
<br /><br />
If difference is detected:
<br />
Takes the domain name and updates the domain name
<br />
Takes the subdomains noted in the parameters in the Cron UI and updates the subdomains
<br /><br />
