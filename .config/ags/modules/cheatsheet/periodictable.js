import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import { periodicTable, series } from "./data_periodictable.js";
const { Box, Button, Icon, Label, Revealer } = Widget;

export default () => {
    const ElementTile = (element) => {
        return Box({
            vertical: true,
            className: `cheatsheet-periodictable-${element.type}`,
            children: element.name == '' ? null : [
                Box({
                    className: 'padding-8',
                    children: [
                        Label({
                            label: `${element.number}`,
                            className: "txt-tiny",
                        }),
                        Box({ hexpand: true }),
                        Label({
                            label: `${element.weight}`,
                            className: "txt-smaller",
                        })
                    ]
                }),
                element.icon ? Icon({
                    icon: element.icon,
                    className: "txt-hugerass txt-bold",
                }) : Label({
                    label: `${element.symbol}`,
                    className: "cheatsheet-periodictable-elementsymbol",
                }),
                Label({
                    label: `${element.name}`,
                    className: "txt-tiny",
                })
            ]
        })
    }
    const mainBoard = Box({
        hpack: 'center',
        vertical: true,
        className: "spacing-v-3",
        children: periodicTable.map((row, _) => Box({ // Rows
            className: "spacing-h-5",
            children: row.map((element, _) => ElementTile(element))
        })),
    });
    const seriesBoard = Box({
        hpack: 'center',
        vertical: true,
        className: "spacing-v-3",
        children: series.map((row, _) => Box({ // Rows
            className: "spacing-h-5",
            children: row.map((element, _) => ElementTile(element))
        })),
    });
    return Box({
        vertical: true,
        className: 'spacing-v-20',
        children: [
            mainBoard,
            seriesBoard
        ]
    })
}