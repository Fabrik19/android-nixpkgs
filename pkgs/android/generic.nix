{ stdenv, fetchandroid, writeText, unzip }:

args: package:

let
  inherit (builtins) attrNames concatStringsSep filter hasAttr head listToAttrs replaceStrings;
  inherit (stdenv.lib) hasPrefix findFirst flatten groupBy mapAttrs nameValuePair optionalString;

  platforms = flatten (map (name:
    if (hasAttr name stdenv.lib.platforms) then stdenv.lib.platforms.${name} else name
  ) (attrNames package.sources));

  packageXml = writeText "${package.pname}-${package.version}-package-xml" package.xml;

in stdenv.mkDerivation (rec {

  inherit (package) pname version;

  nativeBuildInputs = [ unzip ] ++ (args.nativeBuildInputs or []);

  src = fetchandroid {
    inherit (package) sources;
  };

  setSourceRoot = ''
    sourceRoot="$out/${package.path}";
  '';

  unpackCmd = ''
    if ! [[ "$curSrc" =~ \.zip$ ]]; then return 1; fi

    unzip-strip() (
        local zip=$1
        local dest=''${2:-.}
        local temp=$(mktemp -d) && unzip -qq -d "$temp" "$zip" && mkdir -p "$dest" &&
        shopt -s dotglob && local f=("$temp"/*) &&
        if (( ''${#f[@]} == 1 )) && [[ -d "''${f[0]}" ]] ; then
            mv "$temp"/*/* "$dest"
        else
            mv "$temp"/* "$dest"
        fi && rmdir "$temp"/* "$temp"
    )

    export packageBase="$out/${package.path}"
    unzip-strip "$curSrc" "$packageBase"
  '';

  installPhase = args.installPhase or ''
    runHook preInstall
    runHook postInstall
  '';

  passthru = {
    license = package.license;
  } // (args.passthru or {});

  preferLocalBuild = true;

  meta = with stdenv.lib; {
    description = package.displayName;
    homepage = https://developer.android.com/studio/;
    license = licenses.asl20;
    maintainers = with maintainers; [ tadfisher ];
    inherit platforms;
  } // (args.meta or {});
} // removeAttrs args [ "nativeBuildInputs" "passthru" "meta" "unzipCmd" ])
