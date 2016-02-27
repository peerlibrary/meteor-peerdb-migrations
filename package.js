Package.describe({
  name: 'peerlibrary:peerdb-migrations',
  summary: "PeerDB migrations.",
  version: '0.2.1',
  git: 'https://github.com/peerlibrary/meteor-peerdb-migrations.git'
});

Package.onUse(function (api) {
  api.versionsFrom('METEOR@1.0.3.1');

  // Core dependencies.
  api.use([
    'coffeescript',
    'underscore',
    'minimongo',
    'logging'
  ], 'server');

  // 3rd party dependencies.
  api.use([
    'peerlibrary:assert@0.2.5',
    'peerlibrary:util@0.3.0',
    'peerlibrary:directcollection@0.5.0',
    'peerlibrary:peerdb@0.20.0'
  ], 'server');

  api.addFiles([
    'server.coffee'
  ], 'server');
});

Package.onTest(function (api) {
  api.use([
    'tinytest',
    'test-helpers',
    'coffeescript',
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
    'peerlibrary:peerdb@0.20.0',
    'peerlibrary:assert@0.2.5',
    'peerlibrary:directcollection@0.5.0'
  ]);

  api.addFiles([
    'tests_migrations.coffee'
  ], 'server');
});
