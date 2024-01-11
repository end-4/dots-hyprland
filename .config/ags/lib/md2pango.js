// SPDX-FileCopyrightText: 2021 Uwe Jugel
// SPDX-License-Identifier: MIT
// This file is part of md2pango (https://github.com/ubunatic/md2pango).

const monospaceFonts = 'JetBrains Mono NF, JetBrains Mono Nerd Font, JetBrains Mono NL, SpaceMono NF, SpaceMono Nerd Font, monospace'

const H1 = "H1", H2 = "H2", H3 = "H3", H4 = "H4", H5 = "H5", BULLET = "BULLET", NUMBERING = "NUMBERING", CODE = "CODE"
const BOLD = "BOLD", EMPH = "EMPH", INLCODE = "INLCODE", LINK = "LINK", HEXCOLOR = "HEXCOLOR", UND = "UND"

let sub_h1, sub_h2, sub_h3, sub_h4, sub_h5

// m2p_sections defines how to detect special markdown sections.
// These expressions scan the full line to detect headings, lists, and code.
const m2p_sections = [
    sub_h1 = { name: H1, re: /^(#\s+)(.*)(\s*)$/, sub: "<span font_weight='bold' size='170%'>$2</span>" },
    sub_h2 = { name: H2, re: /^(##\s+)(.*)(\s*)$/, sub: "<span font_weight='bold' size='150%'>$2</span>" },
    sub_h3 = { name: H3, re: /^(###\s+)(.*)(\s*)$/, sub: "<span font_weight='bold' size='125%'>$2</span>" },
    sub_h4 = { name: H4, re: /^(####\s+)(.*)(\s*)$/, sub: "<span font_weight='bold' size='100%'>$2</span>" },
    sub_h5 = { name: H5, re: /^(#####\s+)(.*)(\s*)$/, sub: "<span font_weight='bold' size='90%'>$2</span>" },
    { name: BULLET, re: /^(\s*)([\*\-]\s)(.*)(\s*)$/, sub: "$1• $3" },
    { name: NUMBERING, re: /^(\s*[0-9]+\.\s)(.*)(\s*)$/, sub: " $1$2" },
]

// m2p_styles defines how to replace inline styled text
const m2p_styles = [
    { name: BOLD, re: /(\*\*)(\S[\s\S]*?\S)(\*\*)/g, sub: "<b>$2</b>" },
    { name: UND, re: /(__)(\S[\s\S]*?\S)(__)/g, sub: "<u>$2</u>" },
    { name: EMPH, re: /\*(\S.*?\S)\*/g, sub: "<i>$1</i>" },
    // { name: EMPH, re: /_(\S.*?\S)_/g, sub: "<i>$1</i>" },
    { name: HEXCOLOR, re: /#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})/g, sub: `<span bgcolor='#$1' fgcolor='#000000' font_family='${monospaceFonts}'> #$1 </span>` },
    { name: INLCODE, re: /(`)([^`]*)(`)/g, sub: `<span font_weight='bold' font_family='${monospaceFonts}'> $2 </span>` },
    // { name: UND, re: /(__|\*\*)(\S[\s\S]*?\S)(__|\*\*)/g, sub: "<u>$2</u>" },
]

const re_comment = /^\s*<!--.*-->\s*$/
const re_color = /^(\s*<!--\s*(fg|bg)=(#?[0-9a-z_A-Z-]*)\s*((fg|bg)=(#?[0-9a-z_A-Z-]*))?\s*-->\s*)$/
const re_reset = /(<!--\/-->)/
const re_uri = /http[s]?:\/\/[^\s']*/
const re_href = "/href='(http[s]?:\\/\\/[^\\s]*)'"
const re_atag = "<a\s.*>.*(http[s]?:\\/\\/[^\\s]*).*</a>/"
const re_h1line = /^===+\s*$/
const re_h2line = /^---+\s*$/

const m2p_escapes = [
    [/<!--.*-->/, ''],
    [/&/g, '&amp;'],
    [/</g, '&lt;'],
    [/>/g, '&gt;'],
]

const code_color_span = "<span foreground='#bbb' background='#222'>"

const escape_line = (line) => m2p_escapes.reduce((l, esc) => l.replace(...esc), line)

const pad = (lines, start = 1, end = 1) => {
    let len = lines.reduce((n, l) => l.length > n ? l.length : n, 0)
    return lines.map((l) => l.padEnd(len + end, ' ').padStart(len + end + start, ' '))
}

export default (text) => {
    let lines = text.split('\n')

    // Indicates if the current line is within a code block
    let is_code = false
    let code_lines = []

    let output = []
    let color_span_open = false
    let tt_must_close = false

    const try_close_span = () => {
        if (color_span_open) {
            output.push('</span>')
            color_span_open = false
        }
    }

    const try_open_span = () => {
        if (!color_span_open) {
            output.push('</span>')
            color_span_open = false
        }
    }

    for (const line of lines) {
        // first parse color macros in non-code texts
        if (!is_code) {
            let colors = line.match(re_color)
            if (colors || line.match(re_reset)) {
                try_close_span()
            }

            if (colors) {
                try_close_span()
                if (color_span_open) {
                    close_span()
                }

                let fg = colors[2] == 'fg' ? colors[3] : colors[5] == 'fg' ? colors[6] : ''
                let bg = colors[2] == 'bg' ? colors[3] : colors[5] == 'bg' ? colors[6] : ''
                let attrs = ''

                if (fg != '') {
                    attrs += ` foreground='${fg}'`
                }

                if (bg != '') {
                    attrs += ` background='${bg}'`
                }

                if (attrs != '') {
                    output.push(`<span${attrs}>`)
                    color_span_open = true
                }
            }
        }

        // all macros processed, let's remove remaining comments
        if (line.match(re_comment)) {
            continue
        }

        // is this line an opening statement of a code block
        let code_start = false

        // escape all non-verbatim text
        let result = is_code ? line : escape_line(line)

        for (const { name, re, sub } of m2p_sections) {
            if (line.match(re)) {
                if (name === CODE) {
                    if (!is_code) {
                        // haven't been inside a code block, so ``` indicates
                        // that it is starting now
                        code_start = true
                        is_code = true

                        if (color_span_open) {
                            // cannot color
                            result = '<tt>'
                            tt_must_close = false
                        } else {
                            result = code_color_span + '<tt>'
                            tt_must_close = true
                        }
                    } else {
                        // the code block ends now
                        is_code = false
                        output.push(...pad(code_lines).map(escape_line))
                        code_lines = []
                        result = '</tt>'
                        if (tt_must_close) {
                            result += '</span>'
                            tt_must_close = false
                        }
                    }
                } else {
                    if (is_code) {
                        result = line
                    } else {
                        result = line.replace(re, sub)
                    }
                }
            }
        }

        if (is_code && !code_start) {
            code_lines.push(result)
            continue
        }

        if (line.match(re_h1line)) {
            output.push(`# ${output.pop()}`.replace(sub_h1.re, sub_h1.sub))
            continue
        }

        if (line.match(re_h2line)) {
            output.push(`## ${output.pop()}`.replace(sub_h2.re, sub_h2.sub))
            continue
        }

        // all other text can be styled
        for (const style of m2p_styles) {
            result = result.replace(style.re, style.sub)
        }

        // all raw urls can be linked if possible
        let uri = result.match(re_uri)    // look for any URI
        let href = result.match(re_href)   // and for URIs in href=''
        let atag = result.match(re_atag)   // and for URIs in <a></a>
        href = href && href[1] == uri
        atag = href && atag[1] == uri
        if (uri && (href || atag)) {
            result = result.replace(uri, `<a href='${uri}'>${uri}</a>`)
        }

        output.push(result)
    }

    try_close_span()

    // remove trailing whitespaces
    output = output.map(line => line.replace(/ +$/, ''))

    return output.join('\n')
}

export const markdownTest = `# Heading 1
## Heading 2
### Heading 3
#### Heading 4
##### Heading 5
1. yes
2. no
127. well
- Bulletpoint starting with minus
* Bulletpoint starting with asterisk
---
- __Underline__ __ No underline __
- **Bold** ** No bold **
- _Italics1_ *Italics2* _ No Italics _
- A color: #D6BAFF
- nvidia green: #7ABB08
  - sub-item
\`\`\`javascript
// A code block!
myArray = [23, 123, 43, 54, '6969'];
console.log('uwu');
\`\`\`
To update arch lincox, run \`sudo pacman -Syu\`
`;