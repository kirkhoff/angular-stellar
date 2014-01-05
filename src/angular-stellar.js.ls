const $requestAnimationFrame = <[
       $window  $log
]> ++ ($window, $log) ->
  #
  # http://caniuse.com/#feat=requestanimationframe
  #
  const NAMES = <[ request webkitRequest mozRequest oRequest msRequest ]>
  for name in NAMES when $window["#{ name }AnimationFrame"]
    # $log.log "find requestAnimationFrame (#{ name })"
    return angular.bind $window, that

  $log.warn 'Can\'t find requestAnimationFrame in your browser. Use polyfill.'
  -> $window.setTimeout it, 1000/60

