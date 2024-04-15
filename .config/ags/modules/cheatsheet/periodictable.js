import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import { periodicTable, series } from "./data_periodictable.js";
const { Box, Button, Label, Revealer } = Widget;

export default () => {
    const ElementTile = (element) => {
        return Box({
            vertical: true,
            className: (element.name == '' ? 'cheatsheet-periodictable-empty' : 'cheatsheet-periodictable-element'),
            children: element.name == '' ? null : [
                Box({
                    className: 'padding-8',
                    children: [
                        Label({
                            label: `${element.number}`,
                            className: "txt txt-tiny",
                        }),
                        Box({ hexpand: true }),
                        Label({
                            label: `${element.weight}`,
                            className: "txt txt-smaller",
                        })
                    ]
                }),
                Label({
                    label: `${element.symbol}`,
                    className: "txt txt-large txt-bold",
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