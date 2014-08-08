angular.module('giffy', ['ngSanitize'])
  .filter('giffy', ['$sanitize', function($sanitize) {
    var GIFFY_URL_REGEXP =
      /(https?:\/\/.*\.(?:png|jpg|jpeg|gif))/i;
    var LINKY_URL_REGEXP =
          /((ftp|https?):\/\/|(mailto:)?[A-Za-z0-9._%+-]+@)\S*[^\s.;,(){}<>]/,
        MAILTO_REGEXP = /^mailto:/;

  // this is decorated linky filter from ngSanitize
  return function(text, target) {
    if (!text) return text;
    var match;
    var raw = text;
    var html = [];
    var url;
    var i;
    while ((match = raw.match(LINKY_URL_REGEXP))) {
      // We can not end in these as they are sometimes found at the end of the sentence
      url = match[0];
      // if we did not match ftp/http/mailto then assume mailto
      if (match[2] == match[3]) url = 'mailto:' + url;
      i = match.index;
      addText(raw.substr(0, i));
      addLink(url, match[0].replace(MAILTO_REGEXP, ''));
      raw = raw.substring(i + match[0].length);
    }
    addText(raw);

    var images = text.match(GIFFY_URL_REGEXP);
    if(images != null) {
      img = '<img src="' + images[0] + '" class="msg-image">';
      addLink(images[0], img);
    }

    return $sanitize(html.join(''));

    function addText(text) {
      if (!text) {
        return;
      }
      html.push(text);
    }

    function addLink(url, text) {
      html.push('<a ');
      if (angular.isDefined(target)) {
        html.push('target="');
        html.push(target);
        html.push('" ');
      }
      html.push('href="');
      html.push(url);
      html.push('">');
      addText(text);
      html.push('</a>');
    }
  };
  }]);
