pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

import qs.modules.common

Singleton {
    id: root
    
    // 5 minutes
    readonly property int fetchInterval: Config.options.bar.crypto.refreshRate * 60 * 1000
    readonly property list<string> coins: Config.options.bar.crypto.coins
    readonly property bool monochromeIcon: Config.options.bar.crypto.monochromeIcon
    readonly property string currency: "usd"

    property ListModel coinModel: ListModel {}

    onCoinsChanged: {
        root.getData()
    }

    function getData() {
        if (root.coins.length === 0) {
            coinModel.clear();
            return;
        }
        
        // Fetch markets data for list of IDs
        let ids = root.coins.join(",");
        let command = `curl -s "https://api.coingecko.com/api/v3/coins/markets?vs_currency=${root.currency}&ids=${ids}&order=market_cap_desc&sparkline=false&locale=en"`
        
        fetcher.command = ["bash", "-c", command]
        fetcher.running = true
    }

    Component.onCompleted: {
        root.getData();
    }

    Process {
        id: fetcher
        command: ["bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0)
                    return;
                try {
                    let data = JSON.parse(text.trim());
                    
                    if (!Array.isArray(data)) {
                         console.error(`[CryptoService] Expected array, got: ${text}`);
                         return;
                    }

                    // Create a map for fast lookup
                    let dataMap = {};
                    data.forEach(coin => { dataMap[coin.id] = coin; });

                    coinModel.clear();
                    
                    // Iterate over configured coins to maintain order
                    for (let i = 0; i < root.coins.length; ++i) {
                        let coinId = root.coins[i];
                        let coinData = dataMap[coinId];
                        
                        if (coinData) {
                            coinModel.append({
                                "coinId": coinData.id,
                                "symbol": coinData.symbol.toUpperCase(),
                                "price": "$" + coinData.current_price.toLocaleString(),
                                "imageUrl": coinData.image
                            });
                        } else {
                            // Placeholder for loading or invalid ID
                            coinModel.append({
                                "coinId": coinId,
                                "symbol": "...",
                                "price": "...",
                                "imageUrl": ""
                            });
                        }
                    }
                    
                } catch (e) {
                    console.error(`[CryptoService] Error parsing JSON: ${e.message} in output: ${text}`);
                }
            }
        }
    }

    Timer {
        running: Config.options.bar.crypto.enable
        repeat: true
        interval: root.fetchInterval
        onTriggered: root.getData()
    }
}
