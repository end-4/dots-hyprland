const { Gtk } = imports.gi;
import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import * as Utils from 'resource:///com/github/Aylur/ags/utils.js';
const { execAsync, exec } = Utils;
const { Box, Button, Entry, EventBox, Icon, Label, Scrollable, Overlay } = Widget;
import SidebarModule from './module.js';
import { MaterialIcon } from '../../.commonwidgets/materialicon.js';
import { setupCursorHover } from '../../.widgetutils/cursorhover.js';
import { truncateToPrecision } from '../../.miscutils/mathfuncs.js';

const VALUE_DEFAULT_PRECISION = 3;
const conversions = [
    {
        unit1: 'px',
        unit2: 'rem',
        unit1Default: 5,
        formula1to2: '{{x}} / (parseFloat(Utils.exec(\'gsettings get org.gnome.desktop.interface font-name\').split(" ").pop().split("\'"))*4/3)',
        formula2to1: '{{x}} * (parseFloat(Utils.exec(\'gsettings get org.gnome.desktop.interface font-name\').split(" ").pop().split("\'"))*4/3)',
        forcePrecision: true,
    },
    {
        unit1: 'deg',
        unit2: 'rad',
        unit1Default: 90,
        formula1to2: '{{x}} * Math.PI / 180',
        formula2to1: '{{x}} * 180 / Math.PI',
    },
    {
        unit1: '°F',
        unit2: '°C',
        unit1Default: 68,
        formula1to2: '({{x}} - 32) * 5 / 9',
        formula2to1: '{{x}} * 9 / 5 + 32',
    },
    {
        unit1: 'Ft',
        unit2: 'Cm',
        formula1to2: '{{x}} * 30.48',
        formula2to1: '{{x}} / 30.48',
    },
    // {
    //     unit1: 'Mile',
    //     unit2: 'Km',
    //     formula1to2: '{{x}} * 1.60934',
    //     formula2to1: '{{x}} / 1.60934',
    // },
    // {
    //     unit1: 'Inch',
    //     unit2: 'Cm',
    //     formula1to2: '{{x}} * 2.54',
    //     formula2to1: '{{x}} / 2.54',
    // },
    {
        unit1: 'lbs',
        unit2: 'Kg',
        formula1to2: '{{x}} * 0.453592',
        formula2to1: '{{x}} / 0.453592',
    }
]

export default () => {
    const ValueBox = ({ unit, initValue = 0, updateCallback }) => {
        const unitName = Label({
            xalign: 0,
            className: 'txt txt-smallie txt-semibold margin-top-2 margin-left-2',
            label: `${unit}`,
        });
        const entry = Entry({
            hexpand: 'true',
            widthChars: 10,
            className: 'txt-small techfont margin-left-2',
            text: `${initValue}`,
            onChange: updateCallback,
        });
        const copyButton = Button({
            className: 'sidebar-module-csscalc-valuebox-copybtn',
            child: MaterialIcon('content_copy', 'norm'),
            onClicked: (self) => {
                Utils.execAsync(['wl-copy', entry.text]);
                self.child.label = 'done';
                Utils.timeout(1000, () => self.child.label = 'content_copy');
            },
            setup: setupCursorHover,
        });
        const wholeThing = Box({
            className: 'sidebar-module-csscalc-valuebox',
            vertical: true,
            hexpand: true,
            children: [
                unitName,
                Box({
                    children: [
                        entry,
                        copyButton,
                    ]
                })
            ],
            attribute: {
                updateValue: (value) => entry.text = `${value}`,
                getValue: () => entry.text,
            }
        });
        return wholeThing;
    }
    // Formula format is js expression, with `{{x}}` being the input value
    const BidirectionalConversion = ({
        unit1, unit2, unit1Default = 1,
        formula1to2, formula2to1,
        forcePrecision = false, precision = VALUE_DEFAULT_PRECISION,
    }) => {
        let updateLock = false;
        const convert = (value, formula) => {
            let thisValue;
            try {
                thisValue = eval(value)
            } catch (error) {
                thisValue = parseFloat(value);
            }
            // print(formula.replace('{{x}}', thisValue))
            // print(eval(formula.replace('{{x}}', thisValue)))
            const evalResult = eval(formula.replace('{{x}}', thisValue));
            const result = forcePrecision ?
                evalResult.toFixed(precision) : truncateToPrecision(evalResult, precision);
            // print(result)
            return result;
        }
        const unit1Box = ValueBox({
            unit: unit1,
            initValue: unit1Default,
            updateCallback: (self) => {
                if (updateLock) return;
                updateLock = true;
                const newValue = convert(self.text, formula1to2);
                unit2Box.attribute.updateValue(newValue || 0);
                updateLock = false;
            },
        });
        const unit2Box = ValueBox({
            unit: unit2,
            initValue: truncateToPrecision(eval(formula1to2.replace('\{{x}}', unit1Default)), precision),
            updateCallback: (self) => {
                if (updateLock) return;
                updateLock = true;
                const newValue = convert(self.text, formula2to1);
                unit1Box.attribute.updateValue(newValue || 0);
                updateLock = false;
            },
        });
        return Box({
            className: 'txt spacing-h-10',
            children: [
                unit1Box,
                MaterialIcon('swap_horiz', 'large'),
                unit2Box,
            ]
        })
    }

    return SidebarModule({
        icon: MaterialIcon('autorenew', 'norm'),
        name: getString('Conversions'),
        child: Box({
            vertical: true,
            className: 'spacing-v-5',
            children: conversions.map(BidirectionalConversion),
        })
    });
}