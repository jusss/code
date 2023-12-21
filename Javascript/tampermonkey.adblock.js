// ==UserScript==
// @name         adblocker
// @namespace    http://tampermonkey.net/
// @version      2023-12-21
// @description  try to take over the world!
// @author       You
// @match        https://a.b/*
// @icon         data:image/gif;base64,R0
// @grant        none
// ==/UserScript==

setTimeout(function() {
    'use strict';
var d1 = document.querySelectorAll(".pgutzbbe_b").forEach(el => el.remove());
var d2 = document.querySelectorAll(".tewuijqa_b").forEach(el => el.remove());

var l1 = ["0", "7.96875", "15.9375", "23.90625"].map(b => ["0","10","20","30","40","50","60","70","80","90"].map(_ => "\"position:fixed; bottom:" + b + "vw; left:" + _ + "vw; z-index:100;display:block;width:9.6vw;height:7.96875vw;background: #000;opacity:0.01;\"").map(s => 'div[style=' + s + ']').map(d => document.querySelector(d)).map(e => e.remove()));

var l2 = ["0", "7.96875", "15.9375", "23.90625"].map(b => ["0","10","20","30","40","50","60","70","80","90"].map(_ => "\"position:fixed; top:" + b + "vw; left:" + _ + "vw; z-index:100;display:block;width:9.6vw;height:7.96875vw;background:#000;opacity:0.01;\"").map(s => 'div[style=' + s + ']').map(d => document.querySelector(d)).map(e => e.remove()));

    // Your code here...
},3600)
