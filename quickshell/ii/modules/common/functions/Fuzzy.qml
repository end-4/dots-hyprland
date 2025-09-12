pragma Singleton
import Quickshell
import "./fuzzysort.js" as FuzzySort

/**
 * Wrapper for FuzzySort to play nicely with Quickshell's imports
 */

Singleton {
    function go(...args) {
        return FuzzySort.go(...args)
    }

    function prepare(...args) {
        return FuzzySort.prepare(...args)
    }
}

