// Author: Christof Schwarz, christof.schwarz@qlik.com
//
// NodeJS app that creates and signs a jwt token for the person ("sub") provided as 
// command-line argument
// usage: 
// nodejs createjwt.js anyuser

var sub = process.argv[2];
var jwt = require('jsonwebtoken');
var fs = require('fs');
var privkey= fs.readFileSync(__dirname + '/certs/private.key');
var jwt_payload = {
    iss: "https://qlik.api.internal",
    aud: "qlik.api",
    sub: sub,
    groups : ["Everyone"],
    name: "Qlik API",
    exp: 1800000000
};
console.log(jwt.sign(jwt_payload, privkey, {
   algorithm:'RS256',
   noTimestamp:true,
   header:{"kid":"my-key-identifier"}
}));
