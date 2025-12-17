function scaleWindow(hyprlandClient, maxWindowWidth, maxWindowHeight) {
    const [width, height] = hyprlandClient.size;
    const [xScale, yScale] = [maxWindowWidth / width, maxWindowHeight / height];
    const scale = Math.min(xScale, yScale);
    return Qt.size(width * scale, height * scale)
}

function arrangedClients(hyprlandClients, maxRowWidth, maxWindowWidth, maxWindowHeight) {
    const count = hyprlandClients.length;
    const resultLayout = [];

    var i = 0;
    while (i < count) {
        var row = [];
        var rowWidth = 0;
        var j = i;

        while (j < count) {
            const client = hyprlandClients[j];
            const scaledSize = scaleWindow(client, maxWindowWidth, maxWindowHeight);

            if (rowWidth + scaledSize.width <= maxRowWidth || row.length === 0) {
                row.push(client);
                rowWidth += scaledSize.width;
                j++;
            } else {
                break;
            }
        }
        
        resultLayout.push(row);
        i = j;
    }

    return resultLayout;
}
