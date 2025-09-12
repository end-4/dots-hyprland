.pragma library

// https://github.com/farzher/fuzzysort
// License: MIT | Copyright (c) 2018 Stephen Kamenar
// A copy of the license is available in the `licenses` folder of this repository

var single =  (search, target) => {
    if(!search || !target) return NULL

    var preparedSearch = getPreparedSearch(search)
    if(!isPrepared(target)) target = getPrepared(target)

    var searchBitflags = preparedSearch.bitflags
    if((searchBitflags & target._bitflags) !== searchBitflags) return NULL

    return algorithm(preparedSearch, target)
}

var go = (search, targets, options) => {
    if(!search) return options?.all ? all(targets, options) : noResults

    var preparedSearch = getPreparedSearch(search)
    var searchBitflags = preparedSearch.bitflags
    var containsSpace  = preparedSearch.containsSpace

    var threshold = denormalizeScore( options?.threshold || 0 )
    var limit     = options?.limit || INFINITY

    var resultsLen = 0; var limitedCount = 0
    var targetsLen = targets.length

    function push_result(result) {
    if(resultsLen < limit) { q.add(result); ++resultsLen }
    else {
        ++limitedCount
        if(result._score > q.peek()._score) q.replaceTop(result)
    }
    }

    // This code is copy/pasted 3 times for performance reasons [options.key, options.keys, no keys]

    // options.key
    if(options?.key) {
    var key = options.key
    for(var i = 0; i < targetsLen; ++i) { var obj = targets[i]
        var target = getValue(obj, key)
        if(!target) continue
        if(!isPrepared(target)) target = getPrepared(target)

        if((searchBitflags & target._bitflags) !== searchBitflags) continue
        var result = algorithm(preparedSearch, target)
        if(result === NULL) continue
        if(result._score < threshold) continue

        result.obj = obj
        push_result(result)
    }

    // options.keys
    } else if(options?.keys) {
    var keys = options.keys
    var keysLen = keys.length

    outer: for(var i = 0; i < targetsLen; ++i) { var obj = targets[i]

        { // early out based on bitflags
        var keysBitflags = 0
        for (var keyI = 0; keyI < keysLen; ++keyI) {
            var key = keys[keyI]
            var target = getValue(obj, key)
            if(!target) { tmpTargets[keyI] = noTarget; continue }
            if(!isPrepared(target)) target = getPrepared(target)
            tmpTargets[keyI] = target

            keysBitflags |= target._bitflags
        }

        if((searchBitflags & keysBitflags) !== searchBitflags) continue
        }

        if(containsSpace) for(let i=0; i<preparedSearch.spaceSearches.length; i++) keysSpacesBestScores[i] = NEGATIVE_INFINITY

        for (var keyI = 0; keyI < keysLen; ++keyI) {
        target = tmpTargets[keyI]
        if(target === noTarget) { tmpResults[keyI] = noTarget; continue }

        tmpResults[keyI] = algorithm(preparedSearch, target, /*allowSpaces=*/false, /*allowPartialMatch=*/containsSpace)
        if(tmpResults[keyI] === NULL) { tmpResults[keyI] = noTarget; continue }

        // todo: this seems weird and wrong. like what if our first match wasn't good. this should just replace it instead of averaging with it
        // if our second match isn't good we ignore it instead of averaging with it
        if(containsSpace) for(let i=0; i<preparedSearch.spaceSearches.length; i++) {
            if(allowPartialMatchScores[i] > -1000) {
            if(keysSpacesBestScores[i] > NEGATIVE_INFINITY) {
                var tmp = (keysSpacesBestScores[i] + allowPartialMatchScores[i]) / 4/*bonus score for having multiple matches*/
                if(tmp > keysSpacesBestScores[i]) keysSpacesBestScores[i] = tmp
            }
            }
            if(allowPartialMatchScores[i] > keysSpacesBestScores[i]) keysSpacesBestScores[i] = allowPartialMatchScores[i]
        }
        }

        if(containsSpace) {
        for(let i=0; i<preparedSearch.spaceSearches.length; i++) { if(keysSpacesBestScores[i] === NEGATIVE_INFINITY) continue outer }
        } else {
        var hasAtLeast1Match = false
        for(let i=0; i < keysLen; i++) { if(tmpResults[i]._score !== NEGATIVE_INFINITY) { hasAtLeast1Match = true; break } }
        if(!hasAtLeast1Match) continue
        }

        var objResults = new KeysResult(keysLen)
        for(let i=0; i < keysLen; i++) { objResults[i] = tmpResults[i] }

        if(containsSpace) {
        var score = 0
        for(let i=0; i<preparedSearch.spaceSearches.length; i++) score += keysSpacesBestScores[i]
        } else {
        // todo could rewrite this scoring to be more similar to when there's spaces
        // if we match multiple keys give us bonus points
        var score = NEGATIVE_INFINITY
        for(let i=0; i<keysLen; i++) {
            var result = objResults[i]
            if(result._score > -1000) {
            if(score > NEGATIVE_INFINITY) {
                var tmp = (score + result._score) / 4/*bonus score for having multiple matches*/
                if(tmp > score) score = tmp
            }
            }
            if(result._score > score) score = result._score
        }
        }

        objResults.obj = obj
        objResults._score = score
        if(options?.scoreFn) {
        score = options.scoreFn(objResults)
        if(!score) continue
        score = denormalizeScore(score)
        objResults._score = score
        }

        if(score < threshold) continue
        push_result(objResults)
    }

    // no keys
    } else {
    for(var i = 0; i < targetsLen; ++i) { var target = targets[i]
        if(!target) continue
        if(!isPrepared(target)) target = getPrepared(target)

        if((searchBitflags & target._bitflags) !== searchBitflags) continue
        var result = algorithm(preparedSearch, target)
        if(result === NULL) continue
        if(result._score < threshold) continue

        push_result(result)
    }
    }

    if(resultsLen === 0) return noResults
    var results = new Array(resultsLen)
    for(var i = resultsLen - 1; i >= 0; --i) results[i] = q.poll()
    results.total = resultsLen + limitedCount
    return results
}


