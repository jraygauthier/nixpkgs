{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.guacamole;
  uid = 54201;
  gid = 54201;

  guacamole_version = "0.9.14";
  guacamole-client = pkgs.fetchurl {
    url = "mirror://sourceforge/guacamole/guacamole-${guacamole_version}.war";
    sha256 = "0kfr4g5nw0hl2wbxycvvy3h3avqk2k0q7xh0vlclk63a19rdjcc8";
  };

  guacamole-tomcat-webapp-dir = pkgs.stdenv.mkDerivation {
    name = "guacamole-tomcat-webapp-dir";
    buildCommand = ''
      mkdir -p "$out/webapps"
      install -T "${guacamole-client}" "$out/webapps/guacamole.war"
    '';
  };

  guacamole-tomcat-common-lib-dir = pkgs.stdenv.mkDerivation {
    name = "guacamole-tomcat-webapp-dir";
    buildCommand = ''
      mkdir -p "$out/lib"
      install -T "${pkgs.postgresql_jdbc}/share/java/postgresql.jar" "$out/lib/postgresql-jdbc.jar"
    '';
  };

  guacamole-server = pkgs.guacamole;
  guacamole_auth = builtins.fetchTarball {
    url = "http://apache.org/dyn/closer.cgi?action=download&filename=guacamole/${guacamole_version}/binary/guacamole-auth-jdbc-${guacamole_version}.tar.gz";
    sha256 = "1n6fnzc3jc5r1a4bdbl5nc5h6178kaix7rvqdr1jpfb5i3rd2sb4";
  };
  guacamole_path_suffix = removeSuffix ".war" (removePrefix "/nix/store/" guacamole-client);
  guac_path = "${config.services.tomcat.baseDir}/webapps/guac";
in

{
  options = {
    services.guacamole = {
      enable = mkOption {
        description = "Enable guacamole";
        default = false;
        type = types.bool;
      };
      user = mkOption {
        description = "User account under which guacd runs.";
        default = "guacamole";
        type = types.str;
      };
      group = mkOption {
        description = "Group account under which guacd runs.";
        default = "guacamole";
        type = types.str;
      };
      # TODO: allow this to be refered to by file and avoid the store
      guacamole_properties = mkOption {
        description = "guacamole.properties in the docs";
        default = ''
          # Basic Authentication provider class. Will use postgres if unspecified and
          # fail if not properly configured. You will need to remove any of the
          # below 'postgresql' options below for it to work.
          auth-provider: net.sourceforge.guacamole.net.basic.BasicFileAuthenticationProvider

          guacd-hostname: localhost
          guacd-port: 4822
          enable-websocket: true
          #postgresql-hostname: localhost
          #postgresql-port: 5432
          #postgresql-database: guacamole_db
          #postgresql-username: guacamole_user
          #postgresql-password: changeme
          #postgresql-default-max-connections: 1
          #postgresql-default-max-group-connections: 1
        '';
        type = types.str;
      };
      # TODO: allow this to be refered to by file and avoid the store
      user_mapping = mkOption {
        description = "user-mapping.xml in the docs";
        default = ''
<user-mapping>
    <authorize username="user"
        password="pw">
	    <connection name="example.com">
            <protocol>ssh</protocol>
            <param name="username">root</param>
            <param name="hostname">localhost</param>
            <param name="port">22</param>
        </connection>
        <connection name="another">
            <protocol>rdp</protocol>
            <param name="security">any</param>
            <param name="username">root</param>
            <param name="hostname">localhost</param>
            <param name="port">3389</param>
        </connection>
    </authorize>
</user-mapping>
        '';
        type = types.str;
      };
    };
  };

  config = mkIf cfg.enable {

    environment.etc."guacamole/user_mapping.xml".text = cfg.user_mapping;
    environment.etc."guacamole/guacamole.properties".text = cfg.guacamole_properties;

    systemd.services.guacd =
      let
        user-mapping = builtins.toFile "user_mapping.xml" cfg.user_mapping;
        guacamole-properties = builtins.toFile "guacamole.properties" cfg.guacamole_properties;

      in {
      description = "Guacamole Proxy Daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        PermissionsStartOnly = true;
        # Someone with better tomcat experience needs to clean this up.
        ExecStartPre = pkgs.writeScript "guacd-prestart.sh" ''
            #!/bin/sh
            set -x
            #ln -snfL ./${guacamole_path_suffix} ${guac_path}
            mkdir -p ${guac_path}
            ln -snfL ${user-mapping} ${guac_path}/user-mapping.xml
            ln -snfL ${guacamole-properties} ${guac_path}/guacamole.properties
            mkdir -p ${guac_path}/extensions
            ln -snfL ${guacamole_auth}/postgresql/guacamole-auth-jdbc-postgresql-${guacamole_version}.jar ${guac_path}/extensions/guacamole-auth-jdbc-postgresql-${guacamole_version}.jar
            chown ${config.services.tomcat.user}:${config.services.tomcat.group} ${guac_path} -R
        '';
        ExecStart = "${guacamole-server}/bin/guacd -f -L debug";
        Restart = "on-failure";
        User = cfg.user;
        Group = cfg.group;
      };
    };

    services.tomcat = {
      enable = true;
      webapps = [ guacamole-tomcat-webapp-dir ];
      commonLibs = [ guacamole-tomcat-common-lib-dir ];
    };
    systemd.services.tomcat.serviceConfig.Environment = ["GUACAMOLE_HOME=${guac_path}" ];

    users.users = optionalAttrs (cfg.user == "guacamole") (singleton {
      name = cfg.user;
      group = cfg.group;
      uid = uid;
    });

    users.groups = optionalAttrs (cfg.group == "guacamole") (singleton {
      name = cfg.group;
      gid = gid;
    });
  };
}
