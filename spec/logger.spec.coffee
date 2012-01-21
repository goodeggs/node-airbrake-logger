logger = require '../src/logger'

describe 'logger', ->

  fakeConsole =
    error: -> throw 'stub me'
    log: -> throw 'stub me'

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

