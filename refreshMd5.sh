#/bin/bash

# sh_upscript_md5="$(md5sum script/sh_upscript.sh | awk '{print $1 }')"
# Sh10_clash_md5="$(md5sum script/Sh10_clash.sh  | awk '{print $1 }')"

# echo "sh_upscript=$sh_upscript_md5"
# echo "Sh10_clash=$Sh10_clash_md5"

# sed -i '' "s/Sh10_clash=.*/Sh10_clash=$Sh10_clash_md5/g" scriptsh.txt
# sed -i '' "s/sh_upscript=.*/sh_upscript=$sh_upscript_md5/g" scriptsh.txt

# 批量替换
for f in script/*.sh; do
    md5_str="$(md5sum $f | awk '{print $1 }')"
    fkey="$(basename $f)"  # https://www.cyberciti.biz/faq/bash-get-basename-of-filename-or-directory-name/ 
    echo "File -> , fkey -> ${fkey%.*} , md5 -> $md5_str"
    sed -i '' "s/${fkey%.*}=.*/${fkey%.*}=$md5_str/g" scriptsh.txt
done
