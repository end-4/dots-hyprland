pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

import qs.modules.common

/**
 * External IP service to fetch and display public IP address.
 */
Singleton {
    id: root
    
    // Fetch interval in milliseconds (default: 5 minutes)
    readonly property int fetchInterval: (Config.options.bar.externalIp.fetchInterval || 5) * 60 * 1000
    
    // The current external IP address
    property string ip: ""
    
    // Loading state
    property bool loading: false
    
    function getData() {
        root.loading = true;
        // Using ipinfo.io/ip which returns just the IP address
        // --fail makes curl return error code on HTTP errors
        // --silent suppresses progress output, --show-error shows errors
        fetcher.command[2] = "curl -sSf --max-time 5 ipinfo.io/ip";
        fetcher.running = true;
    }
    
    Component.onCompleted: {
        console.info("[ExternalIpService] Starting external IP service.");
        root.getData();
    }
    
    Process {
        id: fetcher
        command: ["bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                if (text.length === 0) {
                    console.error("[ExternalIpService] Failed to fetch IP - empty response");
                    return;
                }
                try {
                    // Trim whitespace and newlines
                    const fetchedIp = text.trim();
                    // Basic validation - check if it looks like an IP address
                    // We trust ipinfo.io to return valid IPs, just do basic sanity check
                    const ipv4Pattern = /^(\d{1,3}\.){3}\d{1,3}$/;
                    const ipv6Pattern = /^[0-9a-f:]+$/i;
                    
                    if (ipv4Pattern.test(fetchedIp)) {
                        // For IPv4, validate octets are in range 0-255
                        const octets = fetchedIp.split('.');
                        if (octets.every(octet => parseInt(octet) <= 255)) {
                            root.ip = fetchedIp;
                            console.info(`[ExternalIpService] Fetched IPv4: ${fetchedIp}`);
                        } else {
                            console.error(`[ExternalIpService] Invalid IPv4 - octet out of range: ${fetchedIp}`);
                        }
                    } else if (ipv6Pattern.test(fetchedIp) && fetchedIp.includes(':')) {
                        // For IPv6, basic check that it contains colons and valid characters
                        // We trust the API to return valid IPv6, just ensure it's not garbage
                        root.ip = fetchedIp;
                        console.info(`[ExternalIpService] Fetched IPv6: ${fetchedIp}`);
                    } else {
                        console.error(`[ExternalIpService] Invalid IP format: ${fetchedIp}`);
                    }
                } catch (e) {
                    console.error(`[ExternalIpService] ${e.message}`);
                }
            }
        }
        stderr: SplitParser {
            onRead: line => {
                console.error(`[ExternalIpService] ${line}`);
            }
        }
        onExited: (exitCode, exitStatus) => {
            root.loading = false;
            if (exitCode !== 0) {
                console.error(`[ExternalIpService] Process exited with code ${exitCode}, status: ${exitStatus}`);
            }
        }
    }
    
    Timer {
        running: true
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: false // We already fetch on component completed
        onTriggered: root.getData()
    }
}