// this is written as 1 function instead of 2 for minification. perf seems fine ...
// except when minified. the perf is very slow
var highlight = (result, open='<b>', close='</b>') => {
    var callback = typeof open === 'function' ? open : undefined

    var target      = result.target
    var targetLen   = target.length
    var indexes     = result.indexes
    var highlighted = ''
    var matchI      = 0
    var indexesI    = 0
    var opened      = false
    var parts       = []

    for(var i = 0; i < targetLen; ++i) { var char = target[i]
    if(indexes[indexesI] === i) {
        ++indexesI
        if(!opened) { opened = true
        if(callback) {
            parts.push(highlighted); highlighted = ''
        } else {
            highlighted += open
        }
        }

        if(indexesI === indexes.length) {
        if(callback) {
            highlighted += char
            parts.push(callback(highlighted, matchI++)); highlighted = ''
            parts.push(target.substr(i+1))
        } else {
            highlighted += char + close + target.substr(i+1)
        }
        break
        }
    } else {
        if(opened) { opened = false
        if(callback) {
            parts.push(callback(highlighted, matchI++)); highlighted = ''
        } else {
            highlighted += close
        }
        }
    }
    highlighted += char
    }

    return callback ? parts : highlighted
}


var prepare = (target) => {
    if(typeof target === 'number') target = ''+target
    else if(typeof target !== 'string') target = ''
    var info = prepareLowerInfo(target)
    return new_result(target, {_targetLower:info._lower, _targetLowerCodes:info.lowerCodes, _bitflags:info.bitflags})
}

var cleanup = () => { preparedCache.clear(); preparedSearchCache.clear() }


