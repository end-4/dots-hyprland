// List of rows
const elements = [
    [
        { name: '', symbol: '', number: '', weight: '', type: 'kana' },
{ name: 'wa', symbol: 'ワ', number: '', weight: '', type: 'kana' },
{ name: 'ra', symbol: 'ラ', number: '', weight: '', type: 'kana' },
{ name: 'ya', symbol: 'ヤ', number: '', weight: '', type: 'kana' },
{ name: 'ma', symbol: 'マ', number: '', weight: '', type: 'kana' },
{ name: 'ha', symbol: 'ハ', number: '', weight: '', type: 'kana' },
{ name: 'na', symbol: 'ナ', number: '', weight: '', type: 'kana' },
{ name: 'ta', symbol: 'タ', number: '', weight: '', type: 'kana' },
{ name: 'sa', symbol: 'サ', number: '', weight: '', type: 'kana' },
{ name: 'ka', symbol: 'カ', number: '', weight: '', type: 'kana' },
{ name: 'a', symbol: 'ア', number: '', weight: '', type: 'kana' },
    ],

    [
        { name: '', symbol: '', number: '', weight: '', type: 'kana' }, // Espaço para 'n' (vogal i não tem 'n')
        { name: 'wi', symbol: 'ヰ', number: '', weight: '', type: 'kana' },
        { name: 'ri', symbol: 'リ', number: '', weight: '', type: 'kana' },
        { name: '', symbol: '', number: '', weight: '', type: 'kana' }, // Espaço para 'y' (ya/yu/yo)
        { name: 'mi', symbol: 'ミ', number: '', weight: '', type: 'kana' },
        { name: 'hi', symbol: 'ヒ', number: '', weight: '', type: 'kana' },
        { name: 'ni', symbol: 'ニ', number: '', weight: '', type: 'kana' },
        { name: 'chi', symbol: 'チ', number: '', weight: '', type: 'kana' },
        { name: 'shi', symbol: 'シ', number: '', weight: '', type: 'kana' },
        { name: 'ki', symbol: 'キ', number: '', weight: '', type: 'kana' },
        { name: 'i', symbol: 'イ', number: '', weight: '', type: 'kana' },
    ],
    [
        { name: '', symbol: '', number: '', weight: '', type: 'kana' },
        { name: '', symbol: '', number: '', weight: '', type: 'kana' },
        { name: 'ru', symbol: 'ル', number: '', weight: '', type: 'kana' },
        { name: 'yu', symbol: 'ユ', number: '', weight: '', type: 'kana' },
        { name: 'mu', symbol: 'ム', number: '', weight: '', type: 'kana' },
        { name: 'fu', symbol: 'フ', number: '', weight: '', type: 'kana' },
        { name: 'nu', symbol: 'ヌ', number: '', weight: '', type: 'kana' },
        { name: 'tsu', symbol: 'ツ', number: '', weight: '', type: 'kana' },
        { name: 'su', symbol: 'ス', number: '', weight: '', type: 'kana' },
        { name: 'ku', symbol: 'ク', number: '', weight: '', type: 'kana' },
        { name: 'u', symbol: 'ウ', number: '', weight: '', type: 'kana' },
    ],
    [
        { name: '', symbol: '', number: '', weight: '', type: 'kana' },
        { name: 'we', symbol: 'ヱ', number: '', weight: '', type: 'kana' },
        { name: 're', symbol: 'レ', number: '', weight: '', type: 'kana' },
        { name: '', symbol: '', number: '', weight: '', type: 'kana' },
        { name: 'me', symbol: 'メ', number: '', weight: '', type: 'kana' },
        { name: 'he', symbol: 'ヘ', number: '', weight: '', type: 'kana' },
        { name: 'ne', symbol: 'ネ', number: '', weight: '', type: 'kana' },
        { name: 'te', symbol: 'テ', number: '', weight: '', type: 'kana' },
        { name: 'se', symbol: 'セ', number: '', weight: '', type: 'kana' },
        { name: 'ke', symbol: 'ケ', number: '', weight: '', type: 'kana' },
        { name: 'e', symbol: 'エ', number: '', weight: '', type: 'kana' },
    ],
    [
        { name: 'n', symbol: 'ン', number: '', weight: '', type: 'kana' },
        { name: 'wo', symbol: 'ヲ', number: '', weight: '', type: 'kana' },
        { name: 'ro', symbol: 'ロ', number: '', weight: '', type: 'kana' },
        { name: 'yo', symbol: 'ヨ', number: '', weight: '', type: 'kana' },
        { name: 'mo', symbol: 'モ', number: '', weight: '', type: 'kana' },
        { name: 'ho', symbol: 'ホ', number: '', weight: '', type: 'kana' },
        { name: 'no', symbol: 'ノ', number: '', weight: '', type: 'kana' },
        { name: 'to', symbol: 'ト', number: '', weight: '', type: 'kana' },
        { name: 'so', symbol: 'ソ', number: '', weight: '', type: 'kana' },
        { name: 'ko', symbol: 'コ', number: '', weight: '', type: 'kana' },
        { name: 'o', symbol: 'オ', number: '', weight: '', type: 'kana' },
    ],
];

const niceTypes = {
    kana: "Kana"
}
