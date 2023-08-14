var indicator = monitor => ({
    monitor,
    name: `indicator${monitor}`,
    className: 'indicator',
    layer: 'overlay',
    anchor: ['left'],
    child: { type: 'on-screen-indicator' },
});