// Below this point is only internal code
// Below this point is only internal code
// Below this point is only internal code
// Below this point is only internal code


class Result {
    get ['indexes']() { return this._indexes.slice(0, this._indexes.len).sort((a,b)=>a-b) }
    set ['indexes'](indexes) { return this._indexes = indexes }
    ['highlight'](open, close) { return highlight(this, open, close) }
    get ['score']() { return normalizeScore(this._score) }
    set ['score'](score) { this._score = denormalizeScore(score) }
}

class KeysResult extends Array {
    get ['score']() { return normalizeScore(this._score) }
    set ['score'](score) { this._score = denormalizeScore(score) }
}

var new_result = (target, options) => {
    const result = new Result()
    result['target']             = target
    result['obj']                = options.obj                   ?? NULL
    result._score                = options._score                ?? NEGATIVE_INFINITY
    result._indexes              = options._indexes              ?? []
    result._targetLower          = options._targetLower          ?? ''
    result._targetLowerCodes     = options._targetLowerCodes     ?? NULL
    result._nextBeginningIndexes = options._nextBeginningIndexes ?? NULL
    result._bitflags             = options._bitflags             ?? 0
    return result
}


var normalizeScore = score => {
    if(score === NEGATIVE_INFINITY) return 0
    if(score > 1) return score
    return Math.E ** ( ((-score + 1)**.04307 - 1) * -2)
}
var denormalizeScore = normalizedScore => {
    if(normalizedScore === 0) return NEGATIVE_INFINITY
    if(normalizedScore > 1) return normalizedScore
    return 1 - Math.pow((Math.log(normalizedScore) / -2 + 1), 1 / 0.04307)
}


var prepareSearch = (search) => {
    if(typeof search === 'number') search = ''+search
    else if(typeof search !== 'string') search = ''
    search = search.trim()
    var info = prepareLowerInfo(search)

    var spaceSearches = []
    if(info.containsSpace) {
    var searches = search.split(/\s+/)
    searches = [...new Set(searches)] // distinct
    for(var i=0; i<searches.length; i++) {
        if(searches[i] === '') continue
        var _info = prepareLowerInfo(searches[i])
        spaceSearches.push({lowerCodes:_info.lowerCodes, _lower:searches[i].toLowerCase(), containsSpace:false})
    }
    }

    return {lowerCodes: info.lowerCodes, _lower: info._lower, containsSpace: info.containsSpace, bitflags: info.bitflags, spaceSearches: spaceSearches}
}



var getPrepared = (target) => {
    if(target.length > 999) return prepare(target) // don't cache huge targets
    var targetPrepared = preparedCache.get(target)
    if(targetPrepared !== undefined) return targetPrepared
    targetPrepared = prepare(target)
    preparedCache.set(target, targetPrepared)
    return targetPrepared
}
var getPreparedSearch = (search) => {
    if(search.length > 999) return prepareSearch(search) // don't cache huge searches
    var searchPrepared = preparedSearchCache.get(search)
    if(searchPrepared !== undefined) return searchPrepared
    searchPrepared = prepareSearch(search)
    preparedSearchCache.set(search, searchPrepared)
    return searchPrepared
}


