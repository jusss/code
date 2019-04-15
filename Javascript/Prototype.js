Array.prototype.add =
    function(x) {
        var results = [];
        for (var i=0; i < this.length; i++) {
            results.push(this[i] + x)
        }
        return results;
    }

[1,2,3].add(5)
Array [ 6, 7, 8 ]

//change the prototype, and it has affect all the linked object, OO based on prototype
//change the super-class, it won't change the created object, OO based on class

// in python, constructor is __new__
//in js, constructor is

class Whatever {
    constructor(init_value) {
        this.value = init_value
    }
    add(x){
        return this.value + x
    }
}

n = new Whatever(9);
n.add(3)

//before ES6, same as
var Whatever = function(init_value) {
    this.value = init_value;
    this.add = function(x) {
        return this.value + x
    }
 }

n = new Whatever(9);
n.add(3)

//https://www.w3schools.com/js/js_object_constructors.asp
//https://www.quora.com/What-is-a-constructor-in-JavaScript

