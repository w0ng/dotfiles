# Cursor shaders

Vendored from [sahaj-b/ghostty-cursor-shaders](https://github.com/sahaj-b/ghostty-cursor-shaders)
(MIT, see `LICENSE`). Unmodified; the tunables are the `const` block at the top of each file.

- `cursor_tail.glsl`: comet trail, the kitty `cursor_trail` equivalent. Active.

It reads the trail colour from the live cursor colour, so it follows `cursor-color`.
Shader compile errors do not surface as config errors. Check
`log stream --predicate 'process == "ghostty"'` if a shader silently does nothing.
