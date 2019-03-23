
hello = (function(self) {
	self.hello = function(world) {console.log(world)};
	 return self;

})(window.hello || {});
