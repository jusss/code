t=()=>console.log(1);
stopButton = false;
f = function () {
    return new Promise((r,e) => {t(); setTimeout(r,3000) })
        .then( _ => { if (stopButton) {return }
                      else f();
                    })}

// run
//f()

//stop
//stopButton=true

alist = [1,2,3]
stopButton = false
alist.map( (e,i) => {
    setTimeout( _ => console.log(e), i*3000)})

f = function (n) {
    return new Promise((r,e) => {
        setTimeout(r, 3000)})
        .then( () => {
            if ( (n+1) > alist.length) { return 0}
            else { console.log(alist[n]) ; return (n+1)}
        })
        .then(
            t => { if (stopButton) { stopButton = false; return 0}
                      else {f(t)}})
}

f(0)

//image that f(0) is retrun a new Promise(), that new Promise() will run when it's been created, and then in the last of Promise(), it return a new Promise(), just image Promise() like a snake or whatever else, when it runs to its tail, it will create a new snake, and the old one will disappear, 

f = function (n) {
    return new Promise((r,e) => {
         setTimeout(r, 3000)})
        .then( () => {
            if ( (n+1) > alist.length) { return 0}
            else { console.log(alist[n]) ; return (n+1)}
        })
        .then(
            t => { if (stopButton) { stopButton = false; return 0}
                      else {f(t)}})
}

g = _ => {console.log(alist[0]); f(1)}


//

delay = function(time,value) {
      return new Promise(function(resolve){
      	  setTimeout(function() {resolve(vlaue)}, time)})};

delay = function(t) {
      return new Promise(function(resolve){
      	  setTimeout(function() {resolve(t)}, t)})};
//////////////////////////////////////////////////////////////
alist=[1,2,3]
stopButton=false

f = function (n) {
    return new Promise((r,e) => {
        console.log(alist[n])
        setTimeout( _ => {r(n+1)}, 3000)})
        .then( _ => {
            if ( _+1 > alist.length) { return 0}
            else { console.log(alist[_]) ; return (_+1)}
        })
        .then(
            _ => { if (stopButton) { stopButton = false; return 0}
                   else {
                       new Promise((r,e) => {
                           setTimeout(r, 3000)})
                       .then(
                           whatever=>{f(_)})}})
}

f(0)

        
