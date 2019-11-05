module.exports = function(config, injects) {
  var className = 'likely';
  if (config.look !== 'normal') {
    className += 'likely-' + config.look;
  }
  injects.head.raw('likely', `<link rel="stylesheet" href="${config.cdn.css}">`);
  injects.postBodyEnd.raw('likely', `<div class="post-widgets">
    <div class="${className}">
      {%- for x in config.likely.networks %}
        <div class="{{ loop.key }}">{{ x }}</div>
      {%- endfor %}
    </div>
  </div>
  <script src="${config.cdn.js}"></script>`);
};