var all = (targets, options) => {
    var results = []; results.total = targets.length // this total can be wrong if some targets are skipped

    var limit = options?.limit || INFINITY

    if(options?.key) {
    for(var i=0;i<targets.length;i++) { var obj = targets[i]
        var target = getValue(obj, options.key)
        if(target == NULL) continue
        if(!isPrepared(target)) target = getPrepared(target)
        var result = new_result(target.target, {_score: target._score, obj: obj})
        results.push(result); if(results.length >= limit) return results
    }
    } else if(options?.keys) {
    for(var i=0;i<targets.length;i++) { var obj = targets[i]
        var objResults = new KeysResult(options.keys.length)
        for (var keyI = options.keys.length - 1; keyI >= 0; --keyI) {
        var target = getValue(obj, options.keys[keyI])
        if(!target) { objResults[keyI] = noTarget; continue }
        if(!isPrepared(target)) target = getPrepared(target)
        target._score = NEGATIVE_INFINITY
        target._indexes.len = 0
        objResults[keyI] = target
        }
        objResults.obj = obj
        objResults._score = NEGATIVE_INFINITY
        results.push(objResults); if(results.length >= limit) return results
    }
    } else {
    for(var i=0;i<targets.length;i++) { var target = targets[i]
        if(target == NULL) continue
        if(!isPrepared(target)) target = getPrepared(target)
        target._score = NEGATIVE_INFINITY
        target._indexes.len = 0
        results.push(target); if(results.length >= limit) return results
    }
    }

    return results
}


