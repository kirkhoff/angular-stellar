const {bind, noop, element, extend, equals, isDefined} = angular

const $requestAnimationFrame = <[
       $window  $log
]> ++ ($window, $log) ->
  const NAMES = <[ request webkitRequest mozRequest oRequest msRequest ]>
  for name in NAMES when $window["#{ name }AnimationFrame"]
    # $log.log "find requestAnimationFrame (#{ name })"
    return bind $window, that

  $log.warn 'Can\'t find requestAnimationFrame in your browser. Use polyfill.'
  -> $window.setTimeout it, 1000/60

const $css = <[
       $window
]> ++ ($window) ->
  # $element.css styleName
  #
  # https://github.com/angular-ui/bootstrap/blob/master/src/position/position.js
  # L11~L19
  #
  adapter: ($element, cssprop) ->
    const el = $element.0
    if el.currentStyle # IE
      el.currentStyle[cssprop]
    else if $window.getComputedStyle
      $window.getComputedStyle(el)[cssprop]
    else # finally try and get inline style
      el.style[cssprop]

  toInt: ($element, cssprop, defaultValue || 0) ->
    parseInt @adapter($element, cssprop), 10 or defaultValue

const stellarConfig = do
  scrollProperty: 'scroll'
  positionProperty: 'position'
  horizontalScrolling: true
  verticalScrolling: true
  horizontalOffset: 0
  verticalOffset: 0
  responsive: false
  parallaxBackgrounds: true
  parallaxElements: true
  hideDistantElements: 1
  hideElement: !-> it.addClass 'ng-hide'
  showElement: !-> it.removeClass 'ng-hide'
  isElementHidden: -> it.hasClass 'ng-hide'

#
# We listen scroll event on target, usually it's window
#
class Target
  (name, dom) ->
    @@[name] = @
    @_$element = element dom
    @_callbacks = []
    @_props = {}
    @_lastTime = 0

  isJustUpdated: (timestamp) ->
    const justUpdated = timestamp - @_lastTime < 1000/60
    return true if justUpdated
    @_lastTime = timestamp
    false

  isPropChanged: ->
    const updated = @getOffset!
    updated.scrollTop   = @getTop!
    updated.scrollLeft  = @getLeft!

    return false if equals updated, @_props
    extend @_props, updated
    true

  addCallbak: ->
    const index = -1+@_callbacks.push it
    bind @_callbacks, @_callbacks.splice, index

  # return true if we need to reschedule $requestAnimationFrame
  handleUpdate: !(timestamp) ->
    return true if @isJustUpdated timestamp
    return unless @isPropChanged!
    [callback @_props for callback in @_callbacks]

  #
  # https://github.com/markdalgleish/stellar.js/blob/master/src/jquery.stellar.js
  # L226
  handleWebkitBug: !->
    const {scrollTop, scrollLeft} = @_props

    @setTop scrollTop+1
    @setLeft scrollLeft+1

    @setTop scrollTop
    @setLeft scrollLeft

  getLeft: noop
  setLeft: noop

  getTop: noop
  setTop: noop


