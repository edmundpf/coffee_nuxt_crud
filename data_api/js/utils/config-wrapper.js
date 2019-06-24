var app_routes, corsPort, databaseName, getRoutes, list_methods, list_routes, models, mongoosePort, normal_methods, normal_routes, route_methods, routes, schemaConfig, schemaInfo, secretKey, serverConfig, serverPort, userAuth;

models = require('../models');

schemaConfig = require('../../config/schema-config.json');

serverConfig = require('../../config/server-config.json');

//: Special Models
userAuth = models.userAuth;

secretKey = models.secretKey;

//: Config
serverPort = serverConfig.serverPort;

corsPort = serverConfig.corsPort;

mongoosePort = serverConfig.mongoosePort;

databaseName = serverConfig.databaseName;

//: Route Methods
list_methods = ['set', 'push', 'push_unique'];

normal_methods = ['insert', 'update', 'delete', 'delete_all', 'get', 'get_all', 'sterilize', 'schema'];

route_methods = [...normal_methods, ...list_methods];

//: Get Schema Info
schemaInfo = function(model, primary_key) {
  var key, list_keys, schema, value;
  schema = model.schema.paths;
  list_keys = [];
  for (key in schema) {
    value = schema[key];
    if ((value.$isMongooseArray != null) && value.$isMongooseArray) {
      list_keys.push(key);
    }
  }
  return {
    schema: Object.keys(schema),
    primary_key: primary_key,
    list_fields: list_keys
  };
};

//: Get Routes
getRoutes = function() {
  var key, list_routes, normal_routes, primary_key, route_info, schema_info, schemas;
  list_routes = {};
  normal_routes = {};
  schemas = Object.keys(models);
  for (key in models) {
    primary_key = schemaConfig[key].primary_key;
    schema_info = schemaInfo(models[key], primary_key);
    route_info = {
      model: models[key],
      primary_key: primary_key,
      list_fields: schema_info.list_fields
    };
    if (schema_info.list_fields.length > 0) {
      list_routes[schemaConfig[key].path] = route_info;
    } else {
      normal_routes[schemaConfig[key].path] = route_info;
    }
  }
  return {
    list: list_routes,
    normal: normal_routes
  };
};

//: Routes
routes = getRoutes();

list_routes = routes.list;

normal_routes = routes.normal;

app_routes = {...list_routes, ...normal_routes};

//: Exports
module.exports = {
  userAuth: userAuth,
  secretKey: secretKey,
  list_routes: list_routes,
  normal_routes: normal_routes,
  app_routes: app_routes,
  list_methods: list_methods,
  normal_methods: normal_methods,
  route_methods: route_methods,
  serverPort: serverPort,
  corsPort: corsPort,
  mongoosePort: mongoosePort,
  databaseName: databaseName,
  schemaInfo: schemaInfo
};

//::: End Program :::

//# sourceMappingURL=config-wrapper.js.map
