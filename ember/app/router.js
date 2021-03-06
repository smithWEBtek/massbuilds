import EmberRouter from '@ember/routing/router';
import config from './config/environment';

const Router = EmberRouter.extend({
  location: config.locationType,
  rootURL: config.rootURL,
  didTransition: function() {
    this._super(...arguments);

    return ga('send', 'pageview', {
      'page': this.get('url'),
      'title': this.get('url')
    });
  }
});

Router.map(function() {
  this.route('map', function() {
    this.route('developments', function() {
      this.route('development', { path: '/:development_id'}, function() {
        this.route('edit');
      });

      this.route('create');

      this.route('for', function() {
        this.route('user', { path: '/:user_id' });
      });
    });
    this.route('users', function() {
      this.route('verify');
    });
    this.route('moderations', function() {
      this.route('for', function() {
        this.route('user', { path: '/:user_id' });
      });
    });
  });
  this.route('glossary');
  this.route('about');
});

export default Router;
