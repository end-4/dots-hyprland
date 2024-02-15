const { Gtk } = imports.gi;
import App from 'resource:///com/github/Aylur/ags/app.js';
import Variable from 'resource:///com/github/Aylur/ags/variable.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { execAsync, exec } = Utils;
const { Box, Button, Entry, EventBox, Icon, Label, Overlay, Scrollable } = Widget;
import SidebarModule from './module.js';
import { MaterialIcon } from '../../../lib/materialicon.js';
import { setupCursorHover } from '../../../lib/cursorhover.js';

const clamp = (num, min, max) => Math.min(Math.max(num, min), max);
function hslToRgbValues(h, s, l) {
    h /= 360;
    s /= 100;
    l /= 100;
    let r, g, b;
    if (s === 0) {
        r = g = b = l; // achromatic
    } else {
        const hue2rgb = (p, q, t) => {
            if (t < 0) t += 1;
            if (t > 1) t -= 1;
            if (t < 1 / 6) return p + (q - p) * 6 * t;
            if (t < 1 / 2) return q;
            if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
            return p;
        };
        const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        const p = 2 * l - q;
        r = hue2rgb(p, q, h + 1 / 3);
        g = hue2rgb(p, q, h);
        b = hue2rgb(p, q, h - 1 / 3);
    }
    const to255 = x => Math.round(x * 255);
    r = to255(r);
    g = to255(g);
    b = to255(b);
    return `${Math.round(r)},${Math.round(g)},${Math.round(b)}`;
    // return `rgb(${r},${g},${b})`;
}
function hslToHex(h, s, l) {
    h /= 360;
    s /= 100;
    l /= 100;
    let r, g, b;
    if (s === 0) {
        r = g = b = l; // achromatic
    } else {
        const hue2rgb = (p, q, t) => {
            if (t < 0) t += 1;
            if (t > 1) t -= 1;
            if (t < 1 / 6) return p + (q - p) * 6 * t;
            if (t < 1 / 2) return q;
            if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
            return p;
        };
        const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
        const p = 2 * l - q;
        r = hue2rgb(p, q, h + 1 / 3);
        g = hue2rgb(p, q, h);
        b = hue2rgb(p, q, h - 1 / 3);
    }
    const toHex = x => {
        const hex = Math.round(x * 255).toString(16);
        return hex.length === 1 ? "0" + hex : hex;
    };
    return `#${toHex(r)}${toHex(g)}${toHex(b)}`;
}

