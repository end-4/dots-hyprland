import App from 'resource:///com/github/Aylur/ags/app.js';
import Widget from 'resource:///com/github/Aylur/ags/widget.js';
const { Box, Window } = Widget;


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
        setup: (self) => self
            .hook(App, (self, currentName, visible) => {
                if (currentName === name) {
                    self.toggleClassName(hideClassName, !visible);
                }
            })
        ,
        child: child,
    }),
});