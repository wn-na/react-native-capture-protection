const configPlugins = require('expo/config-plugins');
const { withAppBuildGradle, WarningAggregator, createRunOncePlugin } =
  configPlugins;

const pkg = require('../package.json');

function addToDefaultConfigInBuildGradle(buildGradle, addLine) {
  const lines = buildGradle.split('\n');
  const anchorIndex = lines.findIndex((line) => line.match('defaultConfig'));
  lines.splice(anchorIndex + 1, 0, addLine);
  return lines.join('\n');
}

function withPlugin(config, props) {
  const missingDimensionStrategy =
    props?.captureType === 'restrictedCapture'
      ? `\tmissingDimensionStrategy "react-native-capture-protection", "restrictedCapture"`
      : `\tmissingDimensionStrategy "react-native-capture-protection", "fullMediaCapture"`;

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
