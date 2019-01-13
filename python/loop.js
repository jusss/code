alist=[[name,addr] , [name1,addr1]]

var condition=false

// use outside variable to control that loop
// js's setInterval has a problem, that is what if the inside executions have not yet done and the time is up?
// once click that button, then condition=true and call loop-function
//click button again, then condition=false
// name need waiting for pic
// think if while block ?
_loop = function() {
    while (condition) { f(alist) }}


