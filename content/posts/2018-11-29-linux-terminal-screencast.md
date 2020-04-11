---
title: Recording Linux Terminal Session to GIF with asciinema
date: 2018-11-29
tags: [linux]
type: note
url: "/html/2018-11-29-linux-terminal-screencast.html"
---

The [asciinema](https://github.com/asciinema/asciinema) is a good and simple to use tool to record a screencast from the terminal session.

And [asciicast2gif](https://github.com/asciinema/asciicast2gif) allows to convert the recording to gif animation.

<!-- more -->

```
virtualenv -p python3 venv
source venv/bin/activate

pip install asciinema
```

```
$ asciinema
asciinema: recording asciicast to demo.cast
asciinema: press <ctrl-d> or type "exit" when you're done

...

$ <ctrl-d>
asciinema: recording finished
asciinema: asciicast saved to demo.cast
```

And convert it to gif:

```
docker run --rm -v $PWD:/data asciinema/asciicast2gif -t solarized-dark demo.cast demo.gif
```

The result looks like this:

![asciinema demo](/2018-11-29-demo.gif)

And the recording of the recording process :)

![asciinema self-recording](/2018-11-29-asciinema.gif)
