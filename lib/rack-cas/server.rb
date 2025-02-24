require 'rack-cas/url'
require 'rack-cas/saml_validation_response'
require 'rack-cas/service_validation_response'

module RackCAS
  class Server
    def initialize(url)
      @url = RackCAS::URL.parse(url)
    end

    def login_url(service_url, params = {})
      service_url = URL.parse(service_url).to_s
      base_params = {service: service_url}
      base_params[:renew] = true if RackCAS.config.renew?

      url = RackCAS.config.login_url? ? RackCAS::URL.parse(RackCAS.config.login_url) : @url.dup.append_path('login')
      url.add_params(base_params.merge(params))
    end

    def logout_url(params = {})
      @url.dup.tap do |url|
        url.append_path('logout')
        url.add_params(params) unless params.empty?
      end
    end

    def validate_service(service_url, ticket, params = {})
      params = RackCAS.config.extra_params_validate
      unless RackCAS.config.use_saml_validation?
        response = ServiceValidationResponse.new validate_service_url(service_url, ticket, params)
      else
        response = SAMLValidationResponse.new saml_validate_url(service_url, params), ticket
      end
      [response.user, response.extra_attributes]
    end

    protected

    def saml_validate_url(service_url, params = {})
      service_url = URL.parse(service_url).remove_param('ticket').to_s
      base_params = {TARGET: service_url}
      @url.dup.append_path(path_for_protocol('samlValidate')).add_params(base_params.merge(params))
    end

    def validate_service_url(service_url, ticket, params = {})
      service_url = URL.parse(service_url).remove_param('ticket').to_s
      base_params = {service: service_url, ticket: ticket}
      @url.dup.append_path(path_for_protocol('serviceValidate')).add_params(base_params.merge(params))
    end

    def path_for_protocol(path)
      if RackCAS.config.protocol && RackCAS.config.protocol == "p3"
        "p3/#{path}"
      else
        path
      end
    end
  end
end
