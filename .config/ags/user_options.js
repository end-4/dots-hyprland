// For every option, see ~/.config/ags/modules/.configuration/user_options.js
// (vscode users ctrl+click this: file://./modules/.configuration/user_options.js)
// (vim users: `:vsp` to split window, move cursor to this path, press `gf`. `Ctrl-w` twice to switch between)
//   options listed in this file will override the default ones in the above file

const userConfigOptions = {
	weather: {
		city: "Tallinn", // Europe/Tallinn or Tallinn?
		preferredUnit: "C", // Either C or F
	},
	workspaces: {
		shown: 8,
	},
	appearance: {
		barRoundCorners: 0, // 0: No, 1: Yes - Looks ugly imo
	},
};

export default userConfigOptions;
