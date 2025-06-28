// import 'ts-node/register';

// module.exports = (config) => {
//   console.log('>', config);

//   return {
//     plugins: [['./plugins/withPlugin.js']],
//   };
// };
// module.exports = require('./plugins/withPlugin.js');
// Required for external files using TS
// require('ts-node/register');

// import withPlugin from './plugins/withPlugin';

module.exports = require('./plugins/withPlugin.js');
