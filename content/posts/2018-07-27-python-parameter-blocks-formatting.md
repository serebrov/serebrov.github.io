---
title: Formatting Parameter Blocks in Python
date: 2018-07-27
tags: [python]
type: post
url: "/html/2018-07-27-python-parameter-blocks-formatting.html"
---

There are two ways [recommended in pep-8](https://www.python.org/dev/peps/pep-0008/#indentation) to format the blocks with long parameter lists in Python:

```python
# Arguments start on the next line
foo = long_function_name(
    var_one, var_two,
    var_three, var_four)
```

Another way is:

```python
# Arguments start on the same line
foo = long_function_name(var_one, var_two,
                         var_three, var_four)
```

I always prefer the first option and the other one is problematic for a few reasons.
<!-- more -->

For example, if you have two blocks with such indentation, the indent will be jumping:

```python
# Two functions formatted in such way don't look good, indent is jumping
foo = long_function_name(var_one, var_two,
                         var_three, var_four)
bar = another_func(var_one, var_two,
                   var_three, var_four)
```

Another reason is that the indentation will be broken if you, for example, rename the function or make it a class method:

```python
foo = long_function_name(var_one, var_two,
                         var_three, var_four)

# After renaming the function (or the `foo` variable), we need to fix the indentation on following lines
foo = renamed_long_function_name(var_one, var_two,
                         var_three, var_four)

foo = self.long_function_name(var_one, var_two,
                         var_three, var_four)
```

Now, besides the rename / refactoring we need to also fix the indentation in following lines.

While the first way of formatting works good in these cases:

```python
# Two functions near each other, indentation is not jumping
foo = long_function_name(
    var_one, var_two,
    var_three, var_four)
bar = another_func(
    var_one, var_two,
    var_three, var_four)

# Rename / move to class, arguments formatting doesn't need to be changed
foo = long_function_name(
    var_one, var_two,
    var_three, var_four)

foo = renamed_long_function_name(
    var_one, var_two,
    var_three, var_four)

foo = self.long_function_name(
    var_one, var_two,
    var_three, var_four)
```

Along with more convenience during the development, this also results in better diffs, so it will make the code review process easier for a reviewer.
