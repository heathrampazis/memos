# Memos — code conventions

Readability comes before brevity. Someone new to Swift should be able to read any
function from top to bottom and know what it does, without having to unpack it.

## Write it out

- Prefer a plain `for` loop over `map`, `filter`, `compactMap`, `reduce`, `forEach`,
  `zip` and `stride`. Declare the result as a `var`, append to it in the loop, return it.
- Give intermediate values a name. A named `let` on its own line beats a longer
  expression, even when the longer one would fit.
- One statement does one thing. Never hide a side effect inside a closure: if a line
  both finds something and changes something, that is two lines.
- Expand a ternary into `if`/`else` when it assigns to something or returns. A short
  ternary inside a view modifier — `opacity(isOn ? 1 : 0.4)` — is fine and stays.
- Never nest a ternary inside another ternary.
- Prefer an early `return` to an `else` branch that wraps the rest of the function.

## Leave these alone

These are not cleverness, and rewriting them makes the code harder to read, not easier.

- `guard ... else { return }`. It is how Swift keeps the ordinary path unindented;
  turning it into `if` nests the whole function one level deeper for every condition.
- `switch` with one expression per case.
- `some View`, `@ViewBuilder` and SwiftUI's builder syntax. The framework requires them.
- Swift's own API names. Do not wrap `NSAttributedString` or `UITextView` calls in
  helpers just to shorten them.

## Comments

Say why, not what. The code already says what it does. A comment earns its place by
explaining a decision, a constraint, or a bug it is there to prevent.