var algorithm = (preparedSearch, prepared, allowSpaces=false, allowPartialMatch=false) => {
    if(allowSpaces===false && preparedSearch.containsSpace) return algorithmSpaces(preparedSearch, prepared, allowPartialMatch)

    var searchLower      = preparedSearch._lower
    var searchLowerCodes = preparedSearch.lowerCodes
    var searchLowerCode  = searchLowerCodes[0]
    var targetLowerCodes = prepared._targetLowerCodes
    var searchLen        = searchLowerCodes.length
    var targetLen        = targetLowerCodes.length
    var searchI          = 0 // where we at
    var targetI          = 0 // where you at
    var matchesSimpleLen = 0

    // very basic fuzzy match; to remove non-matching targets ASAP!
    // walk through target. find sequential matches.
    // if all chars aren't found then exit
    for(;;) {
    var isMatch = searchLowerCode === targetLowerCodes[targetI]
    if(isMatch) {
        matchesSimple[matchesSimpleLen++] = targetI
        ++searchI; if(searchI === searchLen) break
        searchLowerCode = searchLowerCodes[searchI]
    }
    ++targetI; if(targetI >= targetLen) return NULL // Failed to find searchI
    }

    var searchI = 0
    var successStrict = false
    var matchesStrictLen = 0

    var nextBeginningIndexes = prepared._nextBeginningIndexes
    if(nextBeginningIndexes === NULL) nextBeginningIndexes = prepared._nextBeginningIndexes = prepareNextBeginningIndexes(prepared.target)
    targetI = matchesSimple[0]===0 ? 0 : nextBeginningIndexes[matchesSimple[0]-1]

    // Our target string successfully matched all characters in sequence!
    // Let's try a more advanced and strict test to improve the score
    // only count it as a match if it's consecutive or a beginning character!
    var backtrackCount = 0
    if(targetI !== targetLen) for(;;) {
    if(targetI >= targetLen) {
        // We failed to find a good spot for this search char, go back to the previous search char and force it forward
        if(searchI <= 0) break // We failed to push chars forward for a better match

        ++backtrackCount; if(backtrackCount > 200) break // exponential backtracking is taking too long, just give up and return a bad match

        --searchI
        var lastMatch = matchesStrict[--matchesStrictLen]
        targetI = nextBeginningIndexes[lastMatch]

    } else {
        var isMatch = searchLowerCodes[searchI] === targetLowerCodes[targetI]
        if(isMatch) {
        matchesStrict[matchesStrictLen++] = targetI
        ++searchI; if(searchI === searchLen) { successStrict = true; break }
        ++targetI
        } else {
        targetI = nextBeginningIndexes[targetI]
        }
    }
    }

    // check if it's a substring match
    var substringIndex = searchLen <= 1 ? -1 : prepared._targetLower.indexOf(searchLower, matchesSimple[0]) // perf: this is slow
    var isSubstring = !!~substringIndex
    var isSubstringBeginning = !isSubstring ? false : substringIndex===0 || prepared._nextBeginningIndexes[substringIndex-1] === substringIndex

    // if it's a substring match but not at a beginning index, let's try to find a substring starting at a beginning index for a better score
    if(isSubstring && !isSubstringBeginning) {
    for(var i=0; i<nextBeginningIndexes.length; i=nextBeginningIndexes[i]) {
        if(i <= substringIndex) continue

        for(var s=0; s<searchLen; s++) if(searchLowerCodes[s] !== prepared._targetLowerCodes[i+s]) break
        if(s === searchLen) { substringIndex = i; isSubstringBeginning = true; break }
    }
    }

    // tally up the score & keep track of matches for highlighting later
    // if it's a simple match, we'll switch to a substring match if a substring exists
    // if it's a strict match, we'll switch to a substring match only if that's a better score

    var calculateScore = matches => {
    var score = 0

    var extraMatchGroupCount = 0
    for(var i = 1; i < searchLen; ++i) {
        if(matches[i] - matches[i-1] !== 1) {score -= matches[i]; ++extraMatchGroupCount}
    }
    var unmatchedDistance = matches[searchLen-1] - matches[0] - (searchLen-1)

    score -= (12+unmatchedDistance) * extraMatchGroupCount // penality for more groups

    if(matches[0] !== 0) score -= matches[0]*matches[0]*.2 // penality for not starting near the beginning

    if(!successStrict) {
        score *= 1000
    } else {
        // successStrict on a target with too many beginning indexes loses points for being a bad target
        var uniqueBeginningIndexes = 1
        for(var i = nextBeginningIndexes[0]; i < targetLen; i=nextBeginningIndexes[i]) ++uniqueBeginningIndexes

        if(uniqueBeginningIndexes > 24) score *= (uniqueBeginningIndexes-24)*10 // quite arbitrary numbers here ...
    }

    score -= (targetLen - searchLen)/2 // penality for longer targets

    if(isSubstring)          score /= 1+searchLen*searchLen*1 // bonus for being a full substring
    if(isSubstringBeginning) score /= 1+searchLen*searchLen*1 // bonus for substring starting on a beginningIndex

    score -= (targetLen - searchLen)/2 // penality for longer targets

    return score
    }

    if(!successStrict) {
    if(isSubstring) for(var i=0; i<searchLen; ++i) matchesSimple[i] = substringIndex+i // at this point it's safe to overwrite matchehsSimple with substr matches
    var matchesBest = matchesSimple
    var score = calculateScore(matchesBest)
    } else {
    if(isSubstringBeginning) {
        for(var i=0; i<searchLen; ++i) matchesSimple[i] = substringIndex+i // at this point it's safe to overwrite matchehsSimple with substr matches
        var matchesBest = matchesSimple
        var score = calculateScore(matchesSimple)
    } else {
        var matchesBest = matchesStrict
        var score = calculateScore(matchesStrict)
    }
    }

    prepared._score = score

    for(var i = 0; i < searchLen; ++i) prepared._indexes[i] = matchesBest[i]
    prepared._indexes.len = searchLen

    const result    = new Result()
    result.target   = prepared.target
    result._score   = prepared._score
    result._indexes = prepared._indexes
    return result
}
var algorithmSpaces = (preparedSearch, target, allowPartialMatch) => {
    var seen_indexes = new Set()
    var score = 0
    var result = NULL

    var first_seen_index_last_search = 0
    var searches = preparedSearch.spaceSearches
    var searchesLen = searches.length
    var changeslen = 0

    // Return _nextBeginningIndexes back to its normal state
    var resetNextBeginningIndexes = () => {
    for(let i=changeslen-1; i>=0; i--) target._nextBeginningIndexes[nextBeginningIndexesChanges[i*2 + 0]] = nextBeginningIndexesChanges[i*2 + 1]
    }

    var hasAtLeast1Match = false
    for(var i=0; i<searchesLen; ++i) {
    allowPartialMatchScores[i] = NEGATIVE_INFINITY
    var search = searches[i]

    result = algorithm(search, target)
    if(allowPartialMatch) {
        if(result === NULL) continue
        hasAtLeast1Match = true
    } else {
        if(result === NULL) {resetNextBeginningIndexes(); return NULL}
    }

    // if not the last search, we need to mutate _nextBeginningIndexes for the next search
    var isTheLastSearch = i === searchesLen - 1
    if(!isTheLastSearch) {
        var indexes = result._indexes

        var indexesIsConsecutiveSubstring = true
        for(let i=0; i<indexes.len-1; i++) {
        if(indexes[i+1] - indexes[i] !== 1) {
            indexesIsConsecutiveSubstring = false; break;
        }
        }

        if(indexesIsConsecutiveSubstring) {
        var newBeginningIndex = indexes[indexes.len-1] + 1
        var toReplace = target._nextBeginningIndexes[newBeginningIndex-1]
        for(let i=newBeginningIndex-1; i>=0; i--) {
            if(toReplace !== target._nextBeginningIndexes[i]) break
            target._nextBeginningIndexes[i] = newBeginningIndex
            nextBeginningIndexesChanges[changeslen*2 + 0] = i
            nextBeginningIndexesChanges[changeslen*2 + 1] = toReplace
            changeslen++
        }
        }
    }

    score += result._score / searchesLen
    allowPartialMatchScores[i] = result._score / searchesLen

    // dock points based on order otherwise "c man" returns Manifest.cpp instead of CheatManager.h
    if(result._indexes[0] < first_seen_index_last_search) {
        score -= (first_seen_index_last_search - result._indexes[0]) * 2
    }
    first_seen_index_last_search = result._indexes[0]

    for(var j=0; j<result._indexes.len; ++j) seen_indexes.add(result._indexes[j])
    }

    if(allowPartialMatch && !hasAtLeast1Match) return NULL

    resetNextBeginningIndexes()

    // allows a search with spaces that's an exact substring to score well
    var allowSpacesResult = algorithm(preparedSearch, target, /*allowSpaces=*/true)
    if(allowSpacesResult !== NULL && allowSpacesResult._score > score) {
    if(allowPartialMatch) {
        for(var i=0; i<searchesLen; ++i) {
        allowPartialMatchScores[i] = allowSpacesResult._score / searchesLen
        }
    }
    return allowSpacesResult
    }

    if(allowPartialMatch) result = target
    result._score = score

    var i = 0
    for (let index of seen_indexes) result._indexes[i++] = index
    result._indexes.len = i

    return result
}

