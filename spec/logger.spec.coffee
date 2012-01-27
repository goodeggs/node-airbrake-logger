logger = require '../lib/logger'

describe 'logger', ->

  fakeConsole =
    error: -> throw 'stub fakceConsole.error'
    log: -> throw 'stub fakeConsole.log'

  describe 'with default settings', ->

    beforeEach ->
      logger.configure airbrakeKey: '12345', console: fakeConsole
      spyOn(logger.client, 'notify')

    it 'should log errors', ->
      spyOn(fakeConsole, 'error')
      logger.error(new Error('something happened'))
      expect(fakeConsole.error.callCount).toEqual 1
      expect(fakeConsole.error.mostRecentCall.args[0]).toMatch /something happened/
      expect(logger.client.notify.callCount).toEqual 1
      expect(logger.client.notify.mostRecentCall.args[0].message).toEqual 'something happened'

    it 'should log errors with addtional context if provided', ->
      spyOn(fakeConsole, 'error')
      logger.error('more context', new Error('something happened'))
      expect(fakeConsole.error.callCount).toEqual 1
      expect(fakeConsole.error.mostRecentCall.args[0]).toMatch /something happened/
      expect(fakeConsole.error.mostRecentCall.args[0]).toMatch /more context/
      expect(logger.client.notify.callCount).toEqual 1
      expect(logger.client.notify.mostRecentCall.args[0].message).toEqual 'something happened'
      expect(logger.client.notify.mostRecentCall.args[0].params.context).toEqual 'more context'

    it 'should log string-based errors to the console and airbrake', ->
      spyOn(fakeConsole, 'error')
      logger.error('something happened')
      expect(fakeConsole.error.callCount).toEqual 1
      expect(fakeConsole.error.mostRecentCall.args[0]).toMatch /something happened/
      expect(logger.client.notify.callCount).toEqual 1
      expect(logger.client.notify.mostRecentCall.args[0].message).toEqual 'something happened'

    it 'should log debugs to the console but not airbrake', ->
      spyOn(fakeConsole, 'log')
      logger.debug('something happened')
      expect(fakeConsole.log.callCount).toEqual 1
      expect(fakeConsole.log.mostRecentCall.args[0]).toMatch /something happened/
      expect(logger.client.notify).not.toHaveBeenCalled()

    describe 'cgiDataVars', ->
      beforeEach ->
        process.env['SENDGRID_PASSWORD'] = 'somethingSecure'
        process.env['SOMEOTHERPASSWORD'] = 'somethingElseSecure'

      afterEach ->
        delete process.env['SENDGRID_PASSWORD']

      it 'should not log passwords stored in the env', ->
        err = new Error('this is the error')
        cgiVars = logger.client.cgiDataVars(err)
        expect(cgiVars['USER']).not.toBeNull()
        expect(cgiVars['SENDGRID_PASSWORD']).toEqual '[HIDDEN]'
        expect(cgiVars['SOMEOTHERPASSWORD']).toEqual '[HIDDEN]'

    describe 'middleware', ->
      it 'places request headers in position to be picked up by the client', ->
        req = {}
        req.headers = {}
        req.headers.accept = 'text/html'

        err = new Error('the error message')

        next = jasmine.createSpy()
        spyOn(fakeConsole, 'error')

        logger.middleware(err, req, {}, next)
        
        expect(next).toHaveBeenCalledWith(err)

        expect(err['request.header.accept']).toEqual 'text/html'

      it 'places includes body params, query params, and route params', ->
        req = {}
        req.headers = {}
        req.headers.accept = 'text/html'
        req.params = order: 'somelongorderid'
        req.body = someKey: {nestedKey: 'somevalue'}
        req.query = queryParam: 'queryValue'

        err = new Error('the error message')

        next = jasmine.createSpy()
        spyOn(fakeConsole, 'error')

        logger.middleware(err, req, {}, next)

        expect(next).toHaveBeenCalledWith(err)

        expect(err.params).toEqual
          params:
            order: 'somelongorderid'
          query:
            queryParam: 'queryValue'
          body:
            someKey:
              nestedKey: 'somevalue'
          context: 'uncaught express exception'

  describe 'with remote: false', ->

    beforeEach ->
      logger.configure airbrakeKey: '12345', remote: false, console: fakeConsole
      spyOn(logger.client, 'notify')

    it 'should log errors to the console but not airbrake', ->
      spyOn(fakeConsole, 'error')
      logger.error('something happened')
      expect(fakeConsole.error.callCount).toEqual 1
      expect(fakeConsole.error.mostRecentCall.args[0]).toMatch /something happened/
      expect(logger.client.notify).not.toHaveBeenCalled()

    it 'should log debugs to the console but not airbrake', ->
      spyOn(fakeConsole, 'log')
      logger.debug('something happened')
      expect(fakeConsole.log.callCount).toEqual 1
      expect(fakeConsole.log.mostRecentCall.args[0]).toMatch /something happened/
      expect(logger.client.notify).not.toHaveBeenCalled()

