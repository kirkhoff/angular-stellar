(function(){
  var bind, noop, element, extend, equals, isDefined, $requestAnimationFrame, $css, stellarConfig, Target, stellarAccessors, stellarBackgroundRatio, stellarRatio;
  bind = angular.bind, noop = angular.noop, element = angular.element, extend = angular.extend, equals = angular.equals, isDefined = angular.isDefined;
  $requestAnimationFrame = ['$window', '$log'].concat(function($window, $log){
    var NAMES, i$, len$, name, that;
    NAMES = ['request', 'webkitRequest', 'mozRequest', 'oRequest', 'msRequest'];
    for (i$ = 0, len$ = NAMES.length; i$ < len$; ++i$) {
      name = NAMES[i$];
      if (that = $window[name + "AnimationFrame"]) {
        return bind($window, that);
      }
    }
    $log.warn('Can\'t find requestAnimationFrame in your browser. Use polyfill.');
    return function(it){
      return $window.setTimeout(it, 1000 / 60);
    };
  });
  $css = ['$window'].concat(function($window){
    return {
      adapter: function($element, cssprop){
        var el;
        el = $element[0];
        if (el.currentStyle) {
          return el.currentStyle[cssprop];
        } else if ($window.getComputedStyle) {
          return $window.getComputedStyle(el)[cssprop];
        } else {
          return el.style[cssprop];
        }
      },
      toInt: function($element, cssprop, defaultValue){
        defaultValue || (defaultValue = 0);
        return parseInt(this.adapter($element, cssprop), 10) || defaultValue;
      }
    };
  });
  stellarConfig = {
    scrollProperty: 'scroll',
    positionProperty: 'position',
    horizontalScrolling: true,
    verticalScrolling: true,
    horizontalOffset: 0,
    verticalOffset: 0,
    responsive: false,
    parallaxBackgrounds: true,
    parallaxElements: true,
    hideDistantElements: 1,
    hideElement: function(it){
      it.addClass('ng-hide');
    },
    showElement: function(it){
      it.removeClass('ng-hide');
    },
    isElementHidden: function(it){
      return it.hasClass('ng-hide');
    }
  };
  Target = (function(){
    Target.displayName = 'Target';
    var prototype = Target.prototype, constructor = Target;
    function Target(name, dom){
      constructor[name] = this;
      this._$element = element(dom);
      this._callbacks = [];
      this._props = {};
      this._lastTime = 0;
    }
    prototype.isJustUpdated = function(timestamp){
      var justUpdated;
      justUpdated = timestamp - this._lastTime < 1000 / 60;
      if (justUpdated) {
        return true;
      }
      this._lastTime = timestamp;
      return false;
    };
    prototype.isPropChanged = function(){
      var updated;
      updated = this.getOffset();
      updated.scrollTop = this.getTop();
      updated.scrollLeft = this.getLeft();
      if (equals(updated, this._props)) {
        return false;
      }
      extend(this._props, updated);
      return true;
    };
    prototype.addCallbak = function(it){
      var index;
      index = -1 + this._callbacks.push(it);
      return bind(this._callbacks, this._callbacks.splice, index);
    };
    prototype.handleUpdate = function(timestamp){
      var i$, ref$, len$, callback;
      if (this.isJustUpdated(timestamp)) {
        return true;
      }
      if (!this.isPropChanged()) {
        return;
      }
      for (i$ = 0, len$ = (ref$ = this._callbacks).length; i$ < len$; ++i$) {
        callback = ref$[i$];
        callback(this._props);
      }
    };
    prototype.handleWebkitBug = function(){
      var ref$, scrollTop, scrollLeft;
      ref$ = this._props, scrollTop = ref$.scrollTop, scrollLeft = ref$.scrollLeft;
      this.setTop(scrollTop + 1);
      this.setLeft(scrollLeft + 1);
      this.setTop(scrollTop);
      this.setLeft(scrollLeft);
    };
    prototype.getLeft = noop;
    prototype.setLeft = noop;
    prototype.getTop = noop;
    prototype.setTop = noop;
    return Target;
  }());
  stellarAccessors = ['$window', '$position', '$requestAnimationFrame', '$css', 'stellarConfig'].concat(function($window, $position, $requestAnimationFrame, $css, stellarConfig){
    var positionProperty, positionAdapter, bgPosAdapter, canCastToWindow, scrollAccessors, update, handleScrollResize, x$;
    positionProperty = (function(){
      switch (stellarConfig.positionProperty) {
      case 'position':
        return {
          setTop: function($element, top){
            $element.css('top', top);
          },
          setLeft: function($element, left){
            $element.css('left', left);
          }
        };
      case 'transform':
        throw Error('unimplemented');
      default:
        return stellarConfig.positionProperty;
      }
    }());
    positionAdapter = positionProperty.setPosition || function($element, left, startingLeft, top, startingTop){
      if (stellarConfig.horizontalScrolling) {
        positionProperty.setLeft($element, left + "px", startingLeft + "px");
      }
      if (stellarConfig.verticalScrolling) {
        positionProperty.setTop($element, top + "px", startingTop + "px");
      }
    };
    bgPosAdapter = isDefined(
    element('<div style="background:#fff;"/>').css('background-position-x'))
      ? {
        get: function($element){
          var error;
          try {
            return [$css.toInt($element, 'background-position-x'), $css.toInt($element, 'background-position-y')];
          } catch (e$) {
            error = e$;
            return [0, 0];
          }
        },
        set: function($element, x, y){
          $element.css('background-position', x + "px " + y + "px");
        }
      }
      : {
        get: function($element){
          var bgPos;
          bgPos = $css.adapter($element, 'background-position').split(' ');
          return [parseInt(bgPos[0]), parseInt(bgPos[1])];
        },
        set: function($element, x, y){
          $element.css('background-position', x + " " + y);
        }
      };
    canCastToWindow = function($element){
      return $window === $element[0] || 9 === $element.prop('nodeType');
    };
    scrollAccessors = (function(){
      switch (stellarConfig.scrollProperty) {
      case 'scroll':
        return {
          getLeft: function(){
            return this._$element.prop('scrollLeft') || $window.pageXOffset;
          },
          getTop: function(){
            return this._$element.prop('scrollTop') || $window.pageYOffset;
          },
          setLeft: function(it){
            if (canCastToWindow(this._$element)) {
              $window.scrollTo(it, $window.pageYOffset);
            } else {
              this._$element.prop('scrollLeft', it);
            }
          },
          setTop: function(it){
            if (canCastToWindow(this._$element)) {
              $window.scrollTo($window.pageXOffset, it);
            } else {
              this._$element.prop('scrollTop', it);
            }
          }
        };
      case 'position':
        return {
          getLeft: function(){
            return -1 * $css.toInt(this._$element, 'left');
          },
          getTop: function(){
            return -1 * $css.toInt(this._$element, 'top');
          }
        };
      case 'margin':
        return {
          getLeft: function(){
            return -1 * $css.toInt(this._$element, 'margin-left');
          },
          getTop: function(){
            return -1 * $css.toInt(this._$element, 'margin-top');
          }
        };
      case 'transform':
        throw Error('unimplemented');
      default:
        return stellarConfig.scrollProperty;
      }
    }());
    extend(Target.prototype, {
      getOffset: function(){
        var offset, ref$;
        offset = $position.offset(this._$element);
        offset.offsetTop = (ref$ = offset.top, delete offset.top, ref$);
        offset.offsetLeft = (ref$ = offset.left, delete offset.left, ref$);
        return offset;
      }
    }, scrollAccessors);
    update = function(timestamp){
      var rescheduled, name, ref$, target;
      rescheduled = false;
      for (name in ref$ = Target) {
        target = ref$[name];
        if ((typeof target.handleUpdate === 'function' && target.handleUpdate(timestamp)) && !rescheduled) {
          rescheduled = true;
          handleScrollResize();
        }
      }
    };
    handleScrollResize = function(){
      $requestAnimationFrame(update);
    };
    x$ = new Target('window', $window);
    x$._$element.on('scroll resize', handleScrollResize);
    x$.getOffset = function(){
      var docEl;
      docEl = $window.document.documentElement;
      return {
        height: docEl.clientHeight,
        width: docEl.clientWidth,
        offsetTop: 0,
        offsetLeft: 0
      };
    };
    if (/WebKit/.test($window.navigator.userAgent)) {
      x$._$element.on('load', bind(x$, x$.handleWebkitBug));
    }
    return {
      get: function($element){
        var positions, offsets, bgPositions;
        positions = $position.position($element);
        offsets = $position.offset($element);
        bgPositions = bgPosAdapter.get($element);
        return {
          height: positions.height,
          width: positions.width,
          positionTop: positions.top,
          positionLeft: positions.left,
          offsetTop: (offsets != null ? offsets.top : void 8) || 0,
          offsetLeft: (offsets != null ? offsets.left : void 8) || 0,
          bgTop: bgPositions[1],
          bgLeft: bgPositions[0]
        };
      },
      set: function($element, styles){
        if (isDefined(styles.bgTop) && isDefined(styles.bgLeft)) {
          bgPosAdapter.set($element, styles.bgLeft, styles.bgTop);
        }
        if (isDefined(styles.positionTop) && isDefined(styles.positionLeft)) {
          positionAdapter($element, styles.positionLeft, styles.startingLeft, styles.positionTop, styles.startingTop);
        }
      },
      requestFrame: function(callback, targetName){
        var target;
        targetName || (targetName = 'window');
        target = Target[targetName] || new Target(targetName);
        return target.addCallbak(callback);
      }
    };
  });
  stellarBackgroundRatio = ['$window', '$document', '$css', 'stellarAccessors'].concat(function($window, $document, $css, stellarAccessors){
    var computeRatio;
    computeRatio = function($element, $attrs){
      var stellarBackgroundRatio, fixedRatioOffset;
      stellarBackgroundRatio = $attrs.stellarBackgroundRatio || 1;
      fixedRatioOffset = 'fixed' === $css.adapter($element, 'background-attachment') ? 0 : 1;
      return fixedRatioOffset - stellarBackgroundRatio;
    };
    return {
      restrict: 'A',
      link: function($scope, $element, $attrs){
        var finalRatio, verticalOffset, horizontalOffset, selfProperties, parentProperties;
        finalRatio = computeRatio($element, $attrs);
        verticalOffset = $attrs.stellarVerticalOffset || 0;
        horizontalOffset = $attrs.stellarHorizontalOffset || 0;
        selfProperties = stellarAccessors.get($element);
        parentProperties = {
          offsetTop: 0,
          offsetLeft: 0
        };
        $scope.$on('$destroy', stellarAccessors.requestFrame(function(targetProps){
          var bgTop, bgLeft;
          bgTop = finalRatio * (targetProps.scrollTop + verticalOffset - targetProps.offsetTop - selfProperties.offsetTop + parentProperties.offsetTop - selfProperties.bgTop);
          bgLeft = finalRatio * (targetProps.scrollLeft + horizontalOffset - targetProps.offsetLeft - selfProperties.offsetLeft + parentProperties.offsetLeft - selfProperties.bgLeft);
          stellarAccessors.set($element, {
            bgTop: bgTop,
            bgLeft: bgLeft
          });
        }));
      }
    };
  });
  stellarRatio = ['$window', '$document', '$css', 'stellarAccessors', 'stellarConfig'].concat(function($window, $document, $css, stellarAccessors, stellarConfig){
    var computeIsFixed, computeRatio;
    computeIsFixed = function($element){
      return 'fixed' === $css.adapter($element, 'position');
    };
    computeRatio = function($element, $attrs){
      var stellarRatio, fixedRatioOffset;
      stellarRatio = $attrs.stellarRatio || 1;
      fixedRatioOffset = computeIsFixed($element) ? 1 : 0;
      return stellarRatio + fixedRatioOffset - 1;
    };
    return {
      restrict: 'A',
      link: function($scope, $element, $attrs){
        var isFixed, finalRatio, verticalOffset, horizontalOffset, selfProperties, parentProperties;
        isFixed = computeIsFixed($element);
        finalRatio = -1 * computeRatio($element, $attrs);
        verticalOffset = $attrs.stellarVerticalOffset || 0;
        horizontalOffset = $attrs.stellarHorizontalOffset || 0;
        selfProperties = stellarAccessors.get($element);
        parentProperties = {
          offsetTop: 0,
          offsetLeft: 0
        };
        $scope.$on('$destroy', stellarAccessors.requestFrame(function(targetProps){
          var newTop, newOffsetTop, newLeft, newOffsetLeft, targetScrollLeft, targetScrollTop, isVisibleHorizontal, isVisibleVertical, isHidden;
          newTop = selfProperties.positionTop;
          newOffsetTop = selfProperties.offsetTop;
          if (stellarConfig.verticalScrolling) {
            newTop += finalRatio * (targetProps.scrollTop + verticalOffset + targetProps.offsetTop + selfProperties.positionTop - selfProperties.offsetTop + parentProperties.offsetTop);
            newOffsetTop += newTop - selfProperties.positionTop;
          }
          newLeft = selfProperties.positionLeft;
          newOffsetLeft = selfProperties.offsetLeft;
          if (stellarConfig.horizontalScrolling) {
            newLeft += finalRatio * (targetProps.scrollLeft + horizontalOffset + targetProps.offsetLeft + selfProperties.positionLeft - selfProperties.offsetLeft + parentProperties.offsetLeft);
            newOffsetLeft += newLeft - selfProperties.positionLeft;
          }
          if (stellarConfig.hideDistantElements) {
            targetScrollLeft = isFixed
              ? 0
              : targetProps.scrollLeft;
            targetScrollTop = isFixed
              ? 0
              : targetProps.scrollTop;
            isVisibleHorizontal = !stellarConfig.horizontalScrolling || (newOffsetLeft + selfProperties.width > targetScrollLeft && newOffsetLeft < targetProps.width + targetProps.offsetLeft + targetScrollLeft);
            isVisibleVertical = !stellarConfig.verticalScrolling || (newOffsetTop + selfProperties.height > targetScrollTop && newOffsetTop < targetProps.height + targetProps.offsetTop + targetScrollTop);
          }
          isHidden = stellarConfig.isElementHidden($element);
          if (isVisibleHorizontal && isVisibleVertical) {
            if (isHidden) {
              stellarConfig.showElement($element);
            }
            stellarAccessors.set($element, {
              positionTop: newTop,
              positionLeft: newLeft,
              startingTop: selfProperties.positionTop,
              startingLeft: selfProperties.positionLeft
            });
          } else if (!isHidden) {
            stellarConfig.hideElement($element);
          }
        }));
      }
    };
  });
  angular.module('angular.stellar', ['ui.bootstrap.position']).constant('stellarConfig', stellarConfig).factory('$requestAnimationFrame', $requestAnimationFrame).factory('$css', $css).factory('stellarAccessors', stellarAccessors).directive('stellarRatio', stellarRatio).directive('stellarBackgroundRatio', stellarBackgroundRatio);
}).call(this);
