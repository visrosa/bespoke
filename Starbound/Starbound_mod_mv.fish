#/usr/bin/env fish

# Before running, delete all mods in the workshop directory and redowload
# to ensure only currently enabled mods are present.

# Script assumes a single .pak file per mod and will fail on mods containing
# multiple .paks, but those should be rare. 

set workshop_dir ~/Games/Installed/Steam/steamapps/workshop/content/211820
set asset_unpacker ~/Games/Installed/xStarbound/xsb-linux/asset_unpacker 
set mod_dir ~/Games/Installed/xStarbound/mods 

mkdir -p $mod_dir


for d in $workshop_dir/*
    set mod_id (basename $d)
    eval $asset_unpacker $d/*.pak $mod_id
    #set mod_name (jq -r '.friendlyName' "$mod_id"/_metadata) #Nice but bug-prone without checking for illegal chars
    set mod_safe_name (jq -r '.name' "$mod_id"/_metadata)
    if not test -n $mod_safe_name
	set mod_safe_name (jq -r '.friendlyName' "$mod_id"/_metadata)
    end
    cp $d/*.pak "$mod_dir/$mod_safe_name.pak"
    rm -rf $mod_id
end