const stellarAccessors = <[
       $window  $position  $requestAnimationFrame $css  stellarConfig
]> ++ ($window, $position, $requestAnimationFrame, $css, stellarConfig) ->
  #
  # part for position & background position
  #
  const positionProperty = switch stellarConfig.positionProperty
    | 'position' =>
      setTop:  !($element, top)  -> $element.css 'top' top
      setLeft: !($element, left) -> $element.css 'left' left
    | 'transform' =>
      ...#TODO
    | _ => stellarConfig.positionProperty

  const positionAdapter = positionProperty.setPosition or !($element, left, startingLeft, top, startingTop) ->
    if stellarConfig.horizontalScrolling
      positionProperty.setLeft $element, "#{left}px", "#{startingLeft}px"
    if stellarConfig.verticalScrolling
      positionProperty.setTop $element, "#{top}px", "#{startingTop}px"

  const bgPosAdapter = do
    get: ($element) ->
      console.log typeof! $css, typeof! $css.adapter, $css.adapter($element, 'background-position')
      const bgPos = $css.adapter $element, 'background-position' .split ' '
      [parseInt(bgPos.0), parseInt(bgPos.1)]
    set: !($element, x, y) ->
      $element.css 'background-position', "#x #y"
  #
  # part for scroll properties, related to Target class
  # extend Target prototype with dependencies (which use DI services here)
  #
  const canCastToWindow = ($element) -> $window is $element.0 or 9 is $element.prop 'nodeType'

  const scrollAccessors = switch stellarConfig.scrollProperty
    | 'scroll' =>
      getLeft: -> @_$element.prop 'scrollLeft' or $window.pageXOffset
      getTop:  -> @_$element.prop 'scrollTop'  or $window.pageYOffset

      setLeft: !-> if canCastToWindow @_$element then $window.scrollTo(it, $window.pageYOffset) else @_$element.prop 'scrollLeft' it
      setTop:  !-> if canCastToWindow @_$element then $window.scrollTo($window.pageXOffset, it) else @_$element.prop 'scrollTop' it
    | 'position' =>
      getLeft: -> -1*$css.toInt @_$element, 'left'
      getTop:  -> -1*$css.toInt @_$element, 'top'
    | 'margin' =>
      getLeft: -> -1*$css.toInt @_$element, 'margin-left'
      getTop:  -> -1*$css.toInt @_$element, 'margin-top'
    | 'transform' =>
      ...# TODO
    | _ => stellarConfig.scrollProperty
  #
  extend Target::, getOffset: ->
    const offset = $position.offset @_$element
    offset.offsetTop = delete offset.top
    offset.offsetLeft = delete offset.left
    offset
  , scrollAccessors

  const update = !(timestamp) ->
    rescheduled = false
    for name, target of Target when target.handleUpdate? timestamp and not rescheduled
      rescheduled = true
      handleScrollResize!

  const handleScrollResize = !->
    $requestAnimationFrame update

  new Target 'window' $window
    .._$element.on 'scroll resize' handleScrollResize
    ..getOffset = ->
      const docEl = $window.document.documentElement
      height: docEl.clientHeight
      width: docEl.clientWidth
      offsetTop: 0
      offsetLeft: 0
    .._$element.on 'load' bind .., ..handleWebkitBug if /WebKit/.test $window.navigator.userAgent
  #  
  # return stellarAccessors
  #
  # part for position & background position
  #
  get: ($element) ->
    const positions   = $position.position $element
    const offsets     = $position.offset $element
    const bgPositions = bgPosAdapter.get $element
    
    height: positions.height
    width:  positions.width
    positionTop:  positions.top
    positionLeft: positions.left
    offsetTop:  offsets?top or 0
    offsetLeft: offsets?left or 0
    bgTop:      bgPositions.1
    bgLeft:     bgPositions.0

  set: !($element, styles) ->
    if isDefined styles.bgTop and isDefined styles.bgLeft
      bgPosAdapter.set $element, styles.bgLeft, styles.bgTop

    if isDefined styles.positionTop and isDefined styles.positionLeft
      positionAdapter $element, styles.positionLeft, styles.startingLeft, styles.positionTop, styles.startingTop
  #
  # part for scroll properties, related to Target class
  #
  requestFrame: (callback, targetName or 'window') ->
    const target = Target[targetName] or new Target targetName
    const unregisterCallback = target.addCallbak callback
    handleScrollResize!# invoke
    unregisterCallback

const stellarBackgroundRatio = <[
       $window  $document  $css  stellarAccessors
]> ++ ($window, $document, $css, stellarAccessors) ->

  const computeRatio = ($element, $attrs) ->
    const stellarBackgroundRatio = $attrs.stellarBackgroundRatio or 1
    const fixedRatioOffset = if 'fixed' is $css.adapter $element, 'background-attachment' then 0 else 1
    fixedRatioOffset - stellarBackgroundRatio

  restrict: 'A'
  #
  # @using $attrs
  #   stellarBackgroundRatio
  #   stellarVerticalOffset
  #   stellarHorizontalOffset
  #
  link: !($scope, $element, $attrs) ->
    const finalRatio        = computeRatio $element, $attrs
    const verticalOffset    = $attrs.stellarVerticalOffset or stellarConfig.verticalOffset
    const horizontalOffset  = $attrs.stellarHorizontalOffset or stellarConfig.horizontalOffset
    const selfProperties    = stellarAccessors.get $element
    const parentProperties  = offsetTop: 0, offsetLeft: 0
    #
    $scope.$on '$destroy' stellarAccessors.requestFrame !(targetProps) ->
      const bgTop = finalRatio * do
        targetProps.scrollTop +
        verticalOffset -
        targetProps.offsetTop -
        selfProperties.offsetTop +
        parentProperties.offsetTop - 
        selfProperties.bgTop
      #
      const bgLeft = finalRatio * do
        targetProps.scrollLeft +
        horizontalOffset -
        targetProps.offsetLeft -
        selfProperties.offsetLeft +
        parentProperties.offsetLeft -
        selfProperties.bgLeft
      #
      stellarAccessors.set $element, {bgTop, bgLeft}


