/*
To create the keys
openssl genrsa -out key.pem
openssl req -new -key key.pem -out csr.pem
openssl x509 -req -days 9999 -in csr.pem -signkey key.pem -out cert.pem
rm csr.pem
*/

var https = require('https');
var fs = require('fs');

var options = {
  key: fs.readFileSync('key.pem'),
  cert: fs.readFileSync('cert.pem')
};
var a = https.createServer(options, function (req, res) {
  res.writeHead(200);
  res.end("hello world\n");
}).listen(process.argv[2]);

console.log("Server is listening at " + process.argv[2]);
