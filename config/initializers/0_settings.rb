#Define simple settings/config methods in here.
module Auth
  class << self
    def ldap_config
      if File.file? '/opt/xn_apps/ldap.yml'
        yaml_contents = YAML.load_file '/opt/xn_apps/ldap.yml'
        yaml_contents.fetch Rails.env, {} rescue {}
      else
        {}
      end
    end

    def ldap_enabled?
      ldap_config['enabled']
    end
  end
end
