semver = Npm.require 'semver'

globals = @

try
  # Migration of migrations collection
  new DirectCollection('migrations').renameCollection 'peerdb.migrations'
catch error
  throw error unless /source namespace does not exist/.test "#{ error }"

# Fields:
#   serial
#   migrationName
#   oldCollectionName
#   newCollectionName
#   oldVersion
#   newVersion
#   timestamp
#   migrated
#   all
# We use a lower case collection name to signal it is a system collection
globals.Document.Migrations = new Meteor.Collection 'peerdb.migrations'

globals.Document._Migration = class
    updateAll: (document, collection, currentSchema, intoSchema) =>
      @_updateAll = true

    forward: (document, collection, currentSchema, newSchema) =>
      migrated: 0
      all: collection.update {_schema: currentSchema}, {$set: _schema: newSchema}, {multi: true}

    backward: (document, collection, currentSchema, oldSchema) =>
      migrated: 0
      all: collection.update {_schema: currentSchema}, {$set: _schema: oldSchema}, {multi: true}

globals.Document.PatchMigration = class extends globals.Document._Migration

globals.Document.MinorMigration = class extends globals.Document._Migration

globals.Document.MajorMigration = class extends globals.Document._Migration

globals.Document.AddReferenceFieldsMigration = class extends globals.Document.MinorMigration
  forward: (document, collection, currentSchema, newSchema) =>
    @updateAll document, collection, currentSchema, newSchema

    counts = super
    counts.migrated = counts.all
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    @updateAll document, collection, currentSchema, oldSchema

    counts = super
    counts.migrated = counts.all
    counts

globals.Document.RemoveReferenceFieldsMigration = class extends globals.Document.MajorMigration
  forward: (document, collection, currentSchema, newSchema) =>
    @updateAll document, collection, currentSchema, newSchema

    counts = super
    counts.migrated = counts.all
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    @updateAll document, collection, currentSchema, oldSchema

    counts = super
    counts.migrated = counts.all
    counts

globals.Document.AddGeneratedFieldsMigration = class extends globals.Document.MinorMigration
  # Fields is an array
  constructor: (fields) ->
    @fields = fields if fields
    super

  forward: (document, collection, currentSchema, newSchema) =>
    assert @fields

    @updateAll document, collection, currentSchema, newSchema

    counts = super
    counts.migrated = counts.all
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    update =
      $unset: {}
      $set:
        _schema: oldSchema

    for field in @fields
      update.$unset[field] = ''

    count = collection.update {_schema: currentSchema}, update, {multi: true}

    counts = super
    counts.migrated += count
    counts.all += count
    counts

globals.Document.ModifyGeneratedFieldsMigration = class extends globals.Document.PatchMigration
  # Fields is an array
  constructor: (fields) ->
    @fields = fields if fields
    super

  forward: (document, collection, currentSchema, newSchema) =>
    assert @fields

    @updateAll document, collection, currentSchema, newSchema

    counts = super
    counts.migrated = counts.all
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    assert @fields

    @updateAll document, collection, currentSchema, oldSchema

    counts = super
    counts.migrated = counts.all
    counts

globals.Document.RemoveGeneratedFieldsMigration = class extends globals.Document.MajorMigration
  # Fields is an array
  constructor: (fields) ->
    @fields = fields if fields
    super

  forward: (document, collection, currentSchema, newSchema) =>
    update =
      $unset: {}
      $set:
        _schema: newSchema

    for field in @fields
      update.$unset[field] = ''

    count = collection.update {_schema: currentSchema}, update, {multi: true}

    counts = super
    counts.migrated += count
    counts.all += count
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    assert @fields

    @updateAll document, collection, currentSchema, oldSchema

    counts = super
    counts.migrated = counts.all
    counts

globals.Document.AddOptionalFieldsMigration = class extends globals.Document.MinorMigration
  # Fields is an array
  constructor: (fields) ->
    @fields = fields if fields
    super

  forward: (document, collection, currentSchema, newSchema) =>
    assert @fields
    super

  backward: (document, collection, currentSchema, oldSchema) =>
    update =
      $unset: {}
      $set:
        _schema: oldSchema

    for field in @fields
      update.$unset[field] = ''

    count = collection.update {_schema: currentSchema}, update, {multi: true}

    counts = super
    counts.migrated += count
    counts.all += count
    counts