const stellarRatio = <[
       $window  $document  $css  stellarAccessors  stellarConfig
]> ++ ($window, $document, $css, stellarAccessors, stellarConfig) ->

  const computeIsFixed = ($element) ->
    'fixed' is $css.adapter $element, 'position'

  const computeRatio = ($element, $attrs) ->
    const stellarRatio = $attrs.stellarRatio or 1
    const fixedRatioOffset = if computeIsFixed $element then 1 else 0
    stellarRatio + fixedRatioOffset - 1

  restrict: 'A'
  #
  # @using $attrs
  #   stellarRatio
  #   stellarVerticalOffset
  #   stellarHorizontalOffset
  link: !($scope, $element, $attrs) ->
    const isFixed           = computeIsFixed $element
    const finalRatio        = -1*computeRatio $element, $attrs
    const verticalOffset    = $attrs.stellarVerticalOffset or stellarConfig.verticalOffset
    const horizontalOffset  = $attrs.stellarHorizontalOffset or stellarConfig.horizontalOffset
    const selfProperties    = stellarAccessors.get $element
    const parentProperties  = offsetTop: 0, offsetLeft: 0
    #
    $scope.$on '$destroy' stellarAccessors.requestFrame !(targetProps) ->
      #
      newTop = selfProperties.positionTop
      newOffsetTop = selfProperties.offsetTop
      if stellarConfig.verticalScrolling
        newTop += finalRatio * do
          targetProps.scrollTop +
          verticalOffset +
          targetProps.offsetTop +
          selfProperties.positionTop -
          selfProperties.offsetTop +
          parentProperties.offsetTop
        newOffsetTop += newTop - selfProperties.positionTop        
      #
      newLeft = selfProperties.positionLeft
      newOffsetLeft = selfProperties.offsetLeft

      if stellarConfig.horizontalScrolling
        newLeft += finalRatio * do
          targetProps.scrollLeft +
          horizontalOffset +
          targetProps.offsetLeft +
          selfProperties.positionLeft -
          selfProperties.offsetLeft +
          parentProperties.offsetLeft
        newOffsetLeft += newLeft - selfProperties.positionLeft
      #
      if stellarConfig.hideDistantElements
        targetScrollLeft = if isFixed then 0 else targetProps.scrollLeft
        targetScrollTop  = if isFixed then 0 else targetProps.scrollTop
        #
        isVisibleHorizontal = !stellarConfig.horizontalScrolling or do
          newOffsetLeft + selfProperties.width > targetScrollLeft and
          newOffsetLeft < targetProps.width + targetProps.offsetLeft + targetScrollLeft
        isVisibleVertical = !stellarConfig.verticalScrolling or do
          newOffsetTop + selfProperties.height > targetScrollTop and
          newOffsetTop < targetProps.height + targetProps.offsetTop + targetScrollTop
      #
      const isHidden = stellarConfig.isElementHidden $element
      if isVisibleHorizontal and isVisibleVertical
        stellarConfig.showElement $element if isHidden
        stellarAccessors.set $element, do
          positionTop: newTop
          positionLeft: newLeft
          startingTop: selfProperties.positionTop
          startingLeft: selfProperties.positionLeft
      else unless isHidden
        stellarConfig.hideElement $element


angular.module 'angular.stellar' <[
  ui.bootstrap.position
]>
.constant 'stellarConfig' stellarConfig
.factory '$requestAnimationFrame' $requestAnimationFrame
.factory '$css' $css
.factory 'stellarAccessors' stellarAccessors

.directive 'stellarRatio' stellarRatio
.directive 'stellarBackgroundRatio' stellarBackgroundRatio
