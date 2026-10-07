#!/bin/bash
set -euo pipefail

MODE="${1:-type}"

symbol="$(sed '1,/^### DATA ###$/d' "$0" | fuzzel --match-mode fzf --dmenu | cut -d ' ' -f 1 | tr -d '\n')"

case "$MODE" in
    type)
        wtype "${symbol}" || wl-copy "${symbol}"
        ;;
    copy)
        wl-copy "${symbol}"
        ;;
    both)
        wtype "${symbol}" || true
        wl-copy "${symbol}"
        ;;
    *)
        echo "Usage: $0 [type|copy|both]"
        exit 1
        ;;
esac
exit
### DATA ###
° degree degrees temperature angle celsius fahrenheit
± plus-minus plus minus plusminus
× multiplication multiply times cross
÷ division divide
≈ approximately almost equal approx
≠ not equal notequal inequality
≤ less than or equal leq
≥ greater than or equal geq
∞ infinity infinite inf
√ square root sqrt radical
∑ summation sum sigma
∏ product pi capital
∫ integral calculus
∂ partial derivative
∆ delta capital triangle change
∇ nabla del gradient
∈ element in member
∉ not element notin notmember
⊂ subset proper
⊃ superset proper
⊆ subset or equal subseteq
⊇ superset or equal superseteq
∪ union set
∩ intersection set
∅ empty set null void
∀ for all forall universal
∃ exists existential there
¬ not negation logical
∧ and logical conjunction
∨ or logical disjunction
⊕ xor exclusive or circled plus
⊗ tensor product circled times
∝ proportional to proportionality
≅ congruent approximately equal isomorphic
∼ similar tilde operator
⊥ perpendicular orthogonal
∥ parallel
∠ angle
∡ measured angle
⊾ right angle
⊿ right triangle
⌀ diameter average null
⁰ superscript zero power exponent
¹ superscript one power exponent
² superscript two squared power exponent
³ superscript three cubed power exponent
⁴ superscript four power exponent
⁵ superscript five power exponent
⁶ superscript six power exponent
⁷ superscript seven power exponent
⁸ superscript eight power exponent
⁹ superscript nine power exponent
₀ subscript zero index
₁ subscript one index
₂ subscript two index
₃ subscript three index
₄ subscript four index
₅ subscript five index
₆ subscript six index
₇ subscript seven index
₈ subscript eight index
₉ subscript nine index
α alpha greek letter
β beta greek letter
γ gamma greek letter
δ delta greek letter
ε epsilon greek letter
ζ zeta greek letter
η eta greek letter
θ theta greek letter
ι iota greek letter
κ kappa greek letter
λ lambda greek letter
μ mu micro greek letter
ν nu greek letter
ξ xi greek letter
ο omicron greek letter
π pi greek letter
ρ rho greek letter
σ sigma greek letter
τ tau greek letter
υ upsilon greek letter
φ phi greek letter
χ chi greek letter
ψ psi greek letter
ω omega greek letter
Α Alpha greek capital
Β Beta greek capital
Γ Gamma greek capital
Δ Delta greek capital
Ε Epsilon greek capital
Ζ Zeta greek capital
Η Eta greek capital
Θ Theta greek capital
Ι Iota greek capital
Κ Kappa greek capital
Λ Lambda greek capital
Μ Mu greek capital
Ν Nu greek capital
Ξ Xi greek capital
Ο Omicron greek capital
Π Pi greek capital
Ρ Rho greek capital
Σ Sigma greek capital
Τ Tau greek capital
Υ Upsilon greek capital
Φ Phi greek capital
Χ Chi greek capital
Ψ Psi greek capital
Ω Omega ohm greek capital
$ dollar usd currency
€ euro eur currency
£ pound sterling gbp currency
¥ yen yuan jpy cny currency
¢ cent currency
₹ rupee inr currency
₽ ruble rub currency
₩ won krw currency korean
₪ shekel ils currency israeli
₫ dong vnd currency vietnamese
₴ hryvnia uah currency ukrainian
₱ peso php currency philippine
₡ colon crc currency costa rican
₦ naira ngn currency nigerian
₨ rupee pkr currency pakistani
₮ tugrik mnt currency mongolian
₲ guarani pyg currency paraguayan
₵ cedi ghs currency ghanaian
₸ tenge kzt currency kazakhstani
₺ lira try currency turkish
₼ manat azn currency azerbaijani
₾ lari gel currency georgian
฿ baht thb currency thai
₿ bitcoin btc crypto currency
₠ ecu currency historical
₢ cruzeiro currency historical
₣ franc currency historical
₤ lira currency historical
₧ peseta currency historical
© copyright copy
® registered trademark reg
™ trademark tm
¶ paragraph pilcrow
§ section
† dagger cross
‡ double dagger cross
• bullet point
… ellipsis dots
‰ per mille permille
‱ per ten thousand basis point
′ prime feet arcminute
″ double prime inches arcsecond
‴ triple prime
← left arrow
→ right arrow
↑ up arrow
↓ down arrow
↔ left right arrow bidirectional
↕ up down arrow vertical
⇐ left double arrow
⇒ right double arrow implies
⇑ up double arrow
⇓ down double arrow
⇔ left right double arrow iff equivalence
↗ northeast arrow diagonal
↘ southeast arrow diagonal
↙ southwest arrow diagonal
↖ northwest arrow diagonal
✓ check checkmark tick yes
✗ cross x mark no
✕ multiplication x
★ star filled black
☆ star outline white
♠ spade suit card
♣ club suit card
♥ heart suit card red
♦ diamond suit card red
½ one half fraction
⅓ one third fraction
⅔ two thirds fraction
¼ one quarter fraction
¾ three quarters fraction
⅛ one eighth fraction
⅜ three eighths fraction
⅝ five eighths fraction
⅞ seven eighths fraction
№ number numero
℃ celsius degree temperature
℉ fahrenheit degree temperature
Å angstrom unit length
℧ mho conductance siemens inverted ohm
℮ estimated sign packaging
♂ male mars masculine gender
♀ female venus feminine gender
⚥ male and female hermaphrodite gender
⚢ female female lesbian
⚣ male male gay
⚤ male female heterosexual
♩ quarter note music
♪ eighth note music
♫ beamed eighth notes music
♬ beamed sixteenth notes music
♭ flat music
♮ natural music
♯ sharp music
♔ white king chess
♕ white queen chess
♖ white rook chess
♗ white bishop chess
♘ white knight chess
♙ white pawn chess
♚ black king chess
♛ black queen chess
♜ black rook chess
♝ black bishop chess
♞ black knight chess
♟ black pawn chess
○ white circle hollow
● black circle filled
◐ circle left half black
◑ circle right half black
◒ circle bottom half black
◓ circle top half black
△ white triangle up hollow
▲ black triangle up filled
▽ white triangle down hollow
▼ black triangle down filled
◇ white diamond hollow
◆ black diamond filled
□ white square hollow
■ black square filled
◯ large circle
▢ white square rounded corners
▣ white square vertical fill
▤ white square horizontal fill
▥ white square diagonal crosshatch
▦ white square diagonal fill
▧ white square diagonal fill reverse
▨ white square orthogonal crosshatch
▩ white square diagonal crosshatch
☐ ballot box checkbox
☑ ballot box with check checkbox
☒ ballot box with x checkbox
" left double quotation mark quote
" right double quotation mark quote
' left single quotation mark quote apostrophe
' right single quotation mark quote apostrophe
‚ single low quotation mark quote
„ double low quotation mark quote
‹ single left angle quotation mark
› single right angle quotation mark
« double left angle quotation guillemet
» double right angle guillemet
— em dash long dash
– en dash medium dash
― horizontal bar quotation dash
‐ hyphen
‑ non-breaking hyphen
‒ figure dash
− minus sign
⁃ hyphen bullet
⁄ fraction slash
‰ per mille promille
‱ per ten thousand basis point
‸ caret insert mark
‼ double exclamation mark
‽ interrobang question exclamation
⁇ double question mark
⁈ question exclamation mark
⁉ exclamation question mark
¡ inverted exclamation mark spanish
¿ inverted question mark spanish
⌘ command cmd mac apple
⌥ option alt mac apple
⇧ shift mac apple
⌃ control ctrl mac apple
⎋ escape esc
⌫ delete backspace mac
⌦ forward delete del
↩ return enter mac
⇥ tab mac
⇤ backtab shift tab
⇪ caps lock
⏎ carriage return enter
⌂ home house
⌨ keyboard
⏏ eject
⏻ power symbol
⏼ power sleep
⏽ power toggle