// we use this instead of just .normalize('NFD').replace(/[\u0300-\u036f]/g, '') because that screws with japanese characters
var remove_accents = (str) => str.replace(/\p{Script=Latin}+/gu, match => match.normalize('NFD')).replace(/[\u0300-\u036f]/g, '')

var prepareLowerInfo = (str) => {
    str = remove_accents(str)
    var strLen = str.length
    var lower = str.toLowerCase()
    var lowerCodes = [] // new Array(strLen)    sparse array is too slow
    var bitflags = 0
    var containsSpace = false // space isn't stored in bitflags because of how searching with a space works

    for(var i = 0; i < strLen; ++i) {
    var lowerCode = lowerCodes[i] = lower.charCodeAt(i)

    if(lowerCode === 32) {
        containsSpace = true
        continue // it's important that we don't set any bitflags for space
    }

    var bit = lowerCode>=97&&lowerCode<=122 ? lowerCode-97 // alphabet
            : lowerCode>=48&&lowerCode<=57  ? 26           // numbers
                                                            // 3 bits available
            : lowerCode<=127                ? 30           // other ascii
            :                                 31           // other utf8
    bitflags |= 1<<bit
    }

    return {lowerCodes:lowerCodes, bitflags:bitflags, containsSpace:containsSpace, _lower:lower}
}
var prepareBeginningIndexes = (target) => {
    var targetLen = target.length
    var beginningIndexes = []; var beginningIndexesLen = 0
    var wasUpper = false
    var wasAlphanum = false
    for(var i = 0; i < targetLen; ++i) {
    var targetCode = target.charCodeAt(i)
    var isUpper = targetCode>=65&&targetCode<=90
    var isAlphanum = isUpper || targetCode>=97&&targetCode<=122 || targetCode>=48&&targetCode<=57
    var isBeginning = isUpper && !wasUpper || !wasAlphanum || !isAlphanum
    wasUpper = isUpper
    wasAlphanum = isAlphanum
    if(isBeginning) beginningIndexes[beginningIndexesLen++] = i
    }
    return beginningIndexes
}
var prepareNextBeginningIndexes = (target) => {
    target = remove_accents(target)
    var targetLen = target.length
    var beginningIndexes = prepareBeginningIndexes(target)
    var nextBeginningIndexes = [] // new Array(targetLen)     sparse array is too slow
    var lastIsBeginning = beginningIndexes[0]
    var lastIsBeginningI = 0
    for(var i = 0; i < targetLen; ++i) {
    if(lastIsBeginning > i) {
        nextBeginningIndexes[i] = lastIsBeginning
    } else {
        lastIsBeginning = beginningIndexes[++lastIsBeginningI]
        nextBeginningIndexes[i] = lastIsBeginning===undefined ? targetLen : lastIsBeginning
    }
    }
    return nextBeginningIndexes
}

