const AWS = require('aws-sdk');
const jwt = require('jsonwebtoken');
const dynamoDB = new AWS.DynamoDB.DocumentClient();

exports.handler = async (event) => {
  console.log(JSON.stringify(event.requestContext.authorizer.claims))
  try {
    sub = event.requestContext.authorizer.claims.sub;
    body = JSON.parse(event.body);
    path = event.path; 
    if(path.startsWith("/sensor")&&event.pathParameters&&event.pathParameters.id){
      isOwnedByUser = await isSensorOwnedByUser(event.pathParameters.id, sub);
      if(isOwnedByUser.statusCode >200){
        return isOwnedByUser;
      }
      sensor = isOwnedByUser.body;

      if (event.httpMethod == 'POST') {
        let item = {
          id: event.requestContext.requestId,
          sensor_name: event.pathParameters.id,
          ...body
        }

        const params = {
          TableName: "sensor-data-table",
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
      }else if (event.httpMethod == 'DELETE') {
        itemToDelete = sensor;
        params = {
          TableName: 'sensor-table', 
          Key: {
            sensor_name: event.pathParameters.id 
          }
        }
        await dynamoDB.delete(params).promise();
        delete itemToDelete.sub_string
        return {
          statusCode: 200,
          body: JSON.stringify(itemToDelete)
        };
      }else if (event.httpMethod == 'GET'){
        try{
          const querySensorDataParams = {
            TableName: 'sensor-data-table',
            IndexName: 'name-gsi',
            KeyConditionExpression: 'sensor_name = :sensorName',
            ExpressionAttributeValues: {
              ':sensorName': event.pathParameters.id
            }
          };
    
          const sensorDataResult = await dynamoDB.query(querySensorDataParams).promise();
          console.log(sensorDataResult.Items);
          return {
            statusCode: 200,
            headers: {
              "Content-Type": "application/json", // HTTP-Header
            },
            body: JSON.stringify(sensorDataResult.Items.map(x =>x.data))
          };
        }catch(err){
          console.log(err)
          return {
            statusCode: 400,
            headers: {
              "Content-Type": "application/json", // HTTP-Header
            },
            body: JSON.stringify({ error: err })
          }
        }
        
      }  
    }else{
      if (event.httpMethod == 'POST') {
        isOwnedByUser = await isSensorOwnedByUser(body.sensor_name, sub);
        if(isOwnedByUser.statusCode == 401){
          return isOwnedByUser;
        }
      sensor = isOwnedByUser.body;
        let item = {
          sensor_name: body.sensor_name,
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
      }
    }

      // Für andere Typen von event.type eine Fehlermeldung zurückgeben
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Ungültiger event.type' })
      };
    
  } catch (error) {
    console.log(error)
    return {
      statusCode: 500,
      error: JSON.stringify(error),
      body: JSON.stringify({ error: 'Fehler aufgetreten' })
    };
  }
};

async function isSensorOwnedByUser(sensorId, subString) {
  params = {
    TableName: 'sensor-table', 
    KeyConditionExpression: 'sensor_name = :sensor_name', 
    ExpressionAttributeValues: { 
      ':sensor_name': sensorId 
    }
  };

  data = await dynamoDB.query(params).promise();
  if(data.Items.length == 0){
    return{
      statusCode: 400,
      body: "Object does not exist"
    }
  }
  item = data.Items[0]
  if(item.sub_string != subString){
    return {
      statusCode: 401,
      body: "Unauthorized"
    }
  }
  return {
    statusCode: 200,
    body: item
  }
}
