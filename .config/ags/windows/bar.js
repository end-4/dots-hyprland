var left = {
    type: 'box', className: 'bar-sidemodule',
    children: [{ type: 'modules/music' }],
};

var center = {
    type: 'box', children: [{ type: 'modules/workspaces' }],
};

var right = {
    type: 'box', className: 'bar-sidemodule',
    children: [{ type: 'modules/system' }],
};

var separator = {
    type: 'box',
    className: 'bar-separator',
    halign: 'center',
    valign: 'center',
};

var bar = {
    name: 'bar',
    anchor: ['top', 'left', 'right'],
    exclusive: true,
    child: {
        className: 'bar-bg',
        type: 'centerbox',
        children: [
            { type: 'modules/leftspace' },
            {
                type: 'box',
                children: [
                    left,
                    center,
                    right,
                ]
            },
            { type: 'modules/rightspace' },
        ],
    },
}