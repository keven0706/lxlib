
local lx, _M = oo{ 
    _cls_ = '',
    _ext_ = 'box'
}

local app, lf, tb, str, new = lx.kit()

function _M:reg()

    self:regDepends()
    self:regBond()
    self:regExcp()

    app:keep('db',                      'lxlib.db.dbAccessor')
    app:single('db.factory',            'lxlib.db.conn.connectionFactory')
 
    app:bind('db.conn', function()
        return app:get('db'):connection()
    end)
    app:bind('db.manager',              'lxlib.db.dbManager')
    app:bind('db.query',                'lxlib.db.query.builder')
    app:bind('db.queryExpression',      'lxlib.db.query.expression')
    app:bind('db.dbo',                  'lxlib.db.entity.dbo')
    app:bind('db.dbos',                 'lxlib.db.entity.dbos')
    app:single('db.entityFactory',      'lxlib.db.entity.factory')
    app:single('dbos', function()
        return app:get('db.entityFactory'):getDbos()
    end)

    app:bind('model',                   'lxlib.db.orm.model')
    app:bind('orm.query',               'lxlib.db.orm.query')
    
    app:bind('db.schema',               'lxlib.db.schema.builder')
    app:bind('schema', function(connName)
        return app:get('db'):conn(connName):getSchemaBuilder()
    end)

end

function _M:boot()

    self:makeEntityFactory()
    self:setUserModel()
    self:addOrmQueryMtToMsgPack()
end

function _M.__:makeEntityFactory()

    local dbosPath = app:conf('db.dbos')
    local baseDbos
    if dbosPath then
        baseDbos = require(dbosPath)
    end
 
    app:make('db.entityFactory', baseDbos)
end

function _M.__:setUserModel()

    local userModel = app:conf('auth.providers.users.model')
    local userTable = app:conf('auth.providers.users.table')
    if userModel then
        local Models = lx.use('models')
        Models.setGlobalModel('user', userModel)
        Models.setGlobalTable('user', userTable)
    end
end

function _M.__:addOrmQueryMtToMsgPack()

    local MsgPack = lx.use('msgPack')
    local Query = lx.use('orm.query')

    MsgPack.addPackMt('ormQuerySetModelsMt', function(models)

        return Query.setModelsMt(models)
    end)
end

function _M:regBond()
    
    app:bond('ldoBond',                 'lxlib.db.bond.ldoBond')
    app:bond('connectionBond',          'lxlib.db.bond.connectionBond')
    app:bond('connectorBond',           'lxlib.db.bond.connectorBond')
    app:bond('connectionResolverBond',  'lxlib.db.bond.connectionResolverBond')

    app:bond('scope', 'lxlib.db.orm.scope')
 
end

function _M:regExcp()

    app:bindFrom('lxlib.db.excp', {
        'ldoException',
        'queryException',
        'modelNotFoundException',
        'invalidColumnValueException'
    })

end

function _M:regDepends()

    app:bindFrom('lxlib.db.orm.relation', {
        'relation', 'hasSome', 'hasOne', 'hasMany',
        'belongsTo', 'belongsToMany', 'morphSome',
        'morphOne', 'morphMany', 'morphTo', 'morphToMany',
        'pivot', 'morphPivot'
    })

    app:bind('softDelete',          'lxlib.db.orm.softDelete')

    app:bindFrom('lxlib.db.orm.ext', {
        'presentableMix', 'presenter', 'models', 'searchableMix'
    })
    app:bind('modelCol', 'lxlib.db.orm.col')

    app:single('db.seed.fair', function()

        local faker = new 'lxlib.db.orm.seed.faker'
        local fair = new('lxlib.db.orm.seed.fair')

        return fair:construct(faker, lx.dir('db', 'seed/fair'))
    end)
end
 
return _M

