# Cursor shaders

Vendored from
[sahaj-b/ghostty-cursor-shaders](https://github.com/sahaj-b/ghostty-cursor-shaders)
(MIT, see `LICENSE`), unmodified. The tunables are the `const` block at the top
of each file.

`cursor_tail.glsl` is the active one: a comet trail, equivalent to kitty's
`cursor_trail`. It reads the trail colour from the live cursor colour, so it
follows `cursor-color`.

Shader compile errors do not surface as config errors. Check
`log stream --predicate 'process == "ghostty"'` if a shader silently does
nothing.
