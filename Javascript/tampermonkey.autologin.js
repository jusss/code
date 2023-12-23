// ==UserScript==
// @name         auto login
// @namespace    http://tampermonkey.net/
// @version      2023-12-23
// @description  try to take over the world!
// @author       You
// @match        https://x/login?*
// @icon         none
// @grant        none
// ==/UserScript==

setTimeout(function sendData(data){
    const formData = new FormData();
    formData.append("username","");
    formData.append("password","");
    formData.append("from",document.forms[0]["from"]["value"]);
    formData.append("login","login");
    fetch("x/login",{
        method: "POST",
        body: formData,
        });
        }, 1600)