globals.Document.AddRequiredFieldsMigration = class extends globals.Document.MinorMigration
  # Fields is an object
  constructor: (fields) ->
    @fields = fields if fields
    super

  forward: (document, collection, currentSchema, newSchema) =>
    selector =
      _schema: currentSchema
    for field, value of @fields
      selector[field] =
        $exists: false

    update =
      $set:
        _schema: newSchema
    for field, value of @fields
      if _.isFunction value
        update.$set[field] = value()
      else
        update.$set[field] = value

    count = collection.update selector, update, {multi: true}

    counts = super
    counts.migrated += count
    counts.all += count
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    update =
      $unset: {}
      $set:
        _schema: oldSchema

    for field, value of @fields
      update.$unset[field] = ''

    count = collection.update {_schema: currentSchema}, update, {multi: true}

    counts = super
    counts.migrated += count
    counts.all += count
    counts

globals.Document.RemoveFieldsMigration = class extends globals.Document.MajorMigration
  # Fields is an object
  constructor: (fields) ->
    @fields = fields if fields
    super

  forward: (document, collection, currentSchema, newSchema) =>
    update =
      $unset: {}
      $set:
        _schema: newSchema

    for field, value of @fields
      update.$unset[field] = ''

    count = collection.update {_schema: currentSchema}, update, {multi: true}

    counts = super
    counts.migrated += count
    counts.all += count
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    selector =
      _schema: currentSchema
    for field, value of @fields
      selector[field] =
        $exists: false

    update =
      $set:
        _schema: oldSchema
    for field, value of @fields
      if _.isFunction value
        v = value()
      else
        v = value
      update.$set[field] = v unless _.isUndefined v

    count = collection.update selector, update, {multi: true}

    counts = super
    counts.migrated += count
    counts.all += count
    counts

globals.Document.RenameFieldsMigration = class extends globals.Document.MajorMigration
  # Fields is object
  constructor: (fields) ->
    @fields = fields if fields
    super

  forward: (document, collection, currentSchema, newSchema) =>
    update =
      $set:
        _schema: newSchema
      $rename: {}

    for from, to of @fields
      update.$rename[from] = to

    count = collection.update {_schema: currentSchema}, update, {multi: true}

    counts = super
    counts.migrated += count
    counts.all += count
    counts

  backward: (document, collection, currentSchema, oldSchema) =>
    update =
      $set:
        _schema: oldSchema
      $rename: {}

    for from, to of @fields
      # Reversed
      update.$rename[to] = from

    count = collection.update {_schema: currentSchema}, update, {multi: true}

    counts = super
    counts.migrated += count
    counts.all += count
    counts

globals.Document._RenameCollectionMigration = class extends globals.Document.MajorMigration
  constructor: (@oldName, @newName) ->
    @name = "Renaming collection from '#{ @oldName }' to '#{ @newName }'"

  _rename: (collection, to) =>
    try
      collection.renameCollection to
    catch error
      throw error unless /source namespace does not exist/.test "#{ error }"

  forward: (document, collection, currentSchema, newSchema) =>
    assert.equal collection.name, @oldName

    @_rename collection, @newName

    collection.name = @newName

    # We renamed the collection, so let's update all documents to new schema version
    counts = super
    # We migrated everything
    counts.migrated = counts.all
    counts

  backward: (document, collection, currentSchema, newSchema) =>
    assert.equal collection.name, @newName

    @_rename collection, @oldName

    collection.name = @oldName

    # We renamed the collection, so let's update all documents to old schema version
    counts = super
    # We migrated everything
    counts.migrated = counts.all
    counts

globals.Document.addMigration = (migration) ->
  throw new Error "Migration is missing a name" unless migration.name
  throw new Error "Migration is not a migration instance" unless migration instanceof @_Migration
  throw new Error "Migration with the name '#{ migration.name }' already exists" if migration.name in _.pluck @Meta.migrations, 'name'

  @Meta.migrations.push migration

globals.Document.renameCollectionMigration = (oldName, newName) ->
  @addMigration new @_RenameCollectionMigration oldName, newName

globals.Document.migrateForward = (untilName) ->
  # TODO: Implement
  throw new Error "Not implemented yet"

