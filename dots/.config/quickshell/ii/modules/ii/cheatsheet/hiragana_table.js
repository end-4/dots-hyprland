// List of rows for Hiragana (Standard Gojuon order)
const elements = [
    // Vowels (A)
    [
        { name: 'a', symbol: 'あ', type: 'main' },
        { name: 'i', symbol: 'い', type: 'main' },
        { name: 'u', symbol: 'う', type: 'main' },
        { name: 'e', symbol: 'え', type: 'main' },
        { name: 'o', symbol: 'お', type: 'main' },
    ],
    // K
    [
        { name: 'ka', symbol: 'か', type: 'main' },
        { name: 'ki', symbol: 'き', type: 'main' },
        { name: 'ku', symbol: 'く', type: 'main' },
        { name: 'ke', symbol: 'け', type: 'main' },
        { name: 'ko', symbol: 'こ', type: 'main' },
    ],
    // S
    [
        { name: 'sa', symbol: 'さ', type: 'main' },
        { name: 'shi', symbol: 'し', type: 'main' },
        { name: 'su', symbol: 'す', type: 'main' },
        { name: 'se', symbol: 'せ', type: 'main' },
        { name: 'so', symbol: 'そ', type: 'main' },
    ],
    // T
    [
        { name: 'ta', symbol: 'た', type: 'main' },
        { name: 'chi', symbol: 'ち', type: 'main' },
        { name: 'tsu', symbol: 'つ', type: 'main' },
        { name: 'te', symbol: 'て', type: 'main' },
        { name: 'to', symbol: 'と', type: 'main' },
    ],
    // N
    [
        { name: 'na', symbol: 'な', type: 'main' },
        { name: 'ni', symbol: 'に', type: 'main' },
        { name: 'nu', symbol: 'ぬ', type: 'main' },
        { name: 'ne', symbol: 'ね', type: 'main' },
        { name: 'no', symbol: 'の', type: 'main' },
    ],
    // H
    [
        { name: 'ha', symbol: 'は', type: 'main' },
        { name: 'hi', symbol: 'ひ', type: 'main' },
        { name: 'fu', symbol: 'ふ', type: 'main' },
        { name: 'he', symbol: 'へ', type: 'main' },
        { name: 'ho', symbol: 'ほ', type: 'main' },
    ],
    // M
    [
        { name: 'ma', symbol: 'ま', type: 'main' },
        { name: 'mi', symbol: 'み', type: 'main' },
        { name: 'mu', symbol: 'む', type: 'main' },
        { name: 'me', symbol: 'め', type: 'main' },
        { name: 'mo', symbol: 'も', type: 'main' },
    ],
    // Y
    [
        { name: 'ya', symbol: 'や', type: 'main' },
        { name: '', symbol: '', type: 'empty' },
        { name: 'yu', symbol: 'ゆ', type: 'main' },
        { name: '', symbol: '', type: 'empty' },
        { name: 'yo', symbol: 'よ', type: 'main' },
    ],
    // R
    [
        { name: 'ra', symbol: 'ら', type: 'main' },
        { name: 'ri', symbol: 'り', type: 'main' },
        { name: 'ru', symbol: 'る', type: 'main' },
        { name: 're', symbol: 'れ', type: 'main' },
        { name: 'ro', symbol: 'ろ', type: 'main' },
    ],
    // W / N
    [
        { name: 'wa', symbol: 'わ', type: 'main' },
        { name: '', symbol: '', type: 'empty' },
        { name: 'wo', symbol: 'を', type: 'main' },
        { name: '', symbol: '', type: 'empty' },
        { name: 'n', symbol: 'ん', type: 'main' },
    ],
];

// We don't need the "series" (Lanthanides) for Hiragana, so we leave it empty
const series = [];
