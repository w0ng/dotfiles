To mimick the compatible symbols from `vim-powerline`, aside from config files,
you also need to change

in `/usr/lib/python3.3/site-packages/powerline/segments/vim.py`:

```diff
-  137:def readonly_indicator(pl, segment_info, text='î¢'):
+  137:def readonly_indicator(pl, segment_info, text='RO '):
```
