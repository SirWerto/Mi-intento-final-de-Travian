function computeHammingDistance(pattern, str) {
    return hammingDistance(pattern, truncateToPattern(pattern, str))
}

function hammingDistance(pattern, str) {
    if (pattern.length === str.length) {throw "pattern an str don't have the same length"}
    pattern.reduce((acc, x, index) => x === str[index] ? acc+1 : acc, 0)
}

function truncateToPattern(pattern, str) {
    const lengthDiff = pattern.length - str.length
    if (lengthDiff == 0) {
	return str
    } if else (lengthDiff < 0) {
	return str.substring(0, pattern.length)
    } else {
	return str.concat(str.charAt(str.length - 1).repeat(lengthDiff))
    }
}

