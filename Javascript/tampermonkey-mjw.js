// ==UserScript==
// @name         x
// @namespace    http://tampermonkey.net/
// @version      2023-12-21
// @description  try to take over the world!
// @author       You
// @match        https://x.vip/*
// @match        https://x.tv/*
// @icon         data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==
// @grant        none
// ==/UserScript==

setTimeout(function() {
    'use strict';
    [".CFLki",".zyhCi",".pgutzbbe_b",".tewuijqa_b", "lavbxmip_b", "vesnslnf_b", "tkocroml_b", "YHVzi_0_0", "EMpXdji_0_1"].map(c => document.querySelectorAll(c).forEach(el => el.remove()));

    ["0", "7.96875", "15.9375", "23.90625"].map(b => ["0","10","20","30","40","50","60","70","80","90"].map(_ => "\"position:fixed; bottom:" + b + "vw; left:" + _ + "vw; z-index:10;display:block;width:9.6vw;height:7.96875vw;background: #000;opacity:0.01;\"").map(s => 'div[style=' + s + ']').map(d => document.querySelector(d)).map(e => e.remove()));

    ["0", "7.96875", "15.9375", "23.90625"].map(b => ["0","10","20","30","40","50","60","70","80","90"].map(_ => "\"position:fixed; top:" + b + "vw; left:" + _ + "vw; z-index:10;display:block;width:9.6vw;height:7.96875vw;background:#000;opacity:0.01;\"").map(s => 'div[style=' + s + ']').map(d => document.querySelector(d)).map(e => e.remove()));

    ["top", "bottom"].map(p => ["0","30","60","90"].map(t => ["0","152.9","305.8","458.7","611.6","764.5","917.4","1070.3","1223.2","1376.1"].map( l => "\"height: 30px; " + p + ": " + t + "px; left: " + l + "px; background-position: -" + l + "px 0px; background-size: 1529px 120px !important;\"").map(s => 'div[style=' + s + ']').map(d => document.querySelector(d)).map(e => e.remove())));

    ["top", "bottom"].map(p => ["0","10","20","30","40","50","60","70","80","90"].map(l => "\"display: block; position: fixed; width: 10%; left: " + l + "vw; border: none; z-index: 2147483646; height: 0px; " + p + ": 120px;\"").map(s => 'div[style=' + s + ']').map(d => document.querySelector(d)).map(e => e.remove()));


    // Your code here...
},1600)
