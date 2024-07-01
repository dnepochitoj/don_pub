# markdown cheat sheet

* Overview
* Headings
* Paragraphs
* Line Breaks
* Emphasis
* Blockquotes
* Lists
* Code
* Horizontal Rules
* Links
* Images
* Escaping Characters
* Footnotes
* Abbreviations
* Table

## Headings

# Heading level 1
## Heading level 2
### Heading level 3
#### Heading level 4
##### Heading level 5

## Bold

I just love **bold text**.
Love**is**bold

## Italic

Italicized text is the *cat's meow*.
A*cat*meow

## Blockquotes with Multiple Paragraphs

> Dorothy followed her through many of the beautiful rooms in her castle.
> The Witch bade her clean the pots and kettles and sweep the floor and keep the fire fed with wood.

## Ordered Lists

1. First item
2. Second item
3. Third item
4. Fourth item

## Unordered Lists

* First item
* Second item
* Third item
* Fourth item

## Code / Code Blocks

Code blocks are normally indented four spaces or one tab. 

    <html>
      <head>
        <title>Test</title>
      </head>

```
<html>
  <head>
    <title>Test</title>
  </head>
```

`<html>`
`  <head>`
`    <title>Test</title>`
`  </head>`

When they’re in a list, indent them eight spaces or two tabs.

1.  Open the file.
2.  Find the following code block on line 21:

        <html>
          <head>
            <title>Test</title>
          </head>

3.  Update the title to match the name of your website.

### Syntax highlighting

<https://en.support.wordpress.com/code/posting-source-code/>

```css
#button {
    border: none;
}
```

```sql
select * from dual;
```

~~~sql
select * from dual;
~~~

## Images / Linking Images

![Tux, the Linux mascot](/assets/images/tux.png)

![Philadelphia's Magic Gardens. This place was so cool!](/assets/images/philly-magic-gardens.jpg "Philadelphia's Magic Gardens")

[![An old rock in the desert](/assets/images/shiprock.jpg "Shiprock, New Mexico by Beau Rogers")](https://www.flickr.com/photos/beaurogers/31833779864/in/photolist-Qv3rFw-34mt9F-a9Cmfy-5Ha3Zi-9msKdv-o3hgjr-hWpUte-4WMsJ1-KUQ8N-deshUb-vssBD-6CQci6-8AFCiD-zsJWT-nNfsgB-dPDwZJ-bn9JGn-5HtSXY-6CUhAL-a4UTXB-ugPum-KUPSo-fBLNm-6CUmpy-4WMsc9-8a7D3T-83KJev-6CQ2bK-nNusHJ-a78rQH-nw3NvT-7aq2qf-8wwBso-3nNceh-ugSKP-4mh4kh-bbeeqH-a7biME-q3PtTf-brFpgb-cg38zw-bXMZc-nJPELD-f58Lmo-bXMYG-bz8AAi-bxNtNT-bXMYi-bXMY6-bXMYv)

Linked logo: [![alt text](/wp-smaller.png)]
(http://wordpress.com/ "Title")

## Horizontal Rules

***

---

## Links / Adding Titles

My favorite search engine is [Duck Duck Go](https://duckduckgo.com "The best search engine for privacy").

## URLs and Email Addresses

<https://www.markdownguide.org>
<fake@example.com>

## Escaping Characters

To display a literal character that would otherwise be used to format text in a Markdown document, add a backslash (\) in front of the character.

\* Without the backslash, this would be a bullet in an unordered list.

## Footnotes

I have more [^1] to say up here.

[^1]: To say down here.

## Abbreviations

Markdown converts text to HTML.
Definitions can be anywhere in the document.

*[HTML]: HyperText Markup Language


## Table

---
layout: single
title: "sql练习"
subtitle: "取题sql-ex网站"
date: 2016-6-22
author: "Anyinlover"
category: 实践
tags:
  - SQL
---
