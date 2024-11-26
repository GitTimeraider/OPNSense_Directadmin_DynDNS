#!/usr/local/bin/bash
# The domain for the account in DirectAdmin
DOMAINNAME=""

# The hostname for your A record
DNS_HOST="m"

# The URL to the DirectAdmin server we log in to
DA_URL=""

# The username and password for the account owning DOMAINNAME. Note that the
# password here should ideally be a Login Key that only has access to
# CMD_API_DNS_CONTROL and nothing else.
DA_USERNAME=""
DA_PASSWORD=""

# Configuration end
function validateIP() {
    local ip=${1}
    local validresult=1

    # First check against a simple regex
    if [[ ${ip} =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        # Then check each number
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

# Get the current IP address from DNS, and validate it.
CONFIGURED_IP="$(dig +short @ns1.mijn.host "${DNS_HOST}")"
if ! validateIP "${CONFIGURED_IP}"; then
    echo "Invalid configured IP: ${CONFIGURED_IP}. Aborting." >&2
    exit
fi

# Get current external IP address of this machine, and validate it.
CURRENT_IP="$(curl -s https://api.myip.com/ | jq -r .ip)"
if ! validateIP "${CURRENT_IP}"; then
    echo "Invalid active IP: ${CURRENT_IP}. Aborting." >&2
    exit
fi

# Check if the DNS A record needs to be updated
if [ "${CONFIGURED_IP}" != "${CURRENT_IP}" ]; then
    # Update the DNS A record and report.
    RESULT="$(curl -sS --insecure -u "${DA_USERNAME}:${DA_PASSWORD}" "${DA_URL}/CMD_API_DNS_CONTROL?action=edit&domain=${DOMAINNAME}&arecs0=name%3D${DNS_HOST}.%26value%3D${CONFIGURED_IP}&type=A&name=${DNS_HOST}.&value=${CURRENT_IP}&json=yes")"
    if [ "$(echo "${RESULT}" | jq -r .success)" == "Record Edited" ]; then
        echo "$(date +"%F %T") DNS record updated: ${DNS_HOST} -> ${CURRENT_IP}"
    else
        echo "$(date +"%F %T") DNS record update failed" >&2
        echo "${RESULT}" >&2
    fi
fi
sleep 20
# Second check if the DNS A record needs to be updated
if [ "${CONFIGURED_IP}" != "${CURRENT_IP}" ]; then
    # Update the DNS A record and report.
    RESULT="$(curl -sS --insecure -u "${DA_USERNAME}:${DA_PASSWORD}" "${DA_URL}/CMD_API_DNS_CONTROL?action=edit&domain=${DOMAINNAME}&arecs0=name%3D${DNS_HOST}.%26value%3D${CONFIGURED_IP}&type=A&name=${DNS_HOST}.&value=${CURRENT_IP}&json=yes")"
    if [ "$(echo "${RESULT}" | jq -r .success)" == "Record Edited" ]; then
        echo "$(date +"%F %T") DNS record updated: ${DNS_HOST} -> ${CURRENT_IP}"
    else
        echo "$(date +"%F %T") DNS record update failed" >&2
        echo "${RESULT}" >&2
    fi
fi
