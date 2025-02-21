#sdf
import json
import boto3

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('visitorCounter')



def lambda_handler(event, context):
    response = table.get_item(Key={'id': 'counter'})
    count = response.get('Item', {}).get('count', 0)
    new_count = count + 1
    table.put_item(Item={'id': 'counter', 'count': new_count})
    return {
        'statusCode': 200,
        'headers': {
        "Access-Control-Allow-Origin": "*"
    },
    'body': json.dumps({'count': int(new_count)})  # Convert Decimal to int
    }
