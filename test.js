var names = ["Max", "Alice", "Bob"]
names.forEach(function(name){console.log("Hello "+name)})

function lowerCase(str){return str.toLowerCase()}
names.map(function(e){return lowerCase(e)}).filter(function(e){return !!e}).forEach(function(e){console.log(e)})
