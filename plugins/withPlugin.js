const configPlugins = require('expo/config-plugins');
const { withAppBuildGradle, WarningAggregator, createRunOncePlugin } =
  configPlugins;

const pkg = require('../package.json');

function addToDefaultConfigInBuildGradle(buildGradle, addLine) {
  const lines = buildGradle.split('\n');
  const anchorIndex = lines.findIndex((line) => line.match('defaultConfig'));
  if (lines.findIndex((line) => line.includes(addLine)) === -1) {
    lines.splice(anchorIndex + 1, 0, `\t\t${addLine}`);
  }
  return lines.join('\n');
}

function withPlugin(config, props) {
  const missingDimensionStrategy =
    props?.captureType === 'base'
      ? `missingDimensionStrategy "react-native-capture-protection", "base"`
      : `missingDimensionStrategy "react-native-capture-protection", "callbackTiramisu"`;

  try {
    return withAppBuildGradle(config, (config) => {
      config.modResults.contents = addToDefaultConfigInBuildGradle(
        config.modResults.contents,
        missingDimensionStrategy
      );

      return config;
    });
  } catch (error) {
    WarningAggregator.addWarningAndroid(
      'react-native-capture-protection',
      `There was a problem to configuring react-native-capture-protection in Android project: ${error}`
    );
    return config;
  }
}

exports.default = createRunOncePlugin(withPlugin, pkg.name, pkg.version);
