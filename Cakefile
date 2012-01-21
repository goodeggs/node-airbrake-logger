{spawn} = require 'child_process'
{print}       = require 'util'

run = (cmd, args, cb) ->
  proc =         spawn cmd, args
  proc.stdout.on 'data', (buffer) -> print buffer.toString()
  proc.stderr.on 'data', (buffer) -> print buffer.toString()
  proc.on        'exit', (status) ->
    process.exit(1) if status != 0
    cb() if typeof cb is 'function'

task 'compile', ->
  run 'coffee', ['-cbl', '-o', 'lib', 'src'], (status) ->
    process.exit(status)

task 'spec', ->
  run 'jasmine-node', ['spec', '--coffee', '--junitreport', '--noColor'], (status) ->
    process.exit(status)
