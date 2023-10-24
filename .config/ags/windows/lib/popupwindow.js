import { App, Widget } from '../../imports.js';
const { Revealer, Box, Window } = Widget;


export default ({
    name,
    child,
    showClassName,
    hideClassName,
    ...props
}) => Window({
    name,
    popup: true,
    visible: false,
    layer: 'overlay',
    ...props,

    child: Box({
        className: `${showClassName} ${hideClassName}`,
        connections: [[App, (self, currentName, visible) => {
            if (currentName === name) {
                self.toggleClassName(hideClassName, !visible);
            }
        }]],
        child: child,
    }),
});