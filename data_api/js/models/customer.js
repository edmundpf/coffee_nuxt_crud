var autoIncrement, customer, listCreate, mongoose;

mongoose = require('mongoose');

autoIncrement = require('mongoose-sequence')(mongoose);

listCreate = require('../utils/model-hooks').listCreate;

//: Schema
customer = new mongoose.Schema({
  email: {
    type: String,
    unique: true,
    required: true
  },
  first_name: {
    type: String,
    required: true
  },
  last_name: {
    type: String,
    required: true
  },
  products_purchased: [
    {
      type: String
    }
  ]
}, {
  collection: 'customers',
  timestamps: true,
  usePushEach: true
});

//: Pre-Save Hook
customer.pre('save', async function() {
  await listCreate(this, ['products_purchased']);
});

//: Auto Increment
customer.plugin(autoIncrement, {
  id: 'customer_uid',
  inc_field: 'uid'
});

//: Exports
module.exports = mongoose.model('Customer', customer);

//::: End Program :::

//# sourceMappingURL=customer.js.map
