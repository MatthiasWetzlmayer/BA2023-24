const jwt = require('jsonwebtoken');
const jwksClient = require('jwks-rsa');
const fetch = require("node-fetch");
const util = require('util') 

exports.handler = async (event) => {
    var token = event.Authorization;
    const jwksUri = "https://cognito-idp.eu-central-1.amazonaws.com/eu-central-1_aUy4duruG/.well-known/jwks.json" 

    const getKey = (jwksUri) => (header, callback) => {
    const client = jwksClient({jwksUri});
    client.getSigningKey(header.kid, (err, key) => {
        if (err) {
        return callback(err);
        }
        callback(null, key.publicKey || key.rsaPublicKey);
    });
    };

    //const token = 'eyJraWQiOiJ6Nyt5XC9xTVVaMTc3dnFUeThqcU5vaVhtMnVwTU9kYjVUd0pYVUMrY09kRT0iLCJhbGciOiJSUzI1NiJ9.eyJzdWIiOiJmZTQwOTA5MC1hNWM1LTQwY2MtOGQ0MC1kMDQ0YWQ1OTIwZWIiLCJlbWFpbF92ZXJpZmllZCI6dHJ1ZSwiaXNzIjoiaHR0cHM6XC9cL2NvZ25pdG8taWRwLmV1LWNlbnRyYWwtMS5hbWF6b25hd3MuY29tXC9ldS1jZW50cmFsLTFfYVV5NGR1cnVHIiwiY29nbml0bzp1c2VybmFtZSI6Ik1hdHRoaWFzIiwib3JpZ2luX2p0aSI6IjIzOTMxMWU2LTJmZmYtNGJhOS1hZWU5LWQ2ZjkzNzgwNTI2YSIsImF1ZCI6InZuN3UyYTlsanM4MDZkbG5sNWlkMWsxZjAiLCJldmVudF9pZCI6ImIwYjc0ZDhjLTMxMGYtNGNhNS1hYjUzLWM1YTg1OTE4ODNjNyIsInRva2VuX3VzZSI6ImlkIiwiYXV0aF90aW1lIjoxNzA0MjIwMDg4LCJleHAiOjE3MDQyMjM2ODgsImlhdCI6MTcwNDIyMDA4OCwianRpIjoiMzM1ZDRlYWMtMTQyYy00N2IzLWFiOTktZmE3OTFkMDgyYjNlIiwiZW1haWwiOiJtd2V0emxtQGdtYWlsLmNvbSJ9.WHUWSvwiod3S6PnrMEssa8gYnFal8hZ873pv2ICLtOL_HMpwoiLacfDkr-wPAbhQBIMlOCpgGXYdF4ccOVOcu4QdM-c5JX2b2FwxskYBAermpC-paK8cpufssodbz0zru6RLYD6dS2i3FeGDUbc5d1Ds_Myn7_XzDfjFCcInoDXyfE6PYpK4dqSGCVWsSvtfBdujrxfr8Nd7LKkuZt_iVAc1CtcfDYe52xmHVAKkSrgan8mM8CZB35h3BGr7FzxBBB7vYUBCZjV9ZLno7ED2GpVZlV71UOPvPJ15XaPNwveiVJjmFHk9sgacg_QM-ApuRo-JCYwgD-OjyDFsO0_QIg';

    const verify = async token => {
    //const {iss: issuer} = jwt.decode(token);
        return util.promisify(jwt.verify)(token, getKey(jwksUri));
    };

    try{
        await verify(token);
        decodedToken = jwt.decode(token);
        username = decodedToken['cognito:username']
        console.log('Token verified successfully.');
        return generatePolicy('user', 'Allow', event.methodArn, username)

    }catch(err){
        return generatePolicy('user', 'Deny', event.methodArn, "")

    }
}

var generatePolicy = function(principalId, effect, resource, username) {
    var authResponse = {};
    
    authResponse.principalId = principalId;
    if (effect && resource) {
        var policyDocument = {};
        policyDocument.Version = '2012-10-17'; 
        policyDocument.Statement = [];
        var statementOne = {};
        statementOne.Action = 'execute-api:Invoke'; 
        statementOne.Effect = effect;
        statementOne.Resource = resource;
        policyDocument.Statement[0] = statementOne;
        authResponse.policyDocument = policyDocument;
    }
    
    authResponse.context = {
        "username": username
    };
    return authResponse;
}