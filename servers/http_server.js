var http = require("http");
var server = http.createServer(function(request, response) {
  response.writeHead(200, {"Content-Type": "text/html"});
  response.end("Hello World\n");
});

server.listen(process.argv[2]);
console.log("Server is listening at " + process.argv[2]);
