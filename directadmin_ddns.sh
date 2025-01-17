#!/usr/local/bin/bash
# Domain name within DirectAdmin
DOMAIN="test.com"

# Names of the A records
declare -a DNS_NAME_ARRAY=("$*")
declare -a DNS_NAMES=("")
string="www."

# Adding main domain names
DNS_NAMES+=( "$string$DOMAIN" )
DNS_NAMES+=( "$DOMAIN" )


# Adding the subdomains and/or adding www. to the names
for sub in ${DNS_NAME_ARRAY[@]};
do
DNS_NAMES+=( "$string$sub.$DOMAIN" )
DNS_NAMES+=( "$sub.$DOMAIN" )
done


# The URL to the DirectAdmin server we log in to
DIRECTADMIN="https://host:2222"

# The username and password for the account within DirectAdmin (Login key is the safest option)
DIRECT_USER="user"
DIRECT_PW="password"

#Run
function validateIP() {
    local ip=${1}
    local validresult=1
    if [[ ${ip} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=${IFS}
        IFS='.'
        ip=(${ip})
        IFS=${OIFS}
        [[     ${ip[0]} -le 255 \
            && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 \
            && ${ip[3]} -le 255 ]]
        validresult=${?}
    fi
    return ${validresult}
}

# Retrieve and check current local IP
CURRENT_IP="$(curl -s https://api.myip.com/ | jq -r .ip)"
if ! validateIP "${CURRENT_IP}"; then
    echo "Invalid active IP: ${CURRENT_IP}. Aborting." >&2
    exit 1
fi

for DNS_NAME in ${DNS_NAMES[@]}; do
# Retrieve and check current DNS IP. Replace DNS with whatever DNS is used by your domainhosting
CONFIGURED_IP="$(dig +short @ns1.mijn.host "${DNS_NAME}")"
if ! validateIP "${CONFIGURED_IP}"; then
    echo "Invalid configured IP: ${CONFIGURED_IP}.
fi

# Check if the DNS records need to be updated
if [ "${CONFIGURED_IP}" != "${CURRENT_IP}" ]; then
    # Update the DNS records
    RESULT="$(curl -sS --insecure -u "${DIRECT_USER}:${DIRECT_PW}" "${DIRECTADMIN}/CMD_API_DNS_CONTROL?action=edit&domain=${DOMAIN}&arecs0=name%3D$DNS_NAME.%26value%3D${CONFIGURED_IP}&type=A&name=$DNS_NAME.&value=${CURRENT_IP}&json=yes")"
    if [ "$(echo "${RESULT}" | jq -r .success)" == "Record Edited" ]; then
        echo "$(date +"%F %T") DNS record updated: $DNS_NAME -> ${CURRENT_IP}"
    else
        echo "$(date +"%F %T") DNS record update failed" >&2
        echo "${RESULT}" >&2
    fi
fi
done
