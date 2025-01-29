import Widget from 'resource:///com/github/Aylur/ags/widget.js';
import { execAsync } from 'resource:///com/github/Aylur/ags/utils.js';
import { MaterialIcon } from '../.commonwidgets/materialicon.js'; // Assuming MaterialIcon utility is already in place

let activeButton = null; // Variable to track the active button

// Function to fetch the current power profile
const getCurrentPowerProfile = async () => {
    try {
        const output = await execAsync('powerprofilesctl get');
        return output.trim(); // Clean the output to get the profile name
    } catch (error) {
        return 'unknown'; // Default in case of an error
    }
};

// Function to create a button and set it active if it matches the current profile
const createProfileButton = async (profileName, tooltipText, iconName, command) => {
    const currentProfile = await getCurrentPowerProfile();
    
    const button = Widget.Button({
        className: 'txt-small sidebar-iconbutton',
        tooltipText: getString(tooltipText),
        onClicked: (btn) => {
            execAsync(`powerprofilesctl set ${command}`).catch(print);
            btn.toggleClassName('sidebar-button-active', true);

            // Deactivate previously active button if any
            if (activeButton && activeButton !== btn) {
                activeButton.toggleClassName('sidebar-button-active', false);
            }

            // Update the active button reference
            activeButton = btn;
        },
        child: MaterialIcon(iconName, 'norm'),
    });

    // Set the button as active if it matches the current profile
    if (currentProfile === profileName) {
        button.toggleClassName('sidebar-button-active', true);
        activeButton = button;
    }

    return button;
};

// Balanced Profile Module
export const BalancedProfile = async (props = {}) => {
    return createProfileButton('balanced', 'Balanced', 'settings_suggest', 'balanced');
};

// PowerSave Profile Module
export const PowerSaveProfile = async (props = {}) => {
    return createProfileButton('power-saver', 'PowerSave', 'battery_saver', 'power-saver');
};

// Performance Profile Module
export const PerformanceProfile = async (props = {}) => {
    return createProfileButton('performance', 'Performance', 'flash_on', 'performance');
};

// Check if powerprofilesctl is available
async function createPowerBox() {
    try {
        const powerProfilesCtlAvailable = await execAsync('which powerprofilesctl');

        if (!powerProfilesCtlAvailable || powerProfilesCtlAvailable.trim().length === 0) {
            return null;  // If powerprofilesctl is not available, return null
        }

        const powerBox = Widget.Box({
            hpack: 'end',
            className: 'spacing-h-5 txt-medium power-box-title',
            children: [
                Widget.Label({
                    label: getString('Set Power Profile >>'),
                    halign: 'center',
                }),
                Widget.Box({
                    hpack: 'center',
                    className: 'spacing-h-5',
                    children: [
                        await BalancedProfile(),
                        await PowerSaveProfile(),
                        await PerformanceProfile(),
                    ],
                }),
            ],
        });

        return powerBox;
    } catch (error) {
        console.log('Error: powerprofilesctl check failed:', error);
        return null;  // In case of any errors, return null
    }
}

// Use the function to add the widget to the interface only if power profiles daemon is available via powerprofilesctl
export const powerBox = await createPowerBox();

