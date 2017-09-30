# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile assets from components folder
Rails.application.config.assets.precompile += %w( angular/angular.min.js angular-animate/angular-animate.min.js angular-bootstrap/ui-bootstrap-tpls.js )
Rails.application.config.assets.precompile += %w( angular-route/angular-route.min.js angular-sanitize/angular-sanitize.min.js )
Rails.application.config.assets.precompile += %w( animate.css/animate.min.css animatedmodal/animatedModal.min.js )
Rails.application.config.assets.precompile += %w( chart.js/dist/Chart.min.js )
Rails.application.config.assets.precompile += %w( jquery-file-upload/js/vendor/jquery.ui.widget.js jquery-file-upload/js/jquery.iframe-transport.js )
Rails.application.config.assets.precompile += %w( jquery-file-upload/js/jquery.fileupload.js jquery-file-upload/js/jquery.fileupload-process.js jquery-file-upload/js/jquery.fileupload-validate.js )
Rails.application.config.assets.precompile += %w( jquery-file-upload/img/loading.gif jquery-file-upload/img/progressbar.gif jquery-file-upload/css/jquery.fileupload.css )
Rails.application.config.assets.precompile += %w( jquery-file-upload/css/jquery.fileupload-noscript.css jquery-file-upload/css/jquery.fileupload-ui.css jquery-file-upload/css/jquery.fileupload-ui-noscript.css )
Rails.application.config.assets.precompile += %w( lodash/dist/lodash.min.js lodash/dist/lodash.core.min.js material-spinner/dist/js/material.spinner.min.js )
Rails.application.config.assets.precompile += %w( mdl/material.min.css mdl/material.min.js )
Rails.application.config.assets.precompile += %w( moment/min/moment.min.js )
Rails.application.config.assets.precompile += %w( xterm.js/dist/xterm.css xterm.js/dist/xterm.js xterm.js/dist/addons/fit/fit.js )
Rails.application.config.assets.precompile += %w( country-4x3/* )
Rails.application.config.assets.precompile += %w( bootstrap-datetimepicker-3/build/js/bootstrap-datetimepicker.min.js bootstrap-datetimepicker-3/build/css/bootstrap-datetimepicker.min.js )
Rails.application.config.assets.precompile += %w( intl-tel-input/build/* )
Rails.application.config.assets.precompile += %w( angular-ui-select/dist/select.css angular-ui-select/dist/select.min.js )
Rails.application.config.assets.precompile += %w( select2/select2.css select2/select2.min.js )
Rails.application.config.assets.precompile += %w( outdated-browser/outdatedbrowser/outdatedbrowser.min.js outdated-browser/outdatedbrowser/outdatedbrowser.min.css )
Rails.application.config.assets.precompile += %w( ng-file-upload/ng-file-upload.min.js )
Rails.application.config.assets.precompile += %w( bootstrap-xlgrid/bootstrap-xlgrid.min.css )
Rails.application.config.assets.precompile += %w( mdc-animation/dist/mdc.animation.min.css mdc-animation/dist/mdc.animation.min.js mdc-base/dist/mdc.base.min.js mdc-ripple/dist/mdc.ripple.min.js mdc-ripple/dist/mdc.ripple.min.css )