export default () => {
    const hue = Variable(198);
    const xAxis = Variable(94);
    const yAxis = Variable(80);
    const alpha = Variable(1);
    function shouldUseBlackColor() {
        return ((xAxis.value < 40 || (45 <= hue.value && hue.value <= 195)) &&
            yAxis.value > 60);
    }
    const colorBlack = 'rgba(0,0,0,0.9)';
    const colorWhite = 'rgba(255,255,255,0.9)';
    const hueRange = Box({
        homogeneous: true,
        className: 'sidebar-module-colorpicker-wrapper',
        children: [Box({
            className: 'sidebar-module-colorpicker-hue',
            css: `background: linear-gradient(to bottom, #ff0000, #ffff00, #00ff00, #00ffff, #0000ff, #ff00ff, #ff0000);`,
        })],
    });
    const hueSlider = Box({
        vpack: 'start',
        className: 'sidebar-module-colorpicker-cursorwrapper',
        homogeneous: true,
        children: [Box({
            className: 'sidebar-module-colorpicker-hue-cursor',
        })],
        setup: (self) => self.hook(hue, () => {
            const widgetHeight = hueRange.children[0].get_allocated_height();
            self.setCss(`margin-top: ${widgetHeight * hue.value / 360}px;`)
        }),
    });
    const hueSelector = Box({
        children: [EventBox({
            child: Overlay({
                child: hueRange,
                overlays: [hueSlider],
            }),
            attribute: {
                clicked: false,
                setHue: (self, event) => {
                    const widgetHeight = hueRange.children[0].get_allocated_height();
                    const [_, cursorX, cursorY] = event.get_coords();
                    const cursorYPercent = clamp(cursorY / widgetHeight, 0, 1);
                    hue.value = Math.round(cursorYPercent * 360);
                }
            },
            setup: (self) => self
                .on('motion-notify-event', (self, event) => {
                    if (!self.attribute.clicked) return;
                    self.attribute.setHue(self, event);
                })
                .on('button-press-event', (self, event) => {
                    if (!(event.get_button()[1] === 1)) return; // We're only interested in left-click here
                    self.attribute.clicked = true;
                    self.attribute.setHue(self, event);
                })
                .on('button-release-event', (self) => self.attribute.clicked = false)
            ,
        })]
    });
    const saturationAndLightnessRange = Box({
        homogeneous: true,
        children: [Box({
            className: 'sidebar-module-colorpicker-saturationandlightness',
            setup: (self) => self.hook(hue, () => {
                // css: `background: linear-gradient(to right, #ffffff, color);`,
                self.setCss(`background: 
                    linear-gradient(to bottom, rgba(0,0,0,0), rgba(0,0,0,1)),
                    linear-gradient(to right, #ffffff, ${hslToHex(hue.value, 100, 50)});
                `);
            }),
        })],
    });
    const saturationAndLightnessCursor = Box({
        className: 'sidebar-module-colorpicker-saturationandlightness-cursorwrapper',
        children: [Box({
            vpack: 'start',
            hpack: 'start',
            homogeneous: true,
            css: `
                margin-left: ${13.636 * xAxis.value / 100}rem;
                margin-top: ${13.636 * (100 - yAxis.value) / 100}rem;
            `, // Why 13.636rem? see class name in stylesheet
            children: [Box({
                className: 'sidebar-module-colorpicker-saturationandlightness-cursor',
                css: `
                    background-color: ${hslToHex(hue.value, xAxis.value, yAxis.value / (1 + xAxis.value / 100))};
                    border-color: ${shouldUseBlackColor() ? colorBlack : colorWhite};
                `,
                attribute: {
                    updateCursorColor: (self) => {
                        self.setCss(`
                            background-color: ${hslToHex(hue.value, xAxis.value, yAxis.value / (1 + xAxis.value / 100))};
                            border-color: ${shouldUseBlackColor() ? colorBlack : colorWhite};
                        `);
                    }
                },
                setup: (self) => self
                    .hook(yAxis, (self) => self.attribute.updateCursorColor(self))
                    .hook(hue, (self) => self.attribute.updateCursorColor(self))
                ,
            })],
            attribute: {
                update: (self) => {
                    const allocation = saturationAndLightnessRange.children[0].get_allocation();
                    self.setCss(`
                        margin-left: ${13.636 * xAxis.value / 100}rem;
                        margin-top: ${13.636 * (100 - yAxis.value) / 100}rem;
                    `); // Why 13.636rem? see class name in stylesheet
                }
            },
            setup: (self) => self.hook(yAxis, (self) => { // And saturation, but both are updated at once so we only need to connect to one
                self.attribute.update(self);
            }),
        })]
    });
    const saturationAndLightnessSelector = Box({
        homogeneous: true,
        className: 'sidebar-module-colorpicker-saturationandlightness-wrapper',
        children: [EventBox({
            child: Overlay({
                child: saturationAndLightnessRange,
                overlays: [saturationAndLightnessCursor],
            }),
            attribute: {
                clicked: false,
                setSaturationAndLightness: (self, event) => {
                    const allocation = saturationAndLightnessRange.children[0].get_allocation();
                    const [_, cursorX, cursorY] = event.get_coords();
                    const cursorXPercent = clamp(cursorX / allocation.width, 0, 1);
                    const cursorYPercent = clamp(cursorY / allocation.height, 0, 1);
                    xAxis.value = Math.round(cursorXPercent * 100);
                    yAxis.value = Math.round(100 - cursorYPercent * 100);
                }
            },
            setup: (self) => self
                .on('motion-notify-event', (self, event) => {
                    if (!self.attribute.clicked) return;
                    self.attribute.setSaturationAndLightness(self, event);
                })
                .on('button-press-event', (self, event) => {
                    if (!(event.get_button()[1] === 1)) return; // We're only interested in left-click here
                    self.attribute.clicked = true;
                    self.attribute.setSaturationAndLightness(self, event);
                })
                .on('button-release-event', (self) => self.attribute.clicked = false)
            ,
        })]
    });
    const resultColorBox = Box({
        className: 'sidebar-module-colorpicker-result-box',
        homogeneous: true,
        css: `background-color: ${hslToHex(hue.value, xAxis.value, yAxis.value / (1 + xAxis.value / 100))};`,
        children: [Label({
            className: 'txt txt-small',
            label: 'Result',
        }),],
        attribute: {
            updateColor: (self) => {
                self.setCss(`background-color: ${hslToHex(hue.value, xAxis.value, yAxis.value / (1 + xAxis.value / 100))};`);
                self.children[0].setCss(`color: ${shouldUseBlackColor() ? colorBlack : colorWhite};`)
            }
        },
        setup: (self) => self
            .hook(yAxis, (self) => self.attribute.updateColor(self))
            .hook(hue, (self) => self.attribute.updateColor(self))
        ,
    });
    const resultHex = Box({
        children: [
            Box({
                vertical: true,
                hexpand: true,
                children: [
                    Label({
                        xalign: 0,
                        className: 'txt-tiny',
                        label: 'Hex',
                    }),
                    Entry({
                        widthChars: 10,
                        className: 'txt-small techfont',
                        css: 'min-width: 0rem;',
                        attribute: {
                            updateColor: (self) => {
                                self.text = hslToHex(hue.value, xAxis.value, yAxis.value / (1 + xAxis.value / 100));
                            }
                        },
                        setup: (self) => self
                            .hook(yAxis, (self) => self.attribute.updateColor(self))
                            .hook(hue, (self) => self.attribute.updateColor(self))
                        ,
                    })
                ]
            }),
            Button({
                child: MaterialIcon('content_copy', 'norm'),
                onClicked: () => Utils
                    .execAsync(['wl-copy', `${hslToHex(hue.value, xAxis.value, yAxis.value / (1 + xAxis.value / 100))}`])
            })
        ]
    });
    const resultRgb = Box({
        children: [
            Box({
                vertical: true,
                hexpand: true,
                children: [
                    Label({
                        xalign: 0,
                        className: 'txt-tiny',
                        label: 'RGB',
                    }),
                    Entry({
                        widthChars: 10,
                        className: 'txt-small techfont',
                        css: 'min-width: 0rem;',
                        attribute: {
                            updateColor: (self) => {
                                self.text = hslToRgbValues(hue.value, xAxis.value, yAxis.value / (1 + xAxis.value / 100));
                            }
                        },
                        setup: (self) => self
                            .hook(yAxis, (self) => self.attribute.updateColor(self))
                            .hook(hue, (self) => self.attribute.updateColor(self))
                        ,
                    })
                ]
            }),
            Button({
                child: MaterialIcon('content_copy', 'norm'),
                onClicked: () => Utils
                    .execAsync(['wl-copy', `rgb(${hslToRgbValues(hue.value, xAxis.value, yAxis.value / (1 + xAxis.value / 100))})`])
            })
        ]
    });
    const resultHsl = Box({
        children: [
            Box({
                vertical: true,
                hexpand: true,
                children: [
                    Label({
                        xalign: 0,
                        className: 'txt-tiny',
                        label: 'HSL',
                    }),
                    Entry({
                        widthChars: 10,
                        className: 'txt-small techfont',
                        css: 'min-width: 0rem;',
                        attribute: {
                            updateColor: (self) => {
                                self.text = `${hue.value},${xAxis.value}%,${Math.round(yAxis.value / (1 + xAxis.value / 100))}%`;
                            }
                        },
                        setup: (self) => self
                            .hook(yAxis, (self) => self.attribute.updateColor(self))
                            .hook(hue, (self) => self.attribute.updateColor(self))
                        ,
                    })
                ]
            }),
            Button({
                child: MaterialIcon('content_copy', 'norm'),
                onClicked: () => Utils
                    .execAsync(['wl-copy', `hsl(${hue.value},${xAxis.value}%,${Math.round(yAxis.value / (1 + xAxis.value / 100))}%)`])
            })
        ]
    });
    const result = Box({
        className: 'sidebar-module-colorpicker-result-area spacing-v-5 txt',
        hexpand: true,
        vertical: true,
        children: [
            resultColorBox,
            resultHex,
            resultRgb,
            resultHsl,
        ]
    })
    return SidebarModule({
        icon: MaterialIcon('colorize', 'norm'),
        name: 'Color picker',
        // revealChild: false,
        child: Box({
            className: 'spacing-h-5',
            children: [
                hueSelector,
                saturationAndLightnessSelector,
                result,
            ]
        })
    });
}