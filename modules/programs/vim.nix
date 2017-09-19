{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.vim;
  defaultPlugins = [ "sensible" ];
  booleanOptions = [ "number" "expandtab" "relativenumber" ];
  vimSettings = mkOptionType {
    name = "settings";
    description = "vim settings";
    check = value: isAttrs value && (all (a: elem a booleanOptions) (attrNames value));
    merge = loc: foldl' (res: def: mergeAttrs res def.value) {};
  };
in

{
  options = {
    programs.vim = {
      enable = mkEnableOption "Vim";

      settings = mkOption {
        type = types.nullOr vimSettings;
        default = null;
        description = "Common basic options";
      };

      tabSize = mkOption {
        type = types.nullOr types.int;
        default = null; 
        example = 4;
        description = "Set tab size and shift width to a specified number of spaces.";
      };

      plugins = mkOption {
        type = types.listOf types.str;
        default = defaultPlugins;
        example = [ "YankRing" ];
        description = ''
          List of vim plugins to install.
          For supported plugins see: https://github.com/NixOS/nixpkgs/blob/master/pkgs/misc/vim-plugins/vim-plugin-names
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          set nocompatible
          set nobackup
        '';
        description = "Custom .vimrc lines";
      };

      package = mkOption {
        type = types.package;
        description = "Resulting customized vim package";
        readOnly = true;
      };
    };
  };

  config = (
    let
      optionalBoolean = name: val: optionalString (val != null) (if val then "set ${name}" else "set no${name}");
      optionalInteger = name: val: optionalString (val != null) "set ${name}=${toString val}";
      booleanOptions' = if cfg.settings != null then (filter (opt: hasAttr opt cfg.settings) booleanOptions) else [];
      settings = concatStringsSep "\n" (map (opt: optionalBoolean opt cfg.settings.${opt}) booleanOptions');
      customRC = ''
        ${optionalInteger "tabstop" cfg.tabSize}
        ${optionalInteger "shiftwidth" cfg.tabSize}
        ${settings}

        ${cfg.extraConfig}
      '';

      vim = pkgs.vim_configurable.customize {
        name = "vim";
        vimrcConfig.customRC = customRC;
        vimrcConfig.vam.knownPlugins = pkgs.vimPlugins;
        vimrcConfig.vam.pluginDictionaries = [
          { names = defaultPlugins ++ cfg.plugins; }
        ];
      };

    in mkIf cfg.enable {
      programs.vim.package = vim;
      home.packages = [ cfg.package ];
    }
  );
}
