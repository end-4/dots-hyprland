import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import { niceTypes, periodicTable, series } from "./data_periodictable.js";
const { Box, Button, Icon, Label, Revealer } = Widget;

export default () => {
    const ElementTile = (element) => {
        return Box({
            vertical: true,
            tooltipText: element.electronConfig ? `${element.electronConfig}` : null,
            className: `cheatsheet-periodictable-${element.type}`,
            children: element.name == '' ? null : [
                Box({
                    className: 'padding-left-8 padding-right-8 padding-top-8',
                    children: [
                        Label({
                            label: `${element.number}`,
                            className: "cheatsheet-periodictable-elementnum txt-tiny txt-bold",
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
    const BoardColor = (type) => Box({
        className: 'spacing-h-5',
        children: [
            Box({
                homogeneous: true,
                className: `cheatsheet-periodictable-legend-color-wrapper`,
                children: [Box({
                    className: `cheatsheet-periodictable-legend-color-${type}`,
                })]
            }),
            Label({
                label: `${niceTypes[type]}`,
                className: "txt txt-small",
            })
        ]
    })
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
    const legend = Box({
        hpack: 'center',
        className: 'spacing-h-20',
        children: [
            BoardColor('metal'),
            BoardColor('nonmetal'),
            BoardColor('noblegas'),
            BoardColor('lanthanum'),
            BoardColor('actinium'),
        ]
    })
    return Box({
        vertical: true,
        className: 'spacing-v-20',
        children: [
            mainBoard,
            seriesBoard,
            legend
        ]
    })
}