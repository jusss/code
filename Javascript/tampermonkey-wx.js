// ==UserScript==
// @name         x
// @namespace    http://tampermonkey.net/
// @version      2024-08-25
// @description  try to take over the world!
// @author       You
// @match        https://www.x.com/*
// @icon         https://www.google.com/s2/favicons?sz=64&domain=x.com
// @grant        none
// ==/UserScript==

setTimeout(function() {
    'use strict';

    ["0", "8.5", "17", "25.5"].map(b => ["0","10","20","30","40","50","60","70","80","90"].map(_ => "\"position:fixed; top:" + b + "vw; left:" + _ + "vw; z-index:100;display:block;width:9.6vw;height:8.5vw;background:#000;opacity:0.01;\"").map(s => 'div[style=' + s + ']').map(d => document.querySelector(d)).map(e => e.remove()));


    ["0", "8.5", "17", "25.5"].map(b => ["0","10","20","30","40","50","60","70","80","90"].map(_ => "\"position:fixed; bottom:" + b + "vw; left:" + _ + "vw; z-index:100;display:block;width:9.6vw;height:8.5vw;background:#000;opacity:0.01;\"").map(s => 'div[style=' + s + ']').map(d => document.querySelector(d)).map(e => e.remove()));


    // Your code here...
},3600)
