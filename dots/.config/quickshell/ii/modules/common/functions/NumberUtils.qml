pragma Singleton
import Quickshell

Singleton {
    id: root

    /**
     * Rounds the given number to the nearest even integer.
     *
     * @param {number} num - The number to round.
     * @returns {number} The nearest even integer.
     */
    function roundToEven(num) {
        return Math.round(num / 2) * 2;
    }
}
