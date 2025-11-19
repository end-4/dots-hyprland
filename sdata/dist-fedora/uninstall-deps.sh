# This script is meant to be sourced.
# It's not for directly running.

user_config="${REPO_ROOT}/sdata/dist-fedora/user-config.yaml"
yq -r '.dnf.transaction_ids[]? | reverse' "$user_config" | while read -r tx_id; do
    echo -e "\n========================================"
    echo "Rolling back DNF Transactions ID：$tx_id"
    echo "========================================"
    v sudo dnf history undo -y "$tx_id"
done