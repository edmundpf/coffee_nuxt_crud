var autoIncrement, hooks, mongoose, secretKey;

mongoose = require('mongoose');

autoIncrement = require('mongoose-sequence')(mongoose);

hooks = require('../utils/model-hooks');

//: Schema
secretKey = new mongoose.Schema({
  key: {
    type: String,
    unique: true,
    required: true
  }
}, {
  collection: 'secret_key',
  timestamps: true
});

//: Pre-Save Hook
secretKey.pre('save', async function() {
  await hooks.saveEncrypt(this, 'key');
});

//: Pre-Update-One Hook
secretKey.pre('updateOne', async function() {
  await hooks.updateEncrypt(this.getUpdate(), 'key');
});

//: Auto Increment
secretKey.plugin(autoIncrement, {
  id: 'secret_key_uid',
  inc_field: 'uid'
});

//: Exports
module.exports = mongoose.model('SecretKey', secretKey);

//::: End Program :::

//# sourceMappingURL=secretKey.js.map