globals.Document.migrateBackward = (untilName) ->
  # TODO: Implement
  throw new Error "Not implemented yet"

globals.Document.migrate = ->
  schemas = ['1.0.0']
  currentSchema = '1.0.0'
  currentSerial = 0

  initialName = @Meta.collection._name
  for migration in @Meta.migrations by -1 when migration instanceof @_RenameCollectionMigration
    throw new Error "Incosistent document renaming, renaming from '#{ migration.oldName }' to '#{ migration.newName }', but current name is '#{ initialName }' (new name and current name should match)" if migration.newName isnt initialName
    initialName = migration.oldName

  migrationsPending = Number.POSITIVE_INFINITY
  currentName = initialName
  for migration, i in @Meta.migrations
    if migration instanceof @PatchMigration
      newSchema = semver.inc currentSchema, 'patch'
    else if migration instanceof @MinorMigration
      newSchema = semver.inc currentSchema, 'minor'
    else if migration instanceof @MajorMigration
      newSchema = semver.inc currentSchema, 'major'

    if migration instanceof @_RenameCollectionMigration
      newName = migration.newName
    else
      newName = currentName

    migrations = globals.Document.Migrations.find(
      serial:
        $gt: currentSerial
      oldCollectionName:
        $in: [currentName, newName]
    ,
      sort: [
        ['serial', 'asc']
      ]
    ).fetch()

    if migrations[0]
      throw new Error "Unexpected migration recorded: #{ util.inspect migrations[0], depth: 10 }" if migrationsPending < Number.POSITIVE_INFINITY

      if migrations[0].migrationName is migration.name and migrations[0].oldCollectionName is currentName and migrations[0].newCollectionName is newName and migrations[0].oldVersion is currentSchema and migrations[0].newVersion is newSchema
        currentSerial = migrations[0].serial
      else
        throw new Error "Incosistent migration recorded, expected migrationName='#{ migration.name }', oldCollectionName='#{ currentName }', newCollectionName='#{ newName }', oldVersion='#{ currentSchema }', newVersion='#{ newSchema }', got: #{ util.inspect migrations[0], depth: 10 }"
    else if migrationsPending is Number.POSITIVE_INFINITY
      # This is the collection name recorded as the last, so we start with it
      initialName = currentName
      migrationsPending = i

    currentSchema = newSchema
    schemas.push currentSchema
    currentName = newName

  unknownSchema = _.pluck @Meta.collection.find(
    _schema:
      $nin: schemas
      $exists: true
  ,
    fields:
      _id: 1
  ).fetch(), '_id'

  throw new Error "Documents with unknown schema version: #{ unknownSchema }" if unknownSchema.length

  updateAll = false

  currentSchema = '1.0.0'
  currentSerial = 0
  currentName = initialName
  for migration, i in @Meta.migrations
    if migration instanceof @PatchMigration
      newSchema = semver.inc currentSchema, 'patch'
    else if migration instanceof @MinorMigration
      newSchema = semver.inc currentSchema, 'minor'
    else if migration instanceof @MajorMigration
      newSchema = semver.inc currentSchema, 'major'

    if i < migrationsPending and migration instanceof @_RenameCollectionMigration
      # We skip all already done rename migrations (but we run other old migrations again, just with the last known collection name)
      currentSchema = newSchema
      currentName = migration.newName
      continue

    if migration instanceof @_RenameCollectionMigration
      newName = migration.newName
    else
      newName = currentName

    if globals.Document.migrationsDisabled
      # Migrations are disabled but we are still running
      # the code just to compute the latest schema version
      currentSchema = newSchema
      currentName = newName
      continue

    migration._updateAll = false

    counts = migration.forward @, new DirectCollection(currentName), currentSchema, newSchema
    throw new Error "Invalid return value from migration: #{ util.inspect counts }" unless 'migrated' of counts and 'all' of counts

    updateAll = true if counts.migrated and migration._updateAll

    if i < migrationsPending
      count = globals.Document.Migrations.update
        migrationName: migration.name
        oldCollectionName: currentName
        newCollectionName: newName
        oldVersion: currentSchema
        newVersion: newSchema
      ,
        $inc:
          migrated: counts.migrated
          all: counts.all
      ,
        multi: true # To catch any errors

      throw new Error "Incosistent migration record state, missing migrationName='#{ migration.name }', oldCollectionName='#{ currentName }', newCollectionName='#{ newName }', oldVersion='#{ currentSchema }', newVersion='#{ newSchema }'" unless count is 1
    else
      count = globals.Document.Migrations.find(
        migrationName: migration.name
        oldCollectionName: currentName
        newCollectionName: newName
        oldVersion: currentSchema
        newVersion: newSchema
      ).count()

      throw new Error "Incosistent migration record state, unexpected migrationName='#{ migration.name }', oldCollectionName='#{ currentName }', newCollectionName='#{ newName }', oldVersion='#{ currentSchema }', newVersion='#{ newSchema }'" unless count is 0

      globals.Document.Migrations.insert
        # Things should not be running in parallel here anyway, so we can get next serial in this way
        serial: globals.Document.Migrations.findOne({}, {sort: [['serial', 'desc']]}).serial + 1
        migrationName: migration.name
        oldCollectionName: currentName
        newCollectionName: newName
        oldVersion: currentSchema
        newVersion: newSchema
        migrated: counts.migrated
        all: counts.all
        timestamp: moment.utc().toDate()

    if migration instanceof @_RenameCollectionMigration
      Log.info "Renamed collection '#{ currentName }' to '#{ newName }'"
      Log.info "Migrated #{ counts.migrated }/#{ counts.all } document(s) (from #{ currentSchema } to #{ newSchema }): #{ migration.name }" if counts.all
    else
      Log.info "Migrated #{ counts.migrated }/#{ counts.all } document(s) in '#{ currentName }' collection (from #{ currentSchema } to #{ newSchema }): #{ migration.name }" if counts.all

    currentSchema = newSchema
    currentName = newName

  # We do not check for not migrated documents if migrations are disabled
  unless globals.Document.migrationsDisabled
    # For all those documents which lack schema information we assume they have the last schema
    @Meta.collection.update
      _schema:
        $exists: false
    ,
      $set:
        _schema: currentSchema
    ,
      multi: true

    notMigrated = _.pluck @Meta.collection.find(
      _schema:
        $ne: currentSchema
    ,
      fields:
        _id: 1
    ).fetch(), '_id'

    throw new Error "Not all documents migrated to the latest schema version (#{ currentSchema }): #{ notMigrated }" if notMigrated.length

  @Meta.schema = currentSchema

  # Return if updateAll should be called
  updateAll

