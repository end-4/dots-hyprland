pragma Singleton
import Quickshell
import "levendist.js" as Levendist

/**
 * Wrapper for levendist.js to play nicely with Quickshell's imports
 */

Singleton {
    function computeScore(...args) {
        return Levendist.computeScore(...args)
    }

    function computeTextMatchScore(...args) {
        return Levendist.computeTextMatchScore(...args)
    }
}

