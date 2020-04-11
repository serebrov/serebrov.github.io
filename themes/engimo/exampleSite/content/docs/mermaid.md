---
date: 2020-01-11
lastmod: 2020-01-11
title: Mermaid Support
authors: ["achary"]
categories:
  - features
tags:
  - engineering
comments: false
mermaid: true
---

In order to include [mermaid] diagram, add the following attribute to the page metadata section:

```
---
mermaid: true
---
```
You may then start adding diagrams. 

## Diagrams
To embed diagrams, add code block section labeled with `mermaid` as a language:

````
```mermaid
classDiagram
Class01 <|-- AveryLongClass : Cool
Class03 *-- Class04
Class05 o-- Class06
Class07 .. Class08
Class07 : equals()
Class07 : Object[] elementData
Class01 : size()
Class01 : int chimp
Class01 : int gorilla
Class08 <--> C2: Cool label
```
````
```mermaid
classDiagram
Class01 <|-- AveryLongClass : Cool
Class03 *-- Class04
Class05 o-- Class06
Class07 .. Class08
Class07 : equals()
Class07 : Object[] elementData
Class01 : size()
Class01 : int chimp
Class01 : int gorilla
Class08 <--> C2: Cool label
```


[mermaid]: https://mermaid-js.github.io/mermaid/#/