globals.Document._setupMigrations = ->
  updateAll = @migrate()

  unless globals.Document.instanceDisabled
    @Meta.collection.find(
      _schema:
        $exists: false
    ,
      fields:
        _id: 1
        _schema: 1
    ).observeChanges
      added: globals.Document._observerCallback true, (id, fields) =>
        # TODO: Check if schema is known and complain if not
        # TODO: We could automatically migrate old documents if we know of newer schema
        return if fields._schema

        @Meta.collection.update id,
          $set:
            _schema: @Meta.schema

  # Return if updateAll should be called
  updateAll

# TODO: What happens if this is called multiple times? We should make sure that for each document observrs are made only once
setupMigrations = ->
  updateAll = false
  # Migrate only server collections.
  for document in globals.Document.list when document.Meta.collection._connection is Meteor.server
    # Always run setupMigrations, don't short circuit
    updateAll = document._setupMigrations() or updateAll

  if updateAll
    Log.info "Migrations requested updating all references..."
    globals.Document.updateAll()

migrations = ->
  if globals.Document.Migrations.find({}, limit: 1).count() == 0
    globals.Document.Migrations.insert
      serial: 1
      migrationName: null
      oldCollectionName: null
      newCollectionName: null
      oldVersion: null
      newVersion: null
      timestamp: moment.utc().toDate()
      migrated: 0
      all: 0

  setupMigrations()

globals.Document.migrationsDisabled = !!process.env.PEERDB_MIGRATIONS_DISABLED

globals.Document.prepare ->
  Log.info "Skipped migrations" if globals.Document.migrationsDisabled
  # We still run the code to determine schema version and setup
  # observer to set schema version when inserting new documents,
  # but we then inside the code skip running migrations themselves
  migrations()

Document = globals.Document
