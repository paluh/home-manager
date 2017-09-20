{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.vim;
  defaultPlugins = [ "sensible" ];
  makeBooleanOption = name: {
    name = name;
    value = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''"set ${name}" or "set no${name}"'';
    };
  };
  booleanOptions =  [
    "backup"
    "compatible"
    "cp"
    "expandtab"
    "hlsearch"
    "incsearch"
    "list"
    "number"
    "relativenumber"
    "showcmd"
    "showmode"
    "splitbelow"
  ];
in

{
  options = {
    programs.vim = listToAttrs (map makeBooleanOption (booleanOptions)) // {
      enable = mkEnableOption "Vim";

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
      booleanOptionsLines = concatStringsSep "\n" (map (v: if cfg.${v} then "set ${v}" else "set no${v}") (filter (opt: cfg.${opt} != null) booleanOptions));
      customRC = ''
        ${booleanOptionsLines}
        ${optionalInteger "tabstop" cfg.tabSize}
        ${optionalInteger "shiftwidth" cfg.tabSize}

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