var preparedCache       = new Map()
var preparedSearchCache = new Map()

// the theory behind these being globals is to reduce garbage collection by not making new arrays
var matchesSimple = []; var matchesStrict = []
var nextBeginningIndexesChanges = [] // allows straw berry to match strawberry well, by modifying the end of a substring to be considered a beginning index for the rest of the search
var keysSpacesBestScores = []; var allowPartialMatchScores = []
var tmpTargets = []; var tmpResults = []

// prop = 'key'                  2.5ms optimized for this case, seems to be about as fast as direct obj[prop]
// prop = 'key1.key2'            10ms
// prop = ['key1', 'key2']       27ms
// prop = obj => obj.tags.join() ??ms
var getValue = (obj, prop) => {
    var tmp = obj[prop]; if(tmp !== undefined) return tmp
    if(typeof prop === 'function') return prop(obj) // this should run first. but that makes string props slower
    var segs = prop
    if(!Array.isArray(prop)) segs = prop.split('.')
    var len = segs.length
    var i = -1
    while (obj && (++i < len)) obj = obj[segs[i]]
    return obj
}

var isPrepared = (x) => { return typeof x === 'object' && typeof x._bitflags === 'number' }
var INFINITY = Infinity; var NEGATIVE_INFINITY = -INFINITY
var noResults = []; noResults.total = 0
var NULL = null

var noTarget = prepare('')

// Hacked version of https://github.com/lemire/FastPriorityQueue.js
var fastpriorityqueue=r=>{var e=[],o=0,a={},v=r=>{for(var a=0,v=e[a],c=1;c<o;){var s=c+1;a=c,s<o&&e[s]._score<e[c]._score&&(a=s),e[a-1>>1]=e[a],c=1+(a<<1)}for(var f=a-1>>1;a>0&&v._score<e[f]._score;f=(a=f)-1>>1)e[a]=e[f];e[a]=v};return a.add=(r=>{var a=o;e[o++]=r;for(var v=a-1>>1;a>0&&r._score<e[v]._score;v=(a=v)-1>>1)e[a]=e[v];e[a]=r}),a.poll=(r=>{if(0!==o){var a=e[0];return e[0]=e[--o],v(),a}}),a.peek=(r=>{if(0!==o)return e[0]}),a.replaceTop=(r=>{e[0]=r,v()}),a}
var q = fastpriorityqueue() // reuse this
