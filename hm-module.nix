self: {
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) types;
  inherit (lib.modules) mkIf;
  inherit (lib.lists) optional;
  inherit (lib.options) mkOption mkEnableOption literalExpression;

  tomlFormat = pkgs.formats.toml { };
  stm = self.packages.${pkgs.stdenv.hostPlatform.system};
  defaultPackage = stm.default;
  script = stm.script;
  cfg = config.programs.stm;
in {
  meta.maintainers = with lib.maintainers; [Aylur];

  options.programs.stm = {
    enable = mkEnableOption "stm";

    package = mkOption {
      type = with types; nullOr package;
      default = defaultPackage;
      defaultText = literalExpression "inputs.stm.packages.${pkgs.stdenv.hostPlatform.system}.default";
      description = ''
        The stm package to use.

        By default, this option will use the `packages.default` as exposed by this flake.
      '';
    };

    integrate = mkOption {
      type = types.bool;
      default = false;
      defaultText = "true";
      description = ''
        Integrate into nushell
      '';
    };

    config = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          date_format = "%b.%e. %A";
          print_details = false;
          skip_confirmation = true;
          color = {
            date = "magenta";
            header = "red";
            row_index = "red";
            separator = "blue";
            string = "white";
          };
          table = {
            header_on_separator = true;
            mode = "thin";
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/stm/config.toml`.
      '';
    };
  };

  config = mkIf cfg.enable {
    xdg.configFile."stm/config.toml" = mkIf (cfg.config != { }) {
      source = tomlFormat.generate "stm-config" cfg.config;
    };
    programs.nushell = mkIf cfg.integrate {
      extraEnv = ''
        $env.PATH = ($env.PATH | split row (char esep) | prepend ${pkgs.gum}/bin)
      '';
      extraConfig = ''
        use ${script} stm
      '';
    };
    home.packages = optional (cfg.package != null && !cfg.integrate) cfg.package;
  };
}
