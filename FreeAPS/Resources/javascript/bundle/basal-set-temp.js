var freeaps_basalSetTemp;(()=>{var t={1701:(t,r,e)=>{"use strict";function a(t,r){t.reason=(t.reason?t.reason+". ":"")+r,console.error(r)}function o(t,r){r||(r=0);var e=Math.pow(10,r);return Math.round(t*e)/e}var n={getMaxSafeBasal:function(t){var r=isNaN(t.max_daily_safety_multiplier)||null===t.max_daily_safety_multiplier?3:t.max_daily_safety_multiplier,e=isNaN(t.current_basal_safety_multiplier)||null===t.current_basal_safety_multiplier?4:t.current_basal_safety_multiplier;return Math.min(t.max_basal,r*t.max_daily_basal,e*t.current_basal)},setTempBasal:function(t,r,i,s,l){var u=n.getMaxSafeBasal(i),c=e(6880);t<0?t=0:t>u&&(console.error("TBR "+c(t,2)+"U/hr limited by maxSafeBasal "+c(u,2)+"U/hr"),a(s,"TBR "+c(t,2)+"U/hr limited by maxSafeBasal "+c(u,2)+"U/hr"),t=u);var f=c(t,i),p=0;s.bolusIOB&&(p=s.bolusIOB);var v=0;s.basalIOB&&(v=s.basalIOB);var b=0;s.iobActivity&&(b=s.iobActivity);const _=i.current_basal;var d="",y=20;if(i.keto_protect_basal&&(y=Math.min(Math.max(i.keto_protect_basal,5),50)),console.error("Keto Protect:"+i.keto_protect+", KetoVarProt:"+i.variable_keto_protect_strategy+", bolusIOB="+o(p,3)+", basalIOB="+o(v,3)+", KetoProt Basal:"+i.keto_protect_basal+"%"),i.keto_protect&&i.variable_keto_protect_strategy&&p+v<0-_&&b<0){const t=_*y/100;f<t&&(f=t,d="KetoVarProt:, "+t+"U/hr, ")}else if(i.variable_keto_protect_strategy&&(p+v<0||b<0))d="KetoVarProt:, not active, IOB "+o(p+v,2)+" ?< "+(0-_)+", iobActivity: "+o(b,3)+" ?< 0, ";else if(i.keto_protect&&!i.variable_keto_protect_strategy){const t=_*y/100;f<t&&(f=t,d="KetoProt:, "+t+"U/hr, ")}return console.error(d),void 0!==l&&void 0!==l.duration&&void 0!==l.rate&&l.duration>r-10&&l.duration<=120&&f<=1.2*l.rate&&f>=.8*l.rate&&r>0?(s.reason=d+s.reason,s.reason+=", "+l.duration+"m left and "+l.rate+" ~ req "+f+"U/hr: no change necessary",s):f===i.current_basal?!0===i.skip_neutral_temps?void 0!==l&&void 0!==l.duration&&l.duration>0?(a(s,"Suggested rate is same as profile rate, a temp basal is active, canceling current temp"),s.duration=0,s.rate=0,s):(a(s,"Suggested rate is same as profile rate, no temp basal is active, doing nothing"),s):(a(s,"Setting neutral temp basal of "+i.current_basal+"U/hr"),s.duration=r,s.rate=f,s):(s.reason=d+s.reason,s.duration=r,s.rate=f,s)}};t.exports=n},6880:(t,r,e)=>{var a=e(6654);t.exports=function(t,r){var e=20;void 0!==r&&"string"==typeof r.model&&(a(r.model,"54")||a(r.model,"23"))&&(e=40);return t<1?Math.round(t*e)/e:t<10?Math.round(20*t)/20:Math.round(10*t)/10}},2705:(t,r,e)=>{var a=e(5639).Symbol;t.exports=a},9932:t=>{t.exports=function(t,r){for(var e=-1,a=null==t?0:t.length,o=Array(a);++e<a;)o[e]=r(t[e],e,t);return o}},9750:t=>{t.exports=function(t,r,e){return t==t&&(void 0!==e&&(t=t<=e?t:e),void 0!==r&&(t=t>=r?t:r)),t}},4239:(t,r,e)=>{var a=e(2705),o=e(9607),n=e(2333),i=a?a.toStringTag:void 0;t.exports=function(t){return null==t?void 0===t?"[object Undefined]":"[object Null]":i&&i in Object(t)?o(t):n(t)}},531:(t,r,e)=>{var a=e(2705),o=e(9932),n=e(1469),i=e(3448),s=a?a.prototype:void 0,l=s?s.toString:void 0;t.exports=function t(r){if("string"==typeof r)return r;if(n(r))return o(r,t)+"";if(i(r))return l?l.call(r):"";var e=r+"";return"0"==e&&1/r==-Infinity?"-0":e}},7561:(t,r,e)=>{var a=e(7990),o=/^\s+/;t.exports=function(t){return t?t.slice(0,a(t)+1).replace(o,""):t}},1957:(t,r,e)=>{var a="object"==typeof e.g&&e.g&&e.g.Object===Object&&e.g;t.exports=a},9607:(t,r,e)=>{var a=e(2705),o=Object.prototype,n=o.hasOwnProperty,i=o.toString,s=a?a.toStringTag:void 0;t.exports=function(t){var r=n.call(t,s),e=t[s];try{t[s]=void 0;var a=!0}catch(t){}var o=i.call(t);return a&&(r?t[s]=e:delete t[s]),o}},2333:t=>{var r=Object.prototype.toString;t.exports=function(t){return r.call(t)}},5639:(t,r,e)=>{var a=e(1957),o="object"==typeof self&&self&&self.Object===Object&&self,n=a||o||Function("return this")();t.exports=n},7990:t=>{var r=/\s/;t.exports=function(t){for(var e=t.length;e--&&r.test(t.charAt(e)););return e}},6654:(t,r,e)=>{var a=e(9750),o=e(531),n=e(554),i=e(9833);t.exports=function(t,r,e){t=i(t),r=o(r);var s=t.length,l=e=void 0===e?s:a(n(e),0,s);return(e-=r.length)>=0&&t.slice(e,l)==r}},1469:t=>{var r=Array.isArray;t.exports=r},3218:t=>{t.exports=function(t){var r=typeof t;return null!=t&&("object"==r||"function"==r)}},7005:t=>{t.exports=function(t){return null!=t&&"object"==typeof t}},3448:(t,r,e)=>{var a=e(4239),o=e(7005);t.exports=function(t){return"symbol"==typeof t||o(t)&&"[object Symbol]"==a(t)}},8601:(t,r,e)=>{var a=e(4841),o=1/0;t.exports=function(t){return t?(t=a(t))===o||t===-1/0?17976931348623157e292*(t<0?-1:1):t==t?t:0:0===t?t:0}},554:(t,r,e)=>{var a=e(8601);t.exports=function(t){var r=a(t),e=r%1;return r==r?e?r-e:r:0}},4841:(t,r,e)=>{var a=e(7561),o=e(3218),n=e(3448),i=/^[-+]0x[0-9a-f]+$/i,s=/^0b[01]+$/i,l=/^0o[0-7]+$/i,u=parseInt;t.exports=function(t){if("number"==typeof t)return t;if(n(t))return NaN;if(o(t)){var r="function"==typeof t.valueOf?t.valueOf():t;t=o(r)?r+"":r}if("string"!=typeof t)return 0===t?t:+t;t=a(t);var e=s.test(t);return e||l.test(t)?u(t.slice(2),e?2:8):i.test(t)?NaN:+t}},9833:(t,r,e)=>{var a=e(531);t.exports=function(t){return null==t?"":a(t)}}},r={};function e(a){var o=r[a];if(void 0!==o)return o.exports;var n=r[a]={exports:{}};return t[a](n,n.exports,e),n.exports}e.g=function(){if("object"==typeof globalThis)return globalThis;try{return this||new Function("return this")()}catch(t){if("object"==typeof window)return window}}();var a=e(1701);freeaps_basalSetTemp=a})();