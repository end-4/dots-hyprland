pragma Singleton
import Quickshell
import "myers.js" as Myers

/**
 * Bit-parallel fuzzy matching helpers.
 */

Singleton {
    /** Lowercase + NFC normalize a string. Same transform applied internally by prepare() and score(). */
    function normalize(value)               { return Myers.normalize(value) }

    /** Precompute pattern state for reuse across comparisons. */
    function prepare(pattern)               { return Myers.prepare(pattern) }

    /** Return Levenshtein edit distance. Normalizes text automatically. */
    function distance(prepared, text)           { return Myers.distance(prepared, text) }

    /** Return Levenshtein edit distance. text must already be normalized. */
    function distanceNormalized(prepared, text) { return Myers.distanceNormalized(prepared, text) }

    /** Return normalized similarity in [0, 1]. */
    function score(prepared, text)          { return Myers.score(prepared, text) }

    /** Compute one-off similarity without prepare(). */
    function computeScore(pattern, text)    { return Myers.computeScore(pattern, text) }

    /** Compatibility wrapper for Levendist.computeTextMatchScore. */
    function computeTextMatchScore(s1, s2)  { return Myers.computeTextMatchScore(s1, s2) }

    /**
     * Return candidates sorted by descending similarity.
     * opts: { key?: string, threshold?: number }
     */
    function search(prepared, candidates, opts) { return Myers.search(prepared, candidates, opts) }
}
