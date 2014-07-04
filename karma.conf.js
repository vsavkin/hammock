module.exports = function(config) {
  config.set({
    basePath: '.',
    frameworks: ['dart-unittest'],

    files: [
      'test/hammock_test.dart',
      'packages/guinness/init_specs.dart',
      {pattern: 'lib/**/*.dart', watched: true, included: false, served: true},
      {pattern: 'test/**/*.dart', watched: true, included: false, served: true},
      {pattern: 'packages/**/*.dart', watched: true, included: false, served: true}
    ],

    autoWatch: true,
    captureTimeout: 20000,
    browserNoActivityTimeout: 1500000,

    plugins: [
      'karma-dart',
      'karma-chrome-launcher',
      'karma-phantomjs-launcher'
    ],

    browsers: ['Dartium']
  });
};
