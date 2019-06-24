var SECRET_KEY, allowedPassword, incorrectSecretKey, incorrectUserOrPass, jwt, noCurrentPass, objOmit, responseFormat, schemaAsync, schemaInfo, secretKey, signToken, updateQuery, userAuth, userNotFound, uuid, verifyToken;

uuid = require('uuid/v4');

jwt = require('jsonwebtoken');

schemaInfo = require('./config-wrapper').schemaInfo;

userAuth = require('./config-wrapper').userAuth;

secretKey = require('./config-wrapper').secretKey;

SECRET_KEY = uuid();

//: Omit Properties from Object and get Copy
objOmit = function(obj, keys) {
  var clone, i, key, len;
  clone = Object.assign({}, obj);
  for (i = 0, len = keys.length; i < len; i++) {
    key = keys[i];
    delete obj[key];
  }
  return clone;
};

//: Response/Error JSON
responseFormat = async function(method, args, req, res) {
  var err_json, error, response, ret_json;
  try {
    response = (await method(...args));
    ret_json = {
      status: 'ok',
      response: response
    };
    if (res.locals.refresh_token != null) {
      ret_json.refresh_token = res.locals.refresh_token;
    }
    return res.json(ret_json);
  } catch (error1) {
    error = error1;
    err_json = {
      status: 'error',
      response: error
    };
    if (res.locals.refresh_token != null) {
      err_json.refresh_token = res.locals.refresh_token;
    }
    return res.status(500).json(err_json);
  }
};

//: Update Query
updateQuery = function(req, primary_key) {
  var update_query;
  update_query = objOmit(req.query, [primary_key]);
  if (update_query.update_primary != null) {
    update_query[primary_key] = update_query.update_primary;
    update_query.update_primary = null;
  }
  return update_query;
};

//: Get Schema Info Async
schemaAsync = function(model, primary_key) {
  return Promise.resolve(schemaInfo(model, primary_key));
};

//: Incorrect Secret Key
incorrectSecretKey = function(res) {
  return res.status(401).json({
    status: 'error',
    response: {
      message: 'Incorrect secret key.',
      codes: ['INCORRECT']
    }
  });
};

//: Incorrect Username or Password JSON
incorrectUserOrPass = function(res) {
  return res.status(401).json({
    status: 'error',
    response: {
      message: 'Incorrect username or password.',
      codes: ['INCORRECT']
    }
  });
};

//: User Not Found JSON
userNotFound = function(res) {
  return res.status(401).json({
    status: 'error',
    response: {
      message: 'User does not exist.',
      codes: ['USER_NOT_FOUND']
    }
  });
};

//: No Current Password JSON
noCurrentPass = function(res) {
  return res.status(401).json({
    status: 'error',
    response: {
      message: 'Must include current password.',
      codes: ['NO_CURRENT_PASS']
    }
  });
};

//: Allowed Password Check
allowedPassword = function(req, res) {
  var error, error_codes, error_msg;
  error_msg = '';
  error_codes = [];
  if (req.query.username.length < 8) {
    error_msg += 'Username must be at least 8 characters. ';
    error_codes.push('USER_LENGTH');
  }
  if (req.query.password.length < 8) {
    error_msg += 'Password must be at least 8 characters. ';
    error_codes.push('PASS_LENGTH');
  }
  if (!/^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/.test(req.query.password)) {
    error_msg += 'Password must have at least 1 letter and at least 1 character. ';
    error_codes.push('PASS_CHAR');
  }
  if (error_msg.length > 0) {
    error_msg = error_msg.substring(0, error_msg.length - 1);
    error = {
      message: error_msg,
      codes: error_codes
    };
    return res.status(401).json({
      status: 'error',
      response: error
    });
  }
};

//: Sign JSON Web Token
signToken = function(user) {
  var access_token, expires_in;
  expires_in = 24 * 60 * 60;
  access_token = jwt.sign({
    username: user.username,
    uid: user.uid
  }, SECRET_KEY, {
    expiresIn: expires_in
  });
  return {
    username: user.username,
    uid: user.uid,
    access_token: access_token,
    expires_in: expires_in
  };
};

// Verify JSON Web Token
verifyToken = async function(req, res, next) {
  var get_all, token;
  if (req.params.path != null) {
    if (req.params.path === 'secret_key') {
      get_all = (await secretKey.find({}));
      if (get_all.length <= 0) {
        return next();
      }
    } else if (req.params.path === 'signup') {
      get_all = (await userAuth.find({}));
      if (get_all.length <= 0) {
        return next();
      }
    }
  }
  token = req.query.auth_token || req.headers['x-access-token'] || req.headers['authorization'];
  if (!token) {
    return res.status(401).json({
      status: 'error',
      response: {
        message: 'No token provided.'
      }
    });
  } else {
    jwt.verify(token, SECRET_KEY, function(error, decoded) {
      var current_time, expires_in, one_hour;
      current_time = Math.round(Date.now() / 1000);
      expires_in = 24 * 60 * 60;
      one_hour = 60 * 60;
      if (error) {
        return res.status(401).json({
          status: 'error',
          response: {
            message: 'Invalid token.'
          }
        });
      } else if (current_time < decoded.exp && current_time + expires_in > decoded.exp + one_hour) {
        res.locals.refresh_token = signToken(decoded);
        next();
      } else {
        next();
      }
    });
  }
};

module.exports = {
  objOmit: objOmit,
  responseFormat: responseFormat,
  schemaAsync: schemaAsync,
  updateQuery: updateQuery,
  incorrectUserOrPass: incorrectUserOrPass,
  userNotFound: userNotFound,
  noCurrentPass: noCurrentPass,
  allowedPassword: allowedPassword,
  signToken: signToken,
  verifyToken: verifyToken
};

//::: End Program :::

//# sourceMappingURL=data-api-functions.js.map
