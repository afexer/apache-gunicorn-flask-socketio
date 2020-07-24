"""##############################################################
##
## Updates the cdns in flask-bootstrap4 so the use more recent versions
##
###############################################################"""
from flask_bootstrap import Bootstrap, StaticCDN, ConditionalCDN, WebCDN
import re

bootstrap = Bootstrap()


def bs_init_app(app):

    local = StaticCDN('bootstrap.static', rev=True)
    static = StaticCDN()

    def lwrap(cdn, primary=static):
        return ConditionalCDN('BOOTSTRAP_SERVE_LOCAL', primary, cdn)

    __version__ = '4.0.0'
    bootstrap_version_re = re.compile(r'(\d+\.\d+\.\d+(\-[a-z]+)?)')
    popper_version = '1.16.0'
    jquery_version = '3.4.1'
    fontawesome_version = '5.14.0'

    def get_bootstrap_version(version):
        return bootstrap_version_re.match(version).group(1)

    bootstrap_version = get_bootstrap_version(__version__)

    popper = lwrap(
        WebCDN('//cdnjs.cloudflare.com/ajax/libs/popper.js/%s/' %
               popper_version), local)

    bs = lwrap(
        WebCDN('//cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/%s/' %
               bootstrap_version), local)

    fontawesome = lwrap(
        WebCDN('//cdnjs.cloudflare.com/ajax/libs/font-awesome/%s/' %
               fontawesome_version), local)

    jquery = lwrap(
        WebCDN('//cdnjs.cloudflare.com/ajax/libs/jquery/%s/' %
               jquery_version), local)

    app.extensions['bootstrap'] = {
        'cdns': {
            'local': local,
            'static': static,
            'popper': popper,
            'bootstrap': bs,
            'fontawesome': fontawesome,
            'jquery': jquery,
        },
    }

    # setup support for flask-nav
    renderers = app.extensions.setdefault('nav_renderers', {})
    renderer_name = (__name__ + '.nav', 'BootstrapRenderer')
    renderers['bootstrap'] = renderer_name

    # make bootstrap the default renderer
    renderers[None] = renderer_name

