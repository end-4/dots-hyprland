# This script is meant to be sourced.
# It's not for directly running.

user_data="${REPO_ROOT}/sdata/dist-fedora/user_data.yaml"
yq eval '.dnf.transaction_ids // [] | reverse[]' "$user_data" | while read -r tx_id; do
    echo -e "\n========================================"
    echo "Rolling back DNF Transactions ID: $tx_id"
    echo "========================================"
    dnf history info "$tx_id"
    echo -e "\nProceed to undo this transaction? "
    v sudo dnf history undo -y "$tx_id" </dev/tty
done