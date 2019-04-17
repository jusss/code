window.onload=function(){

 id=['id1','id2','id3'];
 elementList = id.map(function(x){ return document.getElementById(x)});
 stopButton=false;

 forLoop = function (alist, n) {
     return new Promise(function(r,e) {

         alist[n].style.display="block";
         //console.log(alist[n]);
         setTimeout( function(){r(n)}, 3000)})
         .then( function(_) {
             alist[_].style.display="none" ;
             //   console.log(alist[_]);
             if ( _+1 >= alist.length) {return 0}
             return (_+1)
        })
        .then(
            function(_) {
                if (stopButton) { stopButton = false; return 0}
                else { forLoop(alist, _)}
            })
 }
    
//    g=forLoop(elementList,0)
}

//forLoop(elementList, 0)
