const path = require('path');
const pak = require('../../package.json');

module.exports = {
  dependencies: {
    ...(process.env.NO_FLIPPER
      ? {'react-native-flipper': {platforms: {ios: null}}}
      : {}),
    [pak.name]: {
      root: path.join(__dirname, '../..'),
    },
  },
};
