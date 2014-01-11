(...) <-! describe 'module angular.stellar'
it 'should start test' !(...) ->
  expect true .toBeTruthy!

describe '$requestAnimationFrame' !(...) ->
  beforeEach module !($provide) ->
    const callbacks = []
    const mockWindow = do
      requestAnimationFrame: ->
        callbacks.push it

      flush: !->
        angular.forEach callbacks, -> it!

    $provide.factory '$requestAnimationFrame' $requestAnimationFrame
    $provide.value '$window' mockWindow

  const testFn = !($requestAnimationFrame, $window) ->
    called = false
    $requestAnimationFrame !-> called := true

    expect called .toBeFalsy!
    $window.flush!
    expect called .toBeTruthy!

  it 'should be called back' inject testFn

  describe 'vendor prefix' !(...) ->
    beforeEach module !($provide) ->
      const callbacks = []
      const mockWindow = do
        mozRequestAnimationFrame: ->
          callbacks.push it

        flush: !->
          angular.forEach callbacks, -> it!

      $provide.factory '$requestAnimationFrame' $requestAnimationFrame
      $provide.value '$window' mockWindow

    it 'should be called back' inject testFn


  describe 'fallback to timeout' !(...) ->
    beforeEach module !($provide) ->
      const callbacks = []
      const mockWindow = do
        setTimeout: ->
          callbacks.push it

        flush: !->
          angular.forEach callbacks, -> it!

      $provide.factory '$requestAnimationFrame' $requestAnimationFrame
      $provide.value '$window' mockWindow

    it 'should be called back' inject testFn


describe 'stellarConfig' !(...) ->
  beforeEach module !($provide) ->
    $provide.constant 
