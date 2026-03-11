import '../models/customer.dart';
import '../models/Driver.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';

import '../shared/constants.dart';
// snake case tools is the tools that is editable have dialogs

const String addShipmentToolName = 'add_shipment';
const String assignDriverToolName = 'assignDriver';
const String getOrdersInfoToolName = 'getOrdersInfo';

FunctionDeclaration addShipmentTool(
        {List<String>? cities,
        List<Customer>? customers,
        List<Driver>? drivers}) =>
    FunctionDeclaration(addShipmentToolName,
        'Add a new shipment to the system or edit an existing shipment. Use this when the user wants to create a new delivery shipment or edit an existing one.',
        parameters: {
 
          'recipientName': Schema.string(
            description: 'Name of the person receiving the shipment.',
            nullable: true,
          ),
          'phoneNumber': Schema.string(
            description:
                'Contact phone number for the recipient required parameter.',
          ),
          'city': Schema.string(
            description:
                'Destination city for the shipment should be one of the following: ${cities?.join(', ')}',
          ),
          'addressDescription': Schema.string(
            description: 'Detailed description of the delivery address.',
            nullable: true,
          ),
          'paymentMethod': Schema.string(
            description:
                'Method of payment for the shipment should be one of the following: ${paymentMethods.join(', ')} if not provided return the frist one',
            nullable: true,
          ),
          'collectionMethod': Schema.string(
            description:
                'Method of collecting the shipment should be one of the following: ${collectionMethods.join(', ')} if not provided return the frist one',
            nullable: true,
          ),
          'codAmount': Schema.number(
            description: 'Cash on delivery amount if applicable.',
          ),
          'serviceType': Schema.string(
            description:
                'Type of delivery service requested should be one of the following: ${serviceTypes.join(', ')} if not provided return the frist one',
            nullable: true,
          ),
          'contents': Schema.string(
            description: 'Description of the shipment contents.',
            nullable: true,
          ),
          'weight': Schema.number(
            description: 'Weight of the shipment in kilograms.',
            nullable: true,
          ),
          'parcelCount': Schema.number(
            description: 'Number of parcels in this shipment.',
            nullable: true,
          ),
          'notes': Schema.string(
            description:
                'Additional notes or special instructions for the shipment.',
            nullable: true,
          ),
          'deliveryCost': Schema.number(
            description:
                'Cost of delivery service make sure it cleary specified if not return null.',
            nullable: true,
          ),
          'expectedDeliveryDate': Schema.string(
            description: 'Expected date of delivery in ISO 8601 format.',
            nullable: true,
            format: '2025-01-01',
          ),
          "customer": Schema.object(
            description:
                'Customer use one of the feild provided (userphone,username,userId) to search for the customer in this list and return the customer object: [${customers?.map((e) => {
                      "userphone": e.phoneNumber,
                      "username": e.username,
                      "userId": e.userid,
                    }).join(', ')}] if no feilds provided return prompt to the user using dropdownMessage tool to select the customer from the list (List of username)',
            properties: {
              "userphone": Schema.string(
                  description: 'Phone number of the customer', nullable: true),
              "username": Schema.string(description: 'Name of the customer'),
              "userId": Schema.string(description: 'ID of the customer'),
            },
          ),
          'driver': Schema.object(
            description:
                'Driver use one of the feild provided (driverId,driverName) from the user to search for the driver in this list and return the driver object: [${drivers?.map((e) => {
                      "driverId": e.userid,
                      "driverName": e.username,
                    }).join(', ')}]',
            properties: {
              "driverId": Schema.string(description: 'ID of the driver'),
              "driverName": Schema.string(description: 'Name of the driver'),
            },
            nullable: true,
          ),
        },
        optionalParameters: [
          'orderId',
          'recipientName',
          'phoneNumber',
          'addressDescription',
          'collectionMethod',
          'parcelCount',
          'deliveryCost',
          "driver",
          "contents",
          "weight",
          "notes",
          "expectedDeliveryDate",
        ]);

FunctionDeclaration assignDriverTool({List<Driver>? drivers}) =>
    FunctionDeclaration(
      assignDriverToolName,
      'Assign a driver to a shipment. Use this when the user wants to assign a driver to a shipment that you have its id.',
      parameters: {
        'driver': Schema.object(
          description:
              'Driver use one of the feild provided (driverId,driverName) from the user to search for the driver in this list and return the driver object: [${drivers?.map((e) => {
                    "driverId": e.userid,
                    "driverName": e.username,
                  }).join(', ')}]',
          properties: {
            "driverId": Schema.string(
                description:
                    'ID of the driver required parameter cant be null or empty'),
            "driverName": Schema.string(description: 'Name of the driver'),
          },
        ),
        "orderId": Schema.string(description: 'Order ID of the shipment'),
      },
    );

FunctionDeclaration getOrdersInfoTool() => FunctionDeclaration(
      getOrdersInfoToolName,
      'use this tool to query the orders in the system and return the orders info',
      parameters: {
        'status': Schema.string(
            description:
                'Status of the orders should be one of the following: ${statusOptions.keys.join(', ')}',
            ),
        'driverId': Schema.string(description: 'Driver ID of the orders'),
        'customerId': Schema.string(description: 'Customer ID of the orders'),
        'phoneNumber': Schema.string(description: 'Phone number of the recipient'),
      },
      optionalParameters: [
        'status',
        'driverId',
        'customerId',
        'phoneNumber',
      ],
    );

    
