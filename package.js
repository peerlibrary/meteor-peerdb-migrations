Package.describe({
  name: 'peerlibrary:peerdb-migrations',
  summary: "PeerDB migrations.",
  version: '1.0.1',
  git: 'https://github.com/peerlibrary/meteor-peerdb-migrations.git'
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@1.4.4.5');

  // Core dependencies.
  api.use([
    'coffeescript@2.0.3_3',
    'ecmascript',
    'underscore',
    'minimongo',
    'logging'
  ], 'server');

  // 3rd party dependencies.
  api.use([
    'peerlibrary:assert@0.2.5',
    'peerlibrary:directcollection@0.7.0',
    'peerlibrary:peerdb@0.26.0'
  ], 'server');

  api.addFiles([
    'server.coffee'
  ], 'server');
});

Package.onTest(function (api) {
  api.versionsFrom('METEOR@1.4.4.5');

  // Core dependencies.
  api.use([
    'coffeescript@2.0.3_3',
    'ecmascript',
    'tinytest',
    'test-helpers',
    'underscore',
    'random',
    'logging',
    'ejson',
    'mongo'
  ], 'server');

  // Internal dependencies.
  api.use([
    'peerlibrary:peerdb-migrations'
  ]);

  // 3rd party dependencies.
  api.use([
    'peerlibrary:peerdb@0.25.0',
    'peerlibrary:assert@0.2.5',
    'peerlibrary:directcollection@0.7.0'
  ]);

  api.addFiles([
    'tests_migrations.coffee'
  ], 'server');
});
