---
title: vim - replace a word with yanked text multiple times
date: 2012-04-03
tags: [vim]
type: note
url: "/html/2012-04-03-vim-replace-word-with-yanked-text.html"
---

It is often useful to copy, let's say `new_name`, to clipboard and then replace one or more occurrences of `old_name` with it.
We can use `:%s/new_name/old_name/g` for that, but sometimes it is more convenient to go over the text and do replacements "manually".

A possible way to do that in `vim` is:

* Yank inner word: `yiw` (the `new_name` is now in the default register `""`)
* Move cursor to another word (the `old_name`)
* Select it and paste over: `viwp` (`viw` - visual inner word, `p` - paste)

What happens next might be unexpected in this scenario: when we pasted over the `old_name`, it was deleted and put into the default Vim register instead of `new_name`, so next time we use `p`, it will paste the `old_name` (tldr: the `xnoremap p pgvy` mapping helps fix this).

This behavior is nice when we actually deleted something, for example, if we did `dw` to delete `old_name`, we expect to be able to paste it with `p`, but this is less expected in the case the deletion was implicit, as in the case of the pasting over selection.

<!-- more -->

At this point, we have a couple of choices to continue pasting `new_name`:

* Option 1: `gvy` (`gv` - reselect last selection, `y` - copy) to reselect `new_name` and copy it again and then do `viwp` on another word
* Option 2: use `viw"0p` on another word; here `"0p` will paste from `0` register (the default register now contains `old_name` and `"0` register contains the previously `yank`ed `new_name`)

In more detail, what happens during this process is:

* Deleting, changing and yanking text copies the affected text to the unnamed register (`""`).
* Yanking text also copies the text to register 0 (`"0`).
* We yank inner word: `yiw` (the `new_name`), it is now in `""` and `"0`
* We move cursor to another word (the `old_name`)
* We select the `old_name` and paste over: `viwp`, the deleted `old_name` is in `""` and the `new_name` is still in `"0p`
* Next time we use `p`, it pastes `old_name` since `p` uses `""` register by default (but we can instruct `p` to use the `"0` register with `"0p`)

# Solution

The solution that works quite well for me is the following mapping

```
xnoremap p pgvy
```

As mentioned above, the default Vim behavior is counter-intuitive when we paste over the selection: most of the time we do not need the text we pasted over (so do not want it to get into the default `""` register), but the same behavior is useful when we explicitly delete something (`dw` a word and the `p`aste it somewhere else).

The mapping above only redefines the first case:

* `xnoremap` - map only in visual mode, when we have something selected
* `p` - redefine `p` behavior
* `pgvy` - `p` past, `gv` reselect what we've just pasted, `y` copy back what we've just pasted

With this mapping, we can still use Vim's standard behavior if needed by using `gp` instead of `p` (`gp` is almost the same as p, with cursor left after the pasted text instead of the last char of it).

Another solution that seems simple is to have a `xnoremap p "0p` that would always use the `"0p` register when pasting in visual mode (in the example above, we saw that `new_name` stays in `"0p` during the whole process). But there is a negative side-effect: when we delete something explicitly, it gets into `""`, but not into `"0p`, so we can not then `p`aste it in visual mode. For example, select and copy `irrelevant_name` with `yiw`, delete `new_name` with `dw`, select `old_name` and paste with `yiwp` - the `irrelevant_name` will be pasted (while `new_name` is expected).

One more solution is to use named registered:
* Yank the `new_name` into a specific register, for example, the `a` register: `"ayiw`
* Move the cursor to the `old_name`, select it with `viw`
* Paste the contents of the `a` register over the selected text: `"ap`

This works, but I need to remember to use the named register before I start the operation and it also requires typing the `"a` prefix, which is not very convenient.

I recommend the `xnoremap p pgvy`, it works well and I did not find any drawbacks while using it.

Links
------
[vim.wikia.com](http://vim.wikia.com/wiki/Replace_a_word_with_yanked_text)
[Stackoverflow: Paste multiple times](https://stackoverflow.com/questions/7163947/paste-multiple-times)
