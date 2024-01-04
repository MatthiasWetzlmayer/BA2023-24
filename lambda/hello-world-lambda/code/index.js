const AWS = require('aws-sdk');
const jwt = require('jsonwebtoken');
const dynamoDB = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  console.log(JSON.stringify(event.requestContext.authorizer.claims))
  try {
    sub = event.requestContext.authorizer.claims.sub;
    body = JSON.parse(event.body)
    if (event.httpMethod == 'POST') {
      // PUT-Operation ausführen, wenn event.type == PUT
      let item = {
        id: event.requestContext.requestId,
        sub_string: sub,
        ...body
      }
      const params = {
        TableName: "sensor-table",
        Item:item
      }
      await dynamoDB.put(params).promise();
      delete item.sub_string;
      return {
        statusCode: 200,
        headers: {
          "Content-Type": "application/json", // HTTP-Header
        },
        body: JSON.stringify(item)
      };
    } else if (event.httpMethod == 'DELETE') {
      // DELETE-Operation ausführen, wenn event.type == DELETE
      params = {
        TableName: 'sensor-table', 
        KeyConditionExpression: 'id = :id', 
        ExpressionAttributeValues: { 
          ':id': event.pathParameters.id 
        }
      };

      data = await dynamoDB.query(params).promise();
      if(data.Items.length == 0){
        return{
          statusCode: 400,
          body: "Object does not exist"
        }
      }
      itemToDelete = data.Items[0]
      if(!itemToDelete.sub_string == sub){
        return {
          statusCode: 401,
          body: "Unauthorized"
        }
      }
      params = {
        TableName: 'sensor-table', 
        Key: {
          id: event.pathParameters.id 
        }
      }
      await dynamoDB.delete(params).promise();
      delete itemToDelete.sub_string
      return {
        statusCode: 200,
        body: JSON.stringify(itemToDelete)
      };
    } else {
      // Für andere Typen von event.type eine Fehlermeldung zurückgeben
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Ungültiger event.type' })
      };
    }
  } catch (error) {
    console.log(error)
    return {
      statusCode: 500,
      error: JSON.stringify(error),
      body: JSON.stringify({ error: 'Fehler aufgetreten' })
    };
  }
};
