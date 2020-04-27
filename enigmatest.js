// By Christof Schwarz, csw@qlik.com, April 4 2020
// -> replace constant "hostname" 
// -> replace constant "bearer" with the token that corresponds to the right user
// To get a bearer, use createjwt.js 
// requires the following npm modules:
// npm install fs ws https enigma.js

const enigma = require('./node_modules/enigma.js/enigma.min.js');
const WebSocket = require('ws');
const https = require('https');
//const fs = require('fs');
const schema = require('./node_modules/enigma.js/schemas/12.170.2.json');
// match this schema to your Qlik Sense version.
const bearer = 'eyJ....';
const hostname = 'qlik-shared-vm.q-nnect.net';
const debugInfo = true;
const session = enigma.create({
    schema,
    url: `wss://${hostname}/api/engine/openapi/rpc`,
    createSocket: url => new WebSocket(url, {
        rejectUnauthorized: false,
        headers: {
            "Authorization": 'Bearer ' + bearer
        }
    })
});

var defaultOptions = {
    method: "GET",
    hostname: hostname,
    port: 443,
    //path: "/api/v1/users",
    headers: {
        Authorization: "Bearer " + bearer,
        "content-type": "application/json"
    },
    rejectUnauthorized: false
    };

function qlikApi(moreOptions, requestBody, returnMsg){
    // Generic function to talk to Qlik Sense QSEoK API and return a promise.
    // It takes 1-3 params:
    // options object: {method:'GET', path:'/api/v1/tenants'} will be merged with the defaultOptions
    // sendJson (optional): a requestBody to be sent (for some POST, PUT ... requests)
    // returnMsg: a text be returned when the Promise resolves (instead of an object)

    return new Promise(function(resolve, reject) {
        var options = Object.assign(defaultOptions, moreOptions);
        if (debugInfo) console.log(options);
        var resultObj = { statusCode: null }; //, path: options.path };
        var req = https.request(options, function(res) {
            var chunks = [];
            resultObj.statusCode = res.statusCode;
            res.on('data', function(chunk) {
                chunks.push(chunk);
            });
            res.on('end', function () {
                var body = Buffer.concat(chunks);
                try {
                    resultObj.json = JSON.parse(body);
                    resolve(returnMsg?returnMsg:resultObj);
                }
                catch(err) {
                    if (body.length > 0) { resultObj.body = '' + body };
                    if (res.statusCode >= 400) { reject(resultObj) }
                    else { resolve(returnMsg?returnMsg:resultObj) }
                }
            });
            res.on('error', function(e) {
                //console.error("Got error from https call:", e.message);
                resultObj.body = e.message;
                reject(resultObj);
            });
        });
        if (requestBody) req.write(requestBody);
        req.end();
    })
}

function S4() {
    return (((1+Math.random())*0x10000)|0).toString(16).substring(1);
}

function getGuid() {
    // stitch in '4' in the third group
    return (S4() + S4() + "-" + S4() + "-4" + S4().substr(0,3) + "-" + S4() + "-" + S4() + S4() + S4()).toLowerCase();
}
// ------------------------------------------------------------------------
//               MAIN CODE
// ------------------------------------------------------------------------

var currDate = (new Date()).getFullYear()+("0"+((new Date()).getMonth()+1)).substr(-2)+("0"+((new Date()).getDate())).substr(-2);
var currTime = (new Date()).toTimeString().split(' ')[0].replace(':','').replace(':','');

// some global variables
var newAppId;
var appHandle;
var newDataConn;
var engineApi;

var requestBody = JSON.stringify({
    //attributes: {name: "My app 23", spaceId: "5db89c99dea1e20001c44a25"}
    attributes: {
        name: "My app " + currDate + " " + currTime,
        description: "bla bla"
    }
});
qlikApi({method:'POST', path:'/api/v1/apps'}, requestBody)
.then(function(result){

    newAppId = result.json.attributes.id;
    console.log('App created: ' + newAppId);
    // Re-map several of the attributes of the response body (Json) into another request body
    var requestBody = JSON.stringify({
        resourceType: "app",
        resourceId: result.json.attributes.id,
        name: result.json.attributes.name,
        description: result.json.attributes.description,
        resourceCreatedAt: result.json.attributes.createdDate,
        resourceCreatedBySubject: result.json.attributes.owner,
        resourceAttributes: result.json.attributes,
        resourceCustomAttributes: {}
    });
    // the new app won't be visible until this post request ...
    return(qlikApi({method:'POST', path:'/api/v1/items'}, requestBody, 'app successfully added.'))
}).then(function(result){
    console.log(result);
    var newGuid = getGuid();
    var requestBody = JSON.stringify({
        datasourceID: "rest",
        qName: "My new data conn " + currDate + " " + currTime,
        owner: newAppId,
        qType: "QvRestConnector.exe",
        qArchitecture: 0,
        qConnectStatement: "CUSTOM CONNECT TO \"provider=QvRestConnector.exe;url=https://jsonplaceholder.typicode.com/posts/1;timeout=30;method=GET;httpProtocol=1.1;isKeepAlive=true;bodyEncoding=UTF-8;sendExpect100Continue=true;autoDetectResponseType=true;checkResponseTypeOnTestConnection=true;keyGenerationStrategy=0;authSchema=anonymous;skipServerCertificateValidation=false;addMissingQueryParametersToFinalRequest=false;PaginationType=None;allowResponseHeaders=false;allowHttpsOnly=false;useProxy=false;proxyBypassOnLocal=false;proxyUseDefaultCredentials=true;\"",
        qEngineObjectID: newGuid,
        qID: newGuid,
        qLogOn: 1,
        qUsername: "",
        qPassword: ""
    });
    return(qlikApi({method:'POST', path:'/api/v1/dataconnections'}, requestBody));
}).then(function(result){
    console.log('Data connection created');
    console.log(result);
    newDataConn = result.json.qName;
    return session.open();
}).then(function (global) {
    console.log('Connected to Engine API');
    engineApi = global;
    return engineApi.engineVersion();
}).then(function(ret){
    console.log(ret);
    return engineApi.openDoc(newAppId);
}).then(function(doc){
    console.log('App is open ' + newAppId);
    appHandle = doc;
    const loadScript = `
    LIB CONNECT TO '${newDataConn}';
    RestConnectorMasterTable:
    SQL SELECT
        "userId",
        "id",
        "title",
        "body"
    FROM JSON (wrap on) "root";
    `;
    return appHandle.setScript(loadScript);
}).then(function(ret) {
    console.log('Load script updated. Next: save app ...');
    return appHandle.doSave();
}).then(function(ret) {
    console.log('App saved. Next: reload app ...');
    return appHandle.doReload(0, false); // false = Full Reload
}).then(function(ret){
    console.log('app finished reload. Next: save app again ...');
    return appHandle.doSave();
}).then(function(ret){
    console.log('App saved. Next: Close session.');
    session.close();
}).catch(function(err){
    console.log('Error', err);
    try { session.close(); } catch(error) {};
});
