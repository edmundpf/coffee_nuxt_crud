var SALT_WORK_FACTOR, bcrypt, listCreate, saveEncrypt, updateEncrypt;

bcrypt = require('bcrypt');

SALT_WORK_FACTOR = 10;

//: Pre-Save hook to save CSV lists for array fields
listCreate = function(doc, fields) {
  var error, field, i, j, len, len1, val, vals;
  try {
    for (i = 0, len = fields.length; i < len; i++) {
      field = fields[i];
      vals = doc[field][0].split(',');
      doc[field] = [];
      for (j = 0, len1 = vals.length; j < len1; j++) {
        val = vals[j];
        doc[field].push(val);
      }
    }
  } catch (error1) {
    error = error1;
    return Promise.resolve({
      message: 'Could not set array field value.',
      errorMsg: error
    });
  }
  return Promise.resolve(doc);
};

//: Pre-Save hook to encrypt field
saveEncrypt = async function(doc, key) {
  var error, salt;
  if (!doc.isModified(key) && !doc.isNew) {
    return;
  }
  try {
    salt = (await bcrypt.genSalt(SALT_WORK_FACTOR));
    doc[key] = (await bcrypt.hash(doc[key], salt));
  } catch (error1) {
    error = error1;
    return {
      message: 'Could not create encrypted field.',
      errorMsg: error
    };
  }
  return doc;
};

//: Pre-Update hook to encrypt field
updateEncrypt = async function(query, key) {
  var error, salt;
  try {
    salt = (await bcrypt.genSalt(SALT_WORK_FACTOR));
    query[key] = (await bcrypt.hash(query[key], salt));
  } catch (error1) {
    error = error1;
    return {
      message: 'Could not update encrypted field.',
      errorMsg: error
    };
  }
  return query;
};

//: Exports
module.exports = {
  listCreate: listCreate,
  saveEncrypt: saveEncrypt,
  updateEncrypt: updateEncrypt
};

//::: End Program :::

//# sourceMappingURL=model-hooks.js.map
