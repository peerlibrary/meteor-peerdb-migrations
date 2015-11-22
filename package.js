Package.describe({
  summary: "PeerDB migrations.",
  version: '0.1.1',
  name: 'peerlibrary:peerdb-migrations',
  git: 'https://github.com/peerlibrary/meteor-peerdb-migrations.git'
});

Package.on_use(function (api) {
  api.versionsFrom('METEOR@1.0');
  api.use(['coffeescript', 'underscore', 'minimongo', 'peerlibrary:assert@0.2.5', 'logging', 'peerlibrary:util@0.2.3', 'mrt:moment@2.8.1', 'peerlibrary:directcollection@0.5.0', 'peerlibrary:peerdb@0.15.1'], 'server');
  api.add_files([
    'server.coffee'
  ], 'server');
});

Package.on_test(function (api) {
  api.use(['peerlibrary:peerdb@0.15.1', 'peerlibrary:peerdb-migrations', 'tinytest', 'test-helpers', 'coffeescript', 'insecure', 'accounts-base', 'accounts-password', 'peerlibrary:assert@0.2.5', 'underscore', 'peerlibrary:directcollection@0.5.0', 'random', 'logging'], ['client', 'server']);
  api.add_files([
    'tests_defined.js',
    'tests.coffee'
  ], ['client', 'server']);

  api.add_files([
    'tests_migrations.coffee'
  ], 'server');
});
