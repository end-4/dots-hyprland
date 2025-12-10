function hasActive(element) {
	return element.activeFocus || Array.from(
		element.children
	).some(
		(child) => hasActive(child)
	);
